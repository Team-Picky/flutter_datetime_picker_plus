import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

void main() {
  group('DatePickerModel', () {
    final minTime = DateTime(2018, 1, 1);
    final maxTime = DateTime(2020, 12, 31);

    test('keeps currentTime that is within bounds', () {
      final model = DatePickerModel(
        currentTime: DateTime(2019, 6, 15),
        minTime: minTime,
        maxTime: maxTime,
      );

      final result = model.finalTime();
      expect(result.year, 2019);
      expect(result.month, 6);
      expect(result.day, 15);
    });

    test('clamps currentTime above maxTime down to maxTime', () {
      final model = DatePickerModel(
        currentTime: DateTime(2025, 1, 1),
        minTime: minTime,
        maxTime: maxTime,
      );

      final result = model.finalTime();
      expect(result.year, maxTime.year);
      expect(result.month, maxTime.month);
      expect(result.day, maxTime.day);
    });

    test('clamps currentTime below minTime up to minTime', () {
      final model = DatePickerModel(
        currentTime: DateTime(2000, 1, 1),
        minTime: minTime,
        maxTime: maxTime,
      );

      final result = model.finalTime();
      expect(result.year, minTime.year);
      expect(result.month, minTime.month);
      expect(result.day, minTime.day);
    });

    test('left (year) column spans minTime..maxTime inclusive', () {
      final model = DatePickerModel(
        currentTime: DateTime(2019, 6, 15),
        minTime: minTime,
        maxTime: maxTime,
      );

      // 2018, 2019, 2020 => 3 entries
      expect(model.leftStringAtIndex(0), isNotNull);
      expect(model.leftStringAtIndex(2), isNotNull);
      expect(model.leftStringAtIndex(3), isNull);
    });
  });

  group('i18nObjInLocale', () {
    test('English locale exposes 12 long month names', () {
      final months = i18nObjInLocale(LocaleType.en)['monthLong'] as List;
      expect(months.length, 12);
      expect(months.first, 'January');
      expect(months.last, 'December');
    });

    test('null locale falls back to English', () {
      expect(i18nObjInLocale(null), i18nObjInLocale(LocaleType.en));
    });
  });
}
