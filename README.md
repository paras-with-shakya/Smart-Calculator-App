# Smart Calculator

A calculator app built with Flutter: a basic and a scientific calculator, a programmer calculator, unit and currency conversion, financial tools and date arithmetic, with history and saved calculations. It works fully offline.

## Features

- **Basic:** expression editing with a movable cursor, a live preview, smart percent (`50+10%` = 55), memory (MC, MR, M+, M−, MS) and exact arithmetic (`0.1+0.2−0.3` = 0).
- **Scientific:** powers, roots, factorial, π and e, trigonometric, hyperbolic and logarithmic functions, degrees or radians, and a 2nd (inverse) toggle.
- **Programmer:** hexadecimal, decimal, octal and binary at once; 8, 16, 32 and 64-bit words, signed or unsigned; AND, OR, XOR, NOT and shifts.
- **Converter:** length, weight, temperature, area, volume and time, plus currency at rates you set yourself (the app never fetches rates).
- **Financial:** EMI, simple and compound interest, GST, discount, tip and percentage.
- **Date:** the difference between two dates, and adding or subtracting days, weeks, months or years.
- **History and saved calculations:** search, reuse, copy, rename and delete; history can be limited or turned off.
- **Settings:** light, dark or system theme, decimal places, haptics and key sounds, text size, larger controls, high contrast, the mode the app opens in.
- **Accessibility:** screen-reader labels for every key and result, 48 dp touch targets, reduced motion when the system asks for it, and layouts tested at 200% text.

## Privacy

Everything stays on the device. The release build has no internet permission and asks the user for no permissions, the app has no analytics, tracking or crash reporting, and the currency rates are typed in, not downloaded. A summary is in the app under Settings → About.

## Platforms

- **Android:** the primary platform, built and tested on a phone.
- **iOS:** set up, but not built or tested yet (it needs a Mac).
- **Web, Windows, Linux, macOS:** the folders are kept, but these are not supported targets.

## Building and testing

With Flutter 3.47.5 (Dart 3.13.4), from this directory:

```sh
flutter pub get
flutter run

flutter analyze
dart format --set-exit-if-changed lib test packages
flutter test                           # the app
(cd packages/calc_engine && dart test) # the calculation engine
flutter build apk --debug
```

Two generators are skipped in a normal test run and run on demand:

```sh
# Design-review screenshots of every screen, written to build/design_review/
flutter test --tags design-review --run-skipped --update-goldens

# The Android and iOS launcher icons, from assets/brand/smart_calculator_logo.png
flutter test --tags launcher-icons --run-skipped test/brand/generate_launcher_icons_test.dart
```

## How it is built

- **`packages/calc_engine`:** a pure-Dart calculation engine (no Flutter). It tokenizes and parses expressions itself (no string evaluation), keeps exact fractions wherever the answer is rational, and returns typed errors rather than `NaN` or `Infinity`.
- **`lib/features/`:** one folder per feature (calculator, converter, financial, date calculator, programmer, history, saved calculations, settings), each split into domain, data, application and presentation layers.
- **`lib/core/` and `lib/app/theme/`:** shared widgets and design tokens (colours, typography, spacing, radius, motion); screens are built only from these.
- **State and storage:** Riverpod 3 for state, `shared_preferences` for settings and `sqflite` for history and saved calculations.
- **Fonts:** Manrope and JetBrains Mono, bundled with the app.

The design decisions, the architecture and the development history are in [docs/](docs/): start with [docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md).
