import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/presentation/strings.dart';

import '../support/pump_app.dart';

Future<void> enterPairing(WidgetTester t) async {
  await t.tap(find.text(Strings.addDevice).first);
  await t.pumpAndSettle();
  expect(find.textContaining('红外是单向的'), findsOneWidget);
  await t.tap(find.text('开始'));
  await t.pumpAndSettle();
  await t.tap(find.text('下一步'));
  await t.pumpAndSettle();
  expect(find.text('请输入名称（1–20 个字）'), findsOneWidget);
  await t.enterText(find.byType(TextFormField).first, '书房');
  await t.tap(find.text('下一步'));
  await t.pumpAndSettle();
  await t.tap(find.text('下一步'));
  await t.pumpAndSettle();
  await t.tap(find.text('开始测试'));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('success creates named device', (t) async {
    final (ds, ir) = await pumpHome(t, empty: true);
    await enterPairing(t);
    expect(find.text('空调有响应（滴声）吗？'), findsOneWidget);
    expect(find.text('重发'), findsOneWidget);
    expect(find.text('没反应，试下一个'), findsOneWidget);
    expect(ds.devices, isEmpty);
    await t.tap(find.text('有响应'));
    await t.pumpAndSettle();
    expect(ds.devices.single.name, '书房');
    expect(ds.devices.single.pairingConfirmed, true);
    expect(ir.sent.length, 1);
    expect(find.text('书房'), findsOneWidget);
  });
  testWidgets('all fail gives tips and still save', (t) async {
    final (ds, ir) = await pumpHome(t, empty: true);
    await enterPairing(t);
    for (var i = 0; i < 3; i++) {
      await t.tap(find.text('没反应，试下一个'));
      await t.pumpAndSettle();
    }
    expect(ir.sent.map((f) => f.debugHex).toSet().length, 3);
    expect(find.text('三种型号都没有听到响应'), findsOneWidget);
    await t.ensureVisible(find.text('仍然保存'));
    await t.tap(find.text('仍然保存'));
    await t.pumpAndSettle();
    expect(ds.devices.single.pairingConfirmed, false);
  });
  testWidgets('no emitter can skip without transmission', (t) async {
    final (ds, ir) = await pumpHome(t, empty: true, hasEmitter: false);
    await t.tap(find.text(Strings.addDevice).first);
    await t.pumpAndSettle();
    expect(find.text(Strings.noIr), findsOneWidget);
    await t.tap(find.text('开始'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField).first, '书房');
    await t.tap(find.text('下一步'));
    await t.pumpAndSettle();
    await t.tap(find.text('下一步'));
    await t.pumpAndSettle();
    expect(find.text('开始测试'), findsNothing);
    await t.tap(find.text('跳过'));
    await t.pumpAndSettle();
    expect(ds.devices.length, 1);
    expect(ir.sent, isEmpty);
  });
}
