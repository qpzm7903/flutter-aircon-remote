import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/domain/ac_enums.dart';
import 'package:flutter_aircon_remote/presentation/strings.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('recommended seeds hide all new controls', (t) async {
    final registry = testRegistry();
    await pumpApp(
      t,
      device: testDevice(overrides: registry.fallback.recommendedOverrides),
    );
    await t.scrollUntilVisible(find.text(Strings.features), 200);
    expect(find.text(Strings.horizontalSwing), findsNothing);
    expect(find.text('℉'), findsNothing);
    expect(find.text('定时（实验） · 未设置'), findsNothing);
    expect(find.text('空调 Wi‑Fi'), findsNothing);
    expect(find.byType(DropdownButton<TempDisplay>), findsNothing);
    expect(find.textContaining('下一档'), findsOneWidget);
  });
  testWidgets(
    'horizontal choices emit exact frame; display cycles; WiFi one-shot',
    (t) async {
      final (c, ir) = await pumpApp(t);
      final power = c.togglePower();
      await t.pumpAndSettle();
      await power;
      await t.scrollUntilVisible(find.text(Strings.horizontalSwing), 200);
      for (final label in ['关', '自动', '最左', '偏左', '居中', '偏右', '最右']) {
        expect(find.text(label), findsWidgets);
      }
      await t.ensureVisible(find.text('最左'));
      await t.tap(find.text('最左'));
      await t.pumpAndSettle();
      expect(ir.sent.last.debugHex, '09 0A 60 50 20 20 00 10');
      await t.ensureVisible(find.textContaining('下一档'));
      await t.tap(find.textContaining('下一档'));
      await t.pumpAndSettle();
      expect(c.state.tempDisplay, TempDisplay.setpoint);
      await t.ensureVisible(find.text('空调 Wi‑Fi'));
      final before = ir.sent.length;
      await t.tap(find.text('空调 Wi‑Fi'));
      await t.pumpAndSettle();
      expect(ir.sent.length, before + 1);
      expect(
        int.parse(ir.sent.last.debugHex.split(' ')[5], radix: 16) & 64,
        64,
      );
      expect(c.state.wifiPulse, false);
      expect(find.text('已发送一次 Wi‑Fi 键'), findsOneWidget);
    },
  );
  testWidgets('Fahrenheit display and step; timer picker and estimate', (
    t,
  ) async {
    final (c, ir) = await pumpApp(t);
    await t.tap(find.text('℉'));
    await t.pumpAndSettle();
    expect(find.text('79 °F'), findsOneWidget);
    expect(ir.sent.length, 1);
    await t.tap(find.byTooltip(Strings.increase));
    await t.pumpAndSettle();
    expect(find.text('80 °F'), findsOneWidget);
    await t.scrollUntilVisible(find.text('定时（实验） · 未设置'), 200);
    await t.tap(find.text('定时（实验） · 未设置'));
    await t.pumpAndSettle();
    expect(find.text(Strings.timerNote), findsOneWidget);
    expect(find.text('1 小时'), findsOneWidget);
    expect(find.text('1 小时 30 分'), findsOneWidget);
    expect(find.text('1.0 h'), findsNothing);
    await t.tap(find.text('30 分钟'));
    await t.pumpAndSettle();
    expect(c.state.timerMinutes, 30);
    expect(find.text('定时（实验）（估算） · 约 0 小时 30 分后'), findsOneWidget);
  });
}
