import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A mouse wheel sends a PointerScrollEvent per notch, typically 100 pixels on
// web and desktop. Each notch should move a column by one row.
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

  Future<void> scrollWheel(WidgetTester tester, Finder column, double dy,
      {PointerDeviceKind kind = PointerDeviceKind.mouse}) async {
    final pointer = TestPointer(1, kind);
    await tester.sendEventToBinding(pointer.hover(tester.getCenter(column)));
    await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
    await tester.pumpAndSettle();
  }

  Finder column(int index) => find.byType(CupertinoPicker).at(index);

  testWidgets('one notch down selects the next row', (tester) async {
    final changes = <DateTime>[];
    final result = await showTimePicker(tester, DateTime(2026, 1, 1, 10, 30),
        changes: changes);

    await scrollWheel(tester, column(0), 100);

    expect(changes, [DateTime(2026, 1, 1, 11, 30)]);
    expect(await confirm(tester, result), DateTime(2026, 1, 1, 11, 30));
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('one notch up selects the previous row', (tester) async {
    final result = await showTimePicker(tester, DateTime(2026, 1, 1, 10, 30));

    await scrollWheel(tester, column(1), -100);

    expect(await confirm(tester, result), DateTime(2026, 1, 1, 10, 29));
  });

  testWidgets('each notch moves one row', (tester) async {
    final result = await showTimePicker(tester, DateTime(2026, 1, 1, 10, 30));

    for (var i = 0; i < 3; i++) {
      await scrollWheel(tester, column(0), 100);
    }

    expect(await confirm(tester, result), DateTime(2026, 1, 1, 13, 30));
  });

  testWidgets('stops at the ends of a column', (tester) async {
    final result = await showTimePicker(tester, DateTime(2026, 1, 1, 0, 58));

    await scrollWheel(tester, column(0), -100); // already at hour 00
    await scrollWheel(tester, column(1), 100);
    await scrollWheel(tester, column(1), 100); // past minute 59

    expect(await confirm(tester, result), DateTime(2026, 1, 1, 0, 59));
  });

  testWidgets('trackpad scrolling still scrolls by distance', (tester) async {
    final result = await showTimePicker(tester, DateTime(2026, 1, 1, 10, 30));

    await scrollWheel(tester, column(0), 100, kind: PointerDeviceKind.trackpad);

    expect((await confirm(tester, result))!.hour, greaterThan(11));
  });
}
