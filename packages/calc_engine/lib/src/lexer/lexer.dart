import 'package:calc_engine/src/calc_result.dart';
import 'package:calc_engine/src/evaluation_exception.dart';

/// The kinds of token in an expression.
enum TokenKind {
  /// A decimal literal such as `12`, `.5` or `5.`.
  number,

  /// A name made of letters, such as a variable.
  identifier,

  /// `+`
  plus,

  /// `-` or `−`
  minus,

  /// `*` or `×`
  times,

  /// `/` or `÷`
  divide,

  /// `%`
  percent,

  /// `(`
  openBracket,

  /// `)`
  closeBracket,
}

/// One token of an expression, with its source [text].
final class Token {
  /// Creates a token of [kind] read from [text].
  const Token(this.kind, this.text);

  /// The token's kind.
  final TokenKind kind;

  /// The characters it was read from.
  final String text;

  @override
  String toString() => 'Token($kind, $text)';
}

/// Splits [source] into tokens.
///
/// Accepts digits and `.`, letters, `+ - − * × / ÷ % ( )` and whitespace.
/// Throws an [EvaluationException] with [CalcError.syntax] for any other
/// character, or for a number with a second decimal point or no digits.
List<Token> tokenize(String source) {
  final tokens = <Token>[];
  var index = 0;
  while (index < source.length) {
    final char = source[index];
    if (char.trim().isEmpty) {
      index++;
      continue;
    }
    if (_isDigit(char) || char == '.') {
      final start = index;
      var points = 0;
      while (index < source.length &&
          (_isDigit(source[index]) || source[index] == '.')) {
        if (source[index] == '.') points++;
        index++;
      }
      final text = source.substring(start, index);
      if (points > 1 || text == '.') {
        throw const EvaluationException(CalcError.syntax);
      }
      tokens.add(Token(TokenKind.number, text));
      continue;
    }
    if (_isLetter(char)) {
      final start = index;
      while (index < source.length && _isLetter(source[index])) {
        index++;
      }
      tokens.add(Token(TokenKind.identifier, source.substring(start, index)));
      continue;
    }
    final kind = _symbols[char];
    if (kind == null) throw const EvaluationException(CalcError.syntax);
    tokens.add(Token(kind, char));
    index++;
  }
  return tokens;
}

const Map<String, TokenKind> _symbols = {
  '+': TokenKind.plus,
  '-': TokenKind.minus,
  '−': TokenKind.minus,
  '*': TokenKind.times,
  '×': TokenKind.times,
  '/': TokenKind.divide,
  '÷': TokenKind.divide,
  '%': TokenKind.percent,
  '(': TokenKind.openBracket,
  ')': TokenKind.closeBracket,
};

bool _isDigit(String char) {
  final unit = char.codeUnitAt(0);
  return unit >= 0x30 && unit <= 0x39;
}

bool _isLetter(String char) {
  final unit = char.codeUnitAt(0) | 0x20;
  return unit >= 0x61 && unit <= 0x7A;
}
