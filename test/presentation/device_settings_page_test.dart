import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/presentation/strings.dart';

import '../support/pump_app.dart';

Future<void> openSettings(WidgetTester t) async {
  await t.tap(find.byTooltip('设备设置'));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('protocol title; hide light, save and remote reflects change', (
    t,
  ) async {
    await pumpApp(t);
    await openSettings(t);
    await t.scrollUntilVisible(
      find.text(Strings.protocolTitle),
      300,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    expect(find.text(Strings.protocolTitle), findsOneWidget);
    await t.scrollUntilVisible(
      find.text('灯光'),
      400,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await t.tap(find.widgetWithText(SwitchListTile, '灯光'));
    await t.pumpAndSettle();
    await t.tap(find.text('保存'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      find.text(Strings.features),
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    expect(find.text('灯光'), findsNothing);
  });
  testWidgets('unsaved back confirms discard', (t) async {
    await pumpApp(t);
    await openSettings(t);
    await t.enterText(find.byType(TextFormField).first, '新名');
    await t.pump();
    await t.pageBack();
    await t.pumpAndSettle();
    expect(find.text('放弃未保存的修改？'), findsOneWidget);
    await t.tap(find.text('放弃'));
    await t.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '主卧'), findsOneWidget);
  });
  testWidgets('settings delete confirms', (t) async {
    await pumpApp(t);
    await openSettings(t);
    await t.scrollUntilVisible(
      find.text('删除此空调'),
      500,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await t.tap(find.text('删除此空调'));
    await t.pumpAndSettle();
    expect(find.text('仅删除本应用中的记录，不影响空调本身。'), findsOneWidget);
    await t.tap(find.text('取消'));
    await t.pumpAndSettle();
    expect(find.text('删除此空调'), findsOneWidget);
  });
  testWidgets('confirmed settings delete returns from remote to home', (
    t,
  ) async {
    await pumpApp(t);
    await openSettings(t);
    await t.scrollUntilVisible(
      find.text(Strings.deleteDevice),
      500,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await t.tap(find.text(Strings.deleteDevice));
    await t.pumpAndSettle();
    await t.tap(find.text(Strings.delete));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text(Strings.emptyTitle), findsOneWidget);
    final context = t.element(find.text(Strings.emptyTitle));
    expect(Navigator.of(context).canPop(), false);
  });
}
