import 'dart:io';
import 'dart:typed_data';

/// Encodes straight RGBA pixels as an 8-bit RGB PNG, dropping the alpha
/// channel. `Image.toByteData(format: png)` always writes RGBA, and the App
/// Store rejects an app icon that has an alpha channel, so the iOS icons are
/// written with this instead.
Uint8List encodeRgbPng(int width, int height, Uint8List rgba) {
  assert(rgba.length == width * height * 4, 'expected RGBA pixels');
  final scanlines = BytesBuilder(copy: false);
  for (var y = 0; y < height; y++) {
    final row = Uint8List(1 + width * 3); // filter type 0, then RGB
    for (var x = 0; x < width; x++) {
      final from = (y * width + x) * 4;
      row.setRange(1 + x * 3, 4 + x * 3, rgba, from);
    }
    scanlines.add(row);
  }

  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 2) // colour type: RGB
    ..setUint8(10, 0) // compression
    ..setUint8(11, 0) // filter
    ..setUint8(12, 0); // interlace

  return (BytesBuilder(copy: false)
        ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        ..add(_chunk('IHDR', header.buffer.asUint8List()))
        ..add(
          _chunk('IDAT', ZLibEncoder(level: 9).convert(scanlines.takeBytes())),
        )
        ..add(_chunk('IEND', const [])))
      .takeBytes();
}

Uint8List _chunk(String type, List<int> data) {
  final typeBytes = type.codeUnits;
  final crcInput = [...typeBytes, ...data];
  final out = ByteData(12 + data.length)..setUint32(0, data.length);
  final bytes = out.buffer.asUint8List()
    ..setRange(4, 8, typeBytes)
    ..setRange(8, 8 + data.length, data);
  out.setUint32(8 + data.length, _crc32(crcInput));
  return bytes;
}

final List<int> _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  return crc ^ 0xFFFFFFFF;
}
