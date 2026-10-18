import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/presentation/strings.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('empty state, theme, diagnostics', (t) async {
    await pumpHome(t, empty: true);
    expect(find.text(Strings.emptyTitle), findsOneWidget);
    expect(find.text(Strings.emptyBody), findsOneWidget);
    expect(find.text(Strings.addDevice), findsWidgets);
    await t.tap(find.byTooltip(Strings.theme));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip(Strings.diagnostics));
    await t.pumpAndSettle();
    expect(find.textContaining('版本: 0.2.0'), findsOneWidget);
  });
  testWidgets('list subtitle reorder and navigation', (t) async {
    final (ds, _) = await pumpHome(
      t,
      initial: [
        testDevice(),
        testDevice(id: 'd2', name: '客厅'),
      ],
    );
    expect(find.textContaining('二楼 · 格力 Gree / YAW1F'), findsNWidgets(2));
    final list = t.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorderItem!(0, 1);
    await t.pumpAndSettle();
    expect(ds.devices.first.name, '客厅');
    await t.tap(find.text('客厅'));
    await t.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '客厅'), findsOneWidget);
  });
  testWidgets(
    'deletion requires confirmation and cancellation preserves record',
    (t) async {
      final (ds, _) = await pumpHome(t);
      Future<void> menu() async {
        await t.tap(find.byType(PopupMenuButton<String>));
        await t.pumpAndSettle();
        await t.tap(find.text('删除'));
        await t.pumpAndSettle();
      }

      await menu();
      await t.tap(find.text('取消'));
      await t.pumpAndSettle();
      expect(ds.devices.length, 1);
      await menu();
      await t.tap(find.text('删除'));
      await t.pumpAndSettle();
      expect(ds.devices, isEmpty);
    },
  );
  testWidgets('full list disables add', (t) async {
    await pumpHome(
      t,
      initial: [for (var i = 0; i < 20; i++) testDevice(id: 'd$i')],
    );
    expect(
      t
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .onPressed,
      null,
    );
    expect(find.text('最多 20 台'), findsOneWidget);
  });
}
