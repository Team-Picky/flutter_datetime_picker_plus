import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Web and desktop users pick values with a mouse.
void main() {
  Future<Future<DateTime?>> showHourPicker(WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );
    final result = DatePicker.showTimePicker(
      ctx,
      currentTime: DateTime(2026, 1, 1, 10, 30),
      showSecondsColumn: false,
    );
    await tester.pumpAndSettle();
    return result;
  }

  Future<DateTime?> confirm(
    WidgetTester tester,
    Future<DateTime?> result,
  ) async {
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    return result;
  }

  Finder hourColumn() => find.byType(CupertinoPicker).at(0);

  testWidgets('dragging a column with the mouse scrolls it', (tester) async {
    final result = await showHourPicker(tester);

    // Drag up by about three rows.
    final gesture = await tester.startGesture(
      tester.getCenter(hourColumn()),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(0, -20));
    await gesture.moveBy(const Offset(0, -88));
    await gesture.up();
    await tester.pumpAndSettle();

    final picked = await confirm(tester, result);
    expect(picked!.hour, greaterThan(10));
    expect(picked.minute, 30);
  }, variant: TargetPlatformVariant.desktop());
}
