import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_aircon_remote/presentation/strings.dart';
import 'package:flutter_aircon_remote/presentation/widgets/temperature_display.dart';
import 'package:flutter_aircon_remote/presentation/widgets/mode_selector.dart';
import 'package:flutter_aircon_remote/domain/ac_enums.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('no emitter shows banner and ignores remote input', (
    tester,
  ) async {
    final (c, ir) = await pumpApp(tester, hasEmitter: false);
    expect(find.text(Strings.noIr), findsOneWidget);
    expect(find.text(Strings.recheck), findsOneWidget);
    final ignored = tester.widget<IgnorePointer>(
      find
          .ancestor(
            of: find.byType(TemperatureDisplay),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(ignored.ignoring, true);
    await tester.tap(find.byTooltip(Strings.increase), warnIfMissed: false);
    await tester.pump();
    expect(ir.sent, isEmpty);
    expect(c.state.targetTempC, 26);
    expect(find.text('健康'), findsNothing);
    ir.hasEmitter = true;
    await tester.tap(find.text(Strings.recheck));
    await tester.pumpAndSettle();
    expect(find.text(Strings.noIr), findsNothing);
  });
  testWidgets(
    'temperature and mode send and mode capabilities disable temperature',
    (tester) async {
      final (c, ir) = await pumpApp(tester);
      await tester.tap(find.byTooltip(Strings.increase));
      await tester.pumpAndSettle();
      expect(c.state.targetTempC, 27);
      expect(ir.sent.length, 1);
      await tester.ensureVisible(find.byType(ModeSelector));
      await tester.tap(find.text('自动').first);
      await tester.pumpAndSettle();
      expect(c.state.mode, AcMode.auto);
      expect(c.state.targetTempC, 25);
      expect(ir.sent.length, 2);
      final minus = tester.widget<IconButton>(
        find.descendant(
          of: find.byTooltip(Strings.decrease),
          matching: find.byType(IconButton),
        ),
      );
      expect(minus.onPressed, null);
      expect(find.text('健康'), findsNothing);
    },
  );
  testWidgets('long press repeats and stops on release', (tester) async {
    final (c, ir) = await pumpApp(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byTooltip(Strings.increase)),
    );
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump(const Duration(milliseconds: 320));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(c.state.targetTempC, greaterThan(27));
    expect(ir.sent, isNotEmpty);
    final count = ir.sent.length;
    await tester.pump(const Duration(milliseconds: 500));
    expect(ir.sent.length, count);
  });
  testWidgets('theme and diagnostics are available', (tester) async {
    await pumpApp(tester, hasEmitter: false);
    await tester.tap(find.byTooltip(Strings.theme));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(Strings.diagnostics));
    await tester.pumpAndSettle();
    expect(find.textContaining('版本: 0.1.0'), findsOneWidget);
    expect(find.byTooltip(Strings.copy), findsOneWidget);
  });
}
