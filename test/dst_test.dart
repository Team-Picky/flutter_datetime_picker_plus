// These tests only exercise daylight saving transitions when run in a time
// zone that has them. They pass in any zone, so run them under a few:
//
//   TZ=America/New_York fvm flutter test test/dst_test.dart
//   TZ=America/Nuuk fvm flutter test test/dst_test.dart
//   TZ=Asia/Tokyo fvm flutter test test/dst_test.dart
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateTimePickerModel across DST transitions', () {
    // America/New_York springs forward on 2026-03-08.
    test('the day after Mar 7, 23:30 is Mar 8 (spring forward)', () {
      final model =
          DateTimePickerModel(currentTime: DateTime(2026, 3, 7, 23, 30));
      expect(model.leftStringAtIndex(1), 'Sun Mar 08');
      model.setLeftIndex(1);
      expect(model.finalTime(), DateTime(2026, 3, 8, 23, 30));
    });

    // America/New_York falls back on 2026-11-01, a 25-hour day.
    test('the day after Nov 1, 00:30 is Nov 2 (fall back)', () {
      final model =
          DateTimePickerModel(currentTime: DateTime(2026, 11, 1, 0, 30));
      expect(model.leftStringAtIndex(1), 'Mon Nov 02');
      model.setLeftIndex(1);
      expect(model.finalTime(), DateTime(2026, 11, 2, 0, 30));
    });

    test('minTime is honored on the 25-hour day', () {
      final minTime = DateTime(2026, 11, 1, 0, 40);
      final model = DateTimePickerModel(
        currentTime: DateTime(2026, 11, 1, 23, 50),
        minTime: minTime,
      );
      model.setMiddleIndex(0);
      expect(model.rightStringAtIndex(0), '40');
      model.setRightIndex(0);
      expect(model.finalTime(), minTime);
    });

    // America/Nuuk springs forward at 23:00 on 2026-03-28, so 23:30 that day
    // does not exist.
    test('Mar 28 appears once after Mar 27, 23:30', () {
      final model =
          DateTimePickerModel(currentTime: DateTime(2026, 3, 27, 23, 30));
      expect(
        [for (var i = 0; i < 3; i++) model.leftStringAtIndex(i)],
        ['Fri Mar 27', 'Sat Mar 28', 'Sun Mar 29'],
      );
    });

    test('day rows roll over month and year ends', () {
      final model =
          DateTimePickerModel(currentTime: DateTime(2026, 12, 31, 12));
      expect(model.leftStringAtIndex(1), 'Fri Jan 01, 2027');
      model.setLeftIndex(1);
      expect(model.finalTime(), DateTime(2027, 1, 1, 12));
    });
  });
}
