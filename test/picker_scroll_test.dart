import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_test/flutter_test.dart';

// Tapping a row makes CupertinoPicker scroll to it for 300 ms and then read
// its controller. These tests tap rows and act again before that scroll ends.
void main() {
  // Pumps frames one at a time, so scroll animations run as they would on a
  // device.
  Future<void> frames(WidgetTester tester, int ms) async {
    for (var t = 0; t < ms; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

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

  Finder row(int column, String text) => find.descendant(
        of: find.byType(CupertinoPicker).at(column),
        matching: find.text(text),
      );

  testWidgets('tapping another column while one is scrolling keeps both taps',
      (tester) async {
    final ctx = await pumpHost(tester);
    final initial = DateTime(2026, 9, 23, 10, 30);
    final changes = <DateTime>[];
    final result = DatePicker.showDateTimePicker(
      ctx,
      currentTime: initial,
      onChanged: changes.add,
    );
    await tester.pumpAndSettle();

    final model = DateTimePickerModel(currentTime: initial);
    await tester.tap(row(0, model.leftStringAtIndex(2)!)); // two days later
    await frames(tester, 150);
    await tester.tap(row(1, '12')); // two hours later
    await frames(tester, 1000);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await result, DateTime(2026, 9, 25, 12, 30));
    // One onChanged per column that stopped scrolling, and none for the
    // wheels this package moves itself.
    expect(changes, hasLength(2));
    expect(changes.last, DateTime(2026, 9, 25, 12, 30));
  });

  testWidgets('changing the month updates the day column', (tester) async {
    final ctx = await pumpHost(tester);
    final result = DatePicker.showDatePicker(
      ctx,
      currentTime: DateTime(2026, 1, 31),
    );
    await tester.pumpAndSettle();

    await tester.tap(row(1, 'February'));
    await tester.pumpAndSettle();

    // February has no 29th to 31st.
    expect(row(2, '28'), findsOneWidget);
    expect(row(2, '31'), findsNothing);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await result, DateTime(2026, 2, 28));
  });

  testWidgets('pressing Done right after tapping a row', (tester) async {
    final ctx = await pumpHost(tester);
    final result = DatePicker.showDatePicker(
      ctx,
      currentTime: DateTime(2026, 9, 23),
    );
    await tester.pumpAndSettle();

    await tester.tap(row(2, '25'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    final picked = await result;
    expect(picked, isNotNull);
    expect(picked!.day, inInclusiveRange(23, 25));
  });

  testWidgets('tapping the barrier right after tapping a row', (tester) async {
    final ctx = await pumpHost(tester);
    final result = DatePicker.showDatePicker(
      ctx,
      currentTime: DateTime(2026, 9, 23),
    );
    await tester.pumpAndSettle();

    await tester.tap(row(2, '25'));
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });
}
