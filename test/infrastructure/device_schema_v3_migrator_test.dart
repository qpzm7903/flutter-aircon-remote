import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/method_channel_shared_preferences.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_aircon_remote/infrastructure/persistence/device_schema_v3_migrator.dart';
import 'package:flutter_aircon_remote/infrastructure/persistence/shared_prefs_device_repository.dart';

import '../support/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<SharedPreferences> prefs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  Map<String, Object?> snapshot(SharedPreferences p) => {
    for (final k in p.getKeys()) k: p.get(k),
  };
  for (final failKey in ['device.index', 'app.schemaVersion']) {
    test(
      'v3 interrupted $failKey retry preserves index and is zero-write idempotent',
      () async {
        SharedPreferences.resetStatic();
        SharedPreferencesStorePlatform.instance =
            MethodChannelSharedPreferencesStore();
        const channel = MethodChannel('plugins.flutter.io/shared_preferences');
        final storage = <String, Object>{
          'flutter.app.schemaVersion': 2,
          'flutter.device.index': '{"v":2,"devices":[{"id":"d1","overrides":{"hiddenFeatures":["light"]}}]}',
        };
        final writes = <String>[];
        var fail = true;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'getAll') {
                return Map<String, Object>.of(storage);
              }
              final args = call.arguments as Map;
              final key = args['key'] as String;
              writes.add(key);
              if (fail && key == 'flutter.$failKey') return false;
              storage[key] = args['value'] as Object;
              return true;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
          SharedPreferences.resetStatic();
        });
        final p = await SharedPreferences.getInstance();
        await expectLater(
          DeviceSchemaV3Migrator(p).migrateIfNeeded(),
          throwsStateError,
        );
        expect(storage['flutter.app.schemaVersion'], 2);
        final index = storage['flutter.device.index'];
        fail = false;
        writes.clear();
        // The migrator reloads the optimistic cache after a failed write.
        final restarted = p;
        await DeviceSchemaV3Migrator(restarted).migrateIfNeeded();
        if (failKey == 'app.schemaVersion') {
          expect(writes, ['flutter.app.schemaVersion']);
          expect(storage['flutter.device.index'], index);
        }
        expect(storage['flutter.app.schemaVersion'], 3);
        final committed = Map<String, Object>.of(storage);
        writes.clear();
        await DeviceSchemaV3Migrator(restarted).migrateIfNeeded();
        expect(writes, isEmpty);
        expect(storage, committed);
      },
    );
  }
  test('v2 metadata union preserves unknown fields, ordering and raw states; idempotent', () async {
    final entries = [
      testDevice(id: 'b').toMetaJson(),
      testDevice(id: 'a').toMetaJson(),
    ];
    entries.first['overrides'] = {
      'hiddenFeatures': ['light', 'unknown'],
      'hiddenSwings': ['low'],
      'extra': 42,
    };
    final p = await prefs({
      'app.schemaVersion': 2,
      'device.index': jsonEncode({
        'v': 2,
        'extra': 'keep',
        'devices': [...entries, 42],
      }),
      'device.state.a': '{"v":1,"targetTempC":23}',
      'theme': 'dark',
    });
    final before = snapshot(p);
    await DeviceSchemaV3Migrator(p).migrateIfNeeded();
    final index = jsonDecode(p.getString('device.index')!) as Map;
    expect(index['v'], 3);
    expect(index['extra'], 'keep');
    final ds = index['devices'] as List;
    expect(ds.last, 42);
    for (var i = 0; i < 2; i++) {
      final actual = Map<String, dynamic>.from(ds[i] as Map)
        ..remove('overrides');
      final old = Map<String, dynamic>.from(entries[i])..remove('overrides');
      expect(actual, old);
      expect(
        ds[i]['overrides']['hiddenFeatures'],
        containsAll(['swingH', 'wifi', 'timer', 'fahrenheit']),
      );
      expect(
        ds[i]['overrides']['hiddenSwings'],
        containsAll(['autoDown', 'autoMiddle', 'autoUp']),
      );
    }
    expect(
      ds.first['overrides']['hiddenFeatures'],
      containsAll(['light', 'unknown']),
    );
    expect(ds.first['overrides']['extra'], 42);
    expect(p.get('device.state.a'), before['device.state.a']);
    expect(p.get('theme'), 'dark');
    expect(p.get('app.schemaVersion'), 3);
    final migrated = snapshot(p);
    await DeviceSchemaV3Migrator(p).migrateIfNeeded();
    expect(snapshot(p), migrated);
  });
  test('index committed but schema uncommitted only commits schema', () async {
    const index = '{"v":3,"devices":[{"overrides":{"hiddenFeatures":[]}}]}';
    final p = await prefs({'app.schemaVersion': 2, 'device.index': index});
    await DeviceSchemaV3Migrator(p).migrateIfNeeded();
    expect(p.get('device.index'), index);
    expect(p.get('app.schemaVersion'), 3);
  });
  test('fresh install writes only schema', () async {
    final p = await prefs({});
    await DeviceSchemaV3Migrator(p).migrateIfNeeded();
    expect(snapshot(p), {'app.schemaVersion': 3});
  });
  for (final raw in ['{', '{}', '{"devices":4}', 42]) {
    test('corrupt index $raw untouched', () async {
      final p = await prefs({'app.schemaVersion': 2, 'device.index': raw});
      final before = snapshot(p);
      await DeviceSchemaV3Migrator(p).migrateIfNeeded();
      expect(snapshot(p), before);
    });
  }
  test('v1 to v3 in one repository load with old state defaults', () async {
    final p = await prefs({
      'remote.protocolId': 'gree.yaw1f',
      'remote.state.gree.yaw1f': '{"power":true,"targetTempC":23}',
    });
    await SharedPrefsDeviceRepository(
      p,
      fallbackProtocolId: 'gree.yaw1f',
    ).load();
    expect(p.get('app.schemaVersion'), 3);
    final index = jsonDecode(p.getString('device.index')!);
    expect(index['devices'].length, 1);
    expect(
      index['devices'][0]['overrides']['hiddenFeatures'],
      contains('swingH'),
    );
    expect(
      jsonDecode(p.getString('device.state.legacy-1')!)['targetTempC'],
      23,
    );
  });
}
