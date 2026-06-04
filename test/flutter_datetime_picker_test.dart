import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
// date_format.dart is internal (not re-exported by the barrel), imported
// directly so the formatter and its tokens can be exercised.
import 'package:flutter_datetime_picker_plus/src/date_format.dart';

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

  group('TimePickerModel', () {
    final currentTime = DateTime(2020, 5, 10, 14, 30, 45);

    test('seeds indices from currentTime h/m/s', () {
      final model = TimePickerModel(currentTime: currentTime);
      expect(model.currentLeftIndex(), 14);
      expect(model.currentMiddleIndex(), 30);
      expect(model.currentRightIndex(), 45);
    });

    test('finalTime reflects the seeded time', () {
      final model = TimePickerModel(currentTime: currentTime);
      final result = model.finalTime();
      expect(result.year, 2020);
      expect(result.month, 5);
      expect(result.day, 10);
      expect(result.hour, 14);
      expect(result.minute, 30);
      expect(result.second, 45);
    });

    test('finalTime reflects updated indices', () {
      final model = TimePickerModel(currentTime: currentTime);
      model.setLeftIndex(8);
      model.setMiddleIndex(5);
      model.setRightIndex(30);

      final result = model.finalTime();
      expect(result.hour, 8);
      expect(result.minute, 5);
      expect(result.second, 30);
      // date is preserved
      expect(result.year, 2020);
      expect(result.month, 5);
      expect(result.day, 10);
    });

    test('columns are zero-padded and terminate at their bounds', () {
      final model = TimePickerModel(currentTime: currentTime);
      // hours 0..23
      expect(model.leftStringAtIndex(0), '00');
      expect(model.leftStringAtIndex(9), '09');
      expect(model.leftStringAtIndex(23), '23');
      expect(model.leftStringAtIndex(24), isNull);
      expect(model.leftStringAtIndex(-1), isNull);
      // minutes / seconds 0..59
      expect(model.middleStringAtIndex(59), '59');
      expect(model.middleStringAtIndex(60), isNull);
      expect(model.rightStringAtIndex(59), '59');
      expect(model.rightStringAtIndex(60), isNull);
    });

    test('seconds column shown by default', () {
      final model = TimePickerModel(currentTime: currentTime);
      expect(model.leftDivider(), ':');
      expect(model.rightDivider(), ':');
      expect(model.layoutProportions(), [1, 1, 1]);
    });

    test('seconds column hidden collapses right column', () {
      final model = TimePickerModel(
        currentTime: currentTime,
        showSecondsColumn: false,
      );
      expect(model.rightDivider(), '');
      expect(model.layoutProportions(), [1, 1, 0]);
    });

    test('preserves UTC flag through finalTime', () {
      final model =
          TimePickerModel(currentTime: DateTime.utc(2020, 5, 10, 14, 30, 45));
      expect(model.finalTime().isUtc, isTrue);
    });
  });

  group('Time12hPickerModel', () {
    test('12 AM (midnight) maps to hour 0', () {
      final model =
          Time12hPickerModel(currentTime: DateTime(2020, 5, 10, 0, 15));
      expect(model.currentLeftIndex(), 0);
      expect(model.currentRightIndex(), 0); // AM
      expect(model.finalTime().hour, 0);
    });

    test('12 PM (noon) maps to hour 12', () {
      final model =
          Time12hPickerModel(currentTime: DateTime(2020, 5, 10, 12, 15));
      expect(model.currentLeftIndex(), 0);
      expect(model.currentRightIndex(), 1); // PM
      expect(model.finalTime().hour, 12);
    });

    test('afternoon hour round-trips (2 PM => 14)', () {
      final model =
          Time12hPickerModel(currentTime: DateTime(2020, 5, 10, 14, 30));
      expect(model.currentLeftIndex(), 2);
      expect(model.currentRightIndex(), 1); // PM
      expect(model.finalTime().hour, 14);
      expect(model.finalTime().minute, 30);
    });

    test('late evening round-trips (11 PM => 23)', () {
      final model =
          Time12hPickerModel(currentTime: DateTime(2020, 5, 10, 23, 0));
      expect(model.currentLeftIndex(), 11);
      expect(model.currentRightIndex(), 1); // PM
      expect(model.finalTime().hour, 23);
    });

    test('finalTime zeroes seconds', () {
      final model =
          Time12hPickerModel(currentTime: DateTime(2020, 5, 10, 9, 30, 45));
      expect(model.finalTime().second, 0);
    });

    test('left column shows 12 first then 01..11', () {
      final model =
          Time12hPickerModel(currentTime: DateTime(2020, 5, 10, 9, 0));
      expect(model.leftStringAtIndex(0), '12');
      expect(model.leftStringAtIndex(1), '01');
      expect(model.leftStringAtIndex(11), '11');
      expect(model.leftStringAtIndex(12), isNull);
    });

    test('right column exposes localized AM/PM only', () {
      final model = Time12hPickerModel(
        currentTime: DateTime(2020, 5, 10, 9, 0),
        locale: LocaleType.en,
      );
      expect(model.rightStringAtIndex(0), 'AM');
      expect(model.rightStringAtIndex(1), 'PM');
      expect(model.rightStringAtIndex(2), isNull);
    });
  });

  group('DateTimePickerModel', () {
    test('without bounds, finalTime keeps date + h/m and drops seconds', () {
      final model = DateTimePickerModel(
        currentTime: DateTime(2020, 5, 10, 14, 30, 45),
      );
      final result = model.finalTime();
      expect(result.year, 2020);
      expect(result.month, 5);
      expect(result.day, 10);
      expect(result.hour, 14);
      expect(result.minute, 30);
      expect(result.second, 0);
    });

    test('without bounds, hour/minute columns span full ranges', () {
      final model = DateTimePickerModel(
        currentTime: DateTime(2020, 5, 10, 8, 0),
      );
      // hours 0..23
      expect(model.middleStringAtIndex(0), '00');
      expect(model.middleStringAtIndex(23), '23');
      expect(model.middleStringAtIndex(24), isNull);
      // minutes 0..59
      expect(model.rightStringAtIndex(59), '59');
      expect(model.rightStringAtIndex(60), isNull);
      // left (day) column is non-null at the start
      expect(model.leftStringAtIndex(0), isNotNull);
    });

    test('maxTime terminates the day column after the max day', () {
      final model = DateTimePickerModel(
        currentTime: DateTime(2020, 5, 10, 8, 0),
        maxTime: DateTime(2020, 5, 12, 20, 0),
      );
      // day 0 = 2020-05-10 ... day 2 = 2020-05-12 (max day, allowed)
      expect(model.leftStringAtIndex(0), isNotNull);
      expect(model.leftStringAtIndex(2), isNotNull);
      // day 3 = 2020-05-13 is past maxTime
      expect(model.leftStringAtIndex(3), isNull);
    });

    test('minTime offsets the hour column on the min day', () {
      final model = DateTimePickerModel(
        currentTime: DateTime(2020, 5, 10, 8, 0),
        minTime: DateTime(2020, 5, 10, 6, 0),
      );
      // hours start at the min hour (06) and run to 23
      expect(model.middleStringAtIndex(0), '06');
      expect(model.middleStringAtIndex(17), '23');
      expect(model.middleStringAtIndex(18), isNull);
    });

    test('minTime offset round-trips through finalTime', () {
      final model = DateTimePickerModel(
        currentTime: DateTime(2020, 5, 10, 8, 0),
        minTime: DateTime(2020, 5, 10, 6, 0),
      );
      final result = model.finalTime();
      expect(result.year, 2020);
      expect(result.month, 5);
      expect(result.day, 10);
      expect(result.hour, 8);
      expect(result.minute, 0);
    });

    test('layout gives the date column the most space', () {
      final model = DateTimePickerModel(currentTime: DateTime(2020, 5, 10));
      expect(model.layoutProportions(), [4, 1, 1]);
      expect(model.rightDivider(), ':');
    });
  });

  group('formatDate', () {
    final date = DateTime(1989, 2, 5, 9, 4, 7, 99);

    test('numeric date tokens', () {
      expect(formatDate(date, [yyyy], LocaleType.en), '1989');
      expect(formatDate(date, [yy], LocaleType.en), '89');
      expect(formatDate(date, [mm], LocaleType.en), '02');
      expect(formatDate(date, [m], LocaleType.en), '2');
      expect(formatDate(date, [dd], LocaleType.en), '05');
      expect(formatDate(date, [d], LocaleType.en), '5');
    });

    test('numeric time tokens', () {
      expect(formatDate(date, [HH], LocaleType.en), '09');
      expect(formatDate(date, [H], LocaleType.en), '9');
      expect(formatDate(date, [hh], LocaleType.en), '09');
      expect(formatDate(date, [h], LocaleType.en), '9');
      expect(formatDate(date, [nn], LocaleType.en), '04');
      expect(formatDate(date, [n], LocaleType.en), '4');
      expect(formatDate(date, [ss], LocaleType.en), '07');
    });

    test('12-hour token wraps the afternoon', () {
      final pm = DateTime(1989, 2, 5, 15, 0);
      expect(formatDate(pm, [hh], LocaleType.en), '03');
      expect(formatDate(pm, [h], LocaleType.en), '3');
    });

    test('am token resolves AM/PM by locale', () {
      expect(formatDate(DateTime(1989, 2, 5, 9), [am], LocaleType.en), 'AM');
      expect(formatDate(DateTime(1989, 2, 5, 15), [am], LocaleType.en), 'PM');
    });

    test('localized month names', () {
      expect(formatDate(date, [MM], LocaleType.en), 'February');
      expect(formatDate(date, [M], LocaleType.en), 'Feb');
    });

    test('localized weekday name', () {
      // 2018-01-14 is a Sunday
      expect(formatDate(DateTime(2018, 1, 14), [D], LocaleType.en), 'Sun');
    });

    test('literal tokens are passed through and concatenated', () {
      expect(
        formatDate(date, [yyyy, '-', mm, '-', dd], LocaleType.en),
        '1989-02-05',
      );
    });
  });

  group('digits', () {
    test('left-pads with zeroes to the requested width', () {
      expect(digits(5, 2), '05');
      expect(digits(7, 3), '007');
    });

    test('does not truncate values wider than the width', () {
      expect(digits(123, 2), '123');
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

  group('DatePicker.titleActionsBuilder', () {
    // Pumps a host app and returns a BuildContext from which a picker can be
    // shown.
    Future<BuildContext> pumpHost(WidgetTester tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          ctx = context;
          return const SizedBox();
        }),
      ));
      return ctx;
    }

    testWidgets('replaces the default Cancel/Done bar', (tester) async {
      final ctx = await pumpHost(tester);

      unawaited(DatePicker.showDatePicker(
        ctx,
        titleActionsBuilder: (context, onCancel, onConfirm, currentTime) {
          // Lightweight widgets that fit within the fixed title height.
          return Row(
            children: [
              GestureDetector(onTap: onCancel, child: const Text('Nope')),
              GestureDetector(onTap: onConfirm, child: const Text('Yep')),
            ],
          );
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('Yep'), findsOneWidget);
      expect(find.text('Nope'), findsOneWidget);
      // The built-in bar is gone.
      expect(find.text('Done'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('custom confirm pops with the selection and fires onConfirm',
        (tester) async {
      final ctx = await pumpHost(tester);

      DateTime? confirmed;
      final future = DatePicker.showDatePicker(
        ctx,
        currentTime: DateTime(2020, 5, 10),
        onConfirm: (date) => confirmed = date,
        titleActionsBuilder: (context, onCancel, onConfirm, currentTime) {
          return GestureDetector(onTap: onConfirm, child: const Text('Yep'));
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yep'));
      await tester.pumpAndSettle();

      expect(await future, DateTime(2020, 5, 10));
      expect(confirmed, DateTime(2020, 5, 10));
    });

    testWidgets('custom cancel pops with null and fires onCancel',
        (tester) async {
      final ctx = await pumpHost(tester);

      var cancelled = false;
      final future = DatePicker.showDatePicker(
        ctx,
        onCancel: () => cancelled = true,
        titleActionsBuilder: (context, onCancel, onConfirm, currentTime) {
          return GestureDetector(onTap: onCancel, child: const Text('Nope'));
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nope'));
      await tester.pumpAndSettle();

      expect(await future, isNull);
      expect(cancelled, isTrue);
    });
  });
}
