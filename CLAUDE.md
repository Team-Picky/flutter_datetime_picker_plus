# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`flutter_datetime_picker_plus` is a published Flutter package (pub.dev) providing bottom-sheet date/time pickers with localization into ~45 languages. It is a maintained fork of the original `flutter_datetime_picker`, updated for Dart 3.0 / Flutter >=3.10.0. The package is consumed as a library — there is no app entrypoint except the demo in `example/`.

## Commands

This repo pins its Flutter SDK with [FVM](https://fvm.app) (version in `.fvmrc`). Prefix Flutter/Dart commands with `fvm` so they run against the pinned SDK:

```bash
fvm flutter pub get                 # install dependencies
fvm flutter analyze                 # static analysis / lint (uses default Flutter lints)
fvm flutter test                    # run all tests
fvm flutter test test/some_test.dart        # run a single test file
fvm flutter test --name "pattern"            # run tests matching a name

cd example && fvm flutter run       # run the demo app to visually verify pickers
```

There is no custom `analysis_options.yaml` — analysis uses Flutter defaults.

## Architecture

The package separates **presentation** (the route/widget that draws three scrolling wheels) from **data models** (what each wheel shows and how selections map to a `DateTime`). Adding a new picker style means writing a model, not touching the widget.

### Public API — `lib/flutter_datetime_picker_plus.dart`
The barrel file and only import consumers need. It re-exports `date_model.dart`, `datetime_picker_theme.dart`, and `i18n_model.dart`. The `DatePicker` class exposes static methods that each push a `_DatePickerRoute` (a `PopupRoute`) onto the navigator:
- `showDatePicker`, `showTimePicker`, `showTime12hPicker`, `showDateTimePicker` — convenience methods that instantiate the matching built-in model.
- `showPicker` — the extension point: pass any `BasePickerModel` to render a fully custom picker.

All return `Future<DateTime?>` and accept `onChanged`/`onConfirm`/`onCancel` callbacks, a `locale`, and an optional `theme`. The private `_DatePickerComponent` / `_DatePickerState` and `_BottomPickerLayout` (in the same file) render the three `CupertinoPicker` wheels and animate the sheet — they are model-agnostic and drive everything through the `BasePickerModel` interface.

### Data models — `lib/src/date_model.dart`
This is the core abstraction. `BasePickerModel` defines the three-column contract the widget consumes: `leftStringAtIndex`/`middleStringAtIndex`/`rightStringAtIndex` (return `null` to terminate a column's list), the current-index getters/setters, `finalTime()`, dividers, and `layoutProportions()`. `CommonPickerModel` provides a no-op base; the four built-in models extend it:
- `DatePickerModel` — year / month / day, honoring `minTime`/`maxTime` clamping per column.
- `TimePickerModel` — hour / minute / (optional) second.
- `Time12hPickerModel` — hour / minute / AM-PM.
- `DateTimePickerModel` — combined date + time.

To add a custom picker, subclass `CommonPickerModel` (see README "Customize" section), implement the column getters and `finalTime()`, and pass it to `DatePicker.showPicker`.

### Localization — `lib/src/i18n_model.dart`
`LocaleType` is the enum of supported languages. `_i18nModel` maps each locale to a `Map<String,Object>` of month names, weekday names, AM/PM strings, and column ordering hints. `i18nObjInLocale(localeType)` resolves a locale's table (falling back to English), and `i18nObjInLocaleLookup(...)` reads a single indexed entry. **Adding a language** means adding the enum case in this file, a matching entry in `_i18nModel`, and updating the README language list.

### Formatting — `lib/src/date_format.dart`
String-token date formatting (`formatDate(date, [tokens])`). Tokens are `const String` identifiers like `yyyy`, `mm`, `dd`, `MM` (full month name), `w` (weekday), etc. Models use these tokens together with the i18n tables to produce localized column labels.

### Theming — `lib/src/datetime_picker_theme.dart`
`DatePickerTheme` (mixes in `DiagnosticableTreeMixin`) holds colors, text styles, container height, and item height. Note the barrel imports it with the `picker_theme` prefix to avoid colliding with Flutter's own `DatePickerTheme`.

## Conventions

- Public symbols are exported only through the barrel file; internals live under `lib/src/` and are imported with package-absolute paths.
- The library directive is still `library flutter_datetime_picker;` (legacy name) — leave it unless deliberately renaming.
- Bumping the version: update `version:` in `pubspec.yaml`, add a `CHANGELOG.md` entry, then commit (recent history shows `chore: bump version to X` + lockfile update as separate commits).
