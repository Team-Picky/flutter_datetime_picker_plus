import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A mouse wheel sends one PointerScrollEvent per notch, with a pause before
// the next one. Its size varies: typically 100 pixels on Windows, but on web
// a smooth-scrolling mouse can send ~13 pixels and be reported as a trackpad.
// Each notch should move a column by one row. A trackpad on web sends a
// continuous stream of small events, which should scroll by distance.
void main() {
  Future<Future<DateTime?>> showTimePicker(
      WidgetTester tester, DateTime currentTime,
      {List<DateTime>? changes}) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        ctx = context;
        return const SizedBox();
      }),
    ));
    final result = DatePicker.showTimePicker(
      ctx,
      currentTime: currentTime,
      showSecondsColumn: false,
      onChanged: changes?.add,
    );
    await tester.pumpAndSettle();
    return result;
  }

  Future<DateTime?> confirm(
      WidgetTester tester, Future<DateTime?> result) async {
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    return result;
  }

  // Sends one scroll event per entry in [deltas], [interval] apart.
  Future<void> scroll(
    WidgetTester tester,
    Finder column,
    List<double> deltas, {
    Duration interval = const Duration(milliseconds: 300),
    PointerDeviceKind kind = PointerDeviceKind.mouse,
    Alignment at = Alignment.center,
  }) async {
    final pointer = TestPointer(1, kind);
    final rect = tester.getRect(column);
    await tester.sendEventToBinding(
        pointer.hover(at.withinRect(rect.deflate(8))));
    var time = const Duration(seconds: 1);
    for (final dy in deltas) {
      await tester.sendEventToBinding(
          pointer.scroll(Offset(0, dy), timeStamp: time));
      await tester.pump();
      time += interval;
    }
    await tester.pumpAndSettle();
  }

  Finder column(int index) => find.byType(CupertinoPicker).at(index);

  testWidgets('one notch down selects the next row', (tester) async {
    final changes = <DateTime>[];
    final result = await showTimePicker(tester, DateTime(2026, 1, 1, 10, 30),
        changes: changes);

    await scroll(tester, column(0), [100]);

    expect(changes, [DateTime(2026, 1, 1, 11, 30)]);
    expect(await confirm(tester, result), DateTime(2026, 1, 1, 11, 30));
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('one notch up selects the previous row', (tester) async {
    final result = await showTimePicker(tester, DateTime(2026, 1, 1, 10, 30));

    await scroll(tester, column(1), [-100]);

    expect(await confirm(tester, result), DateTime(2026, 1, 1, 10, 29));
  });

  testWidgets('each notch moves one row', (tester) async {
    final result = await showTimePicker(tester, DateTime(2026, 1, 1, 10, 30));

    await scroll(tester, column(0), [100, 100, 100]);

    expect(await confirm(tester, result), DateTime(2026, 1, 1, 13, 30));
  });

  testWidgets('small notches reported as a trackpad each move one row',
      (tester) async {
    final result = await showTimePicker(tester, DateTime(2026, 1, 1, 23, 12));

    await scroll(tester, column(0), [-12, -13, -13],
        kind: PointerDeviceKind.trackpad);

    expect(await confirm(tester, result), DateTime(2026, 1, 1, 20, 12));
  });

  testWidgets('works with the pointer past the last row', (tester) async {
    // Hour 23 is the last row, so the lower half of the column is empty.
    final result = await showTimePicker(tester, DateTime(2026, 1, 1, 23, 12));

    await scroll(tester, column(0), [-13], at: const Alignment(0, 0.8));

    expect(await confirm(tester, result), DateTime(2026, 1, 1, 22, 12));
  });

  testWidgets('stops at the ends of a column', (tester) async {
    final result = await showTimePicker(tester, DateTime(2026, 1, 1, 0, 58));

    await scroll(tester, column(0), [-100]); // already at hour 00
    await scroll(tester, column(1), [100, 100]); // past minute 59

    expect(await confirm(tester, result), DateTime(2026, 1, 1, 0, 59));
  });

  testWidgets('a continuous trackpad scroll moves by distance',
      (tester) async {
    final result = await showTimePicker(tester, DateTime(2026, 1, 1, 10, 30));

    // 30 events of 6 pixels, one per frame: 180 pixels in total. The first
    // event moves one row, the other 174 pixels move four more (36 each).
    await scroll(tester, column(0), List.filled(30, 6.0),
        interval: const Duration(milliseconds: 16),
        kind: PointerDeviceKind.trackpad);

    expect(await confirm(tester, result), DateTime(2026, 1, 1, 15, 30));
  });
}
