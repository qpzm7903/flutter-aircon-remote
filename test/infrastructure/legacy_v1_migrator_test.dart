import 'dart:convert';

import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/method_channel_shared_preferences.dart';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_aircon_remote/infrastructure/persistence/legacy_v1_migrator.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<SharedPreferences> prefs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  Future<void> migrate(SharedPreferences p) =>
      LegacyV1Migrator(p, fallbackProtocolId: 'gree.yaw1f').migrateIfNeeded();
  test(
    'selected legacy state becomes one device; old keys retained; idempotent',
    () async {
      final state = const AcState.initial().copyWith(
        power: true,
        targetTempC: 23,
      );
      final p = await prefs({
        'remote.protocolId': 'gree.ybofb',
        'remote.state.gree.yaw1f': '{}',
        'remote.state.gree.ybofb': jsonEncode(state.toJson()),
        'ui.themeMode': 'dark',
      });
      await migrate(p);
      final index =
          jsonDecode(p.getString('device.index')!) as Map<String, dynamic>;
      final d = (index['devices'] as List).single as Map;
      expect(d['id'], 'legacy-1');
      expect(d['name'], '我的空调');
      expect(d['protocolId'], 'gree.ybofb');
      expect(d['pairingConfirmed'], false);
      expect(
        AcState.fromJson(
          jsonDecode(p.getString('device.state.legacy-1')!)
              as Map<String, dynamic>,
        ),
        state,
      );
      expect(p.get('remote.protocolId'), 'gree.ybofb');
      expect(p.get('remote.state.gree.yaw1f'), '{}');
      final before = {for (final k in p.getKeys()) k: p.get(k)};
      await migrate(p);
      expect({for (final k in p.getKeys()) k: p.get(k)}, before);
    },
  );
  test('state only uses fallback; new install remains empty', () async {
    var p = await prefs({'remote.state.gree.yaw1f': '{"power":true}'});
    await migrate(p);
    expect(p.getString('device.state.legacy-1'), contains('"power":true'));
    p = await prefs({});
    await migrate(p);
    expect(p.getInt('app.schemaVersion'), 2);
    expect(p.get('device.index'), null);
  });
  test(
    'schema 2 skips legacy entirely; corrupt state safe; unknown id retained',
    () async {
      var p = await prefs({'app.schemaVersion': 2, 'remote.protocolId': 'bad'});
      await migrate(p);
      expect(p.get('device.index'), null);
      p = await prefs({
        'remote.protocolId': 'unknown',
        'remote.state.unknown': 42,
        'remote.state.other': '{',
      });
      await migrate(p);
      expect(p.getString('device.index'), contains('unknown'));
      expect(
        p.getString('device.state.legacy-1'),
        jsonEncode(const AcState.initial().toJson()),
      );
    },
  );
  test(
    'commit failure retries only schema and second run writes nothing',
    () async {
      SharedPreferences.resetStatic();
      SharedPreferencesStorePlatform.instance =
          MethodChannelSharedPreferencesStore();
      const channel = MethodChannel('plugins.flutter.io/shared_preferences');
      final storage = <String, Object>{
        'flutter.remote.protocolId': 'gree.yaw1f',
      };
      final writes = <String>[];
      var fail = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getAll') return Map<String, Object>.of(storage);
            final args = call.arguments as Map;
            final key = args['key'] as String;
            writes.add(key);
            if (key == 'flutter.app.schemaVersion' && fail) return false;
            storage[key] = args['value'] as Object;
            return true;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        SharedPreferences.resetStatic();
      });
      var p = await SharedPreferences.getInstance();
      await expectLater(migrate(p), throwsStateError);
      expect(writes, [
        'flutter.device.state.legacy-1',
        'flutter.device.index',
        'flutter.app.schemaVersion',
      ]);
      final index = storage['flutter.device.index'];
      fail = false;
      SharedPreferences.resetStatic();
      p = await SharedPreferences.getInstance();
      await migrate(p);
      expect(storage['flutter.device.index'], index);
      expect(writes.skip(3), ['flutter.app.schemaVersion']);
      final count = writes.length;
      await migrate(p);
      expect(writes.length, count);
      expect(storage['flutter.remote.protocolId'], 'gree.yaw1f');
    },
  );
  test(
    'existing index without schema preserves all devices and state',
    () async {
      final p = await prefs({
        'remote.protocolId': 'gree.yaw1f',
        'device.index': '{"v":2,"devices":[{"id":"new-device"}]}',
        'device.state.legacy-1': 'existing legacy state',
        'device.state.new-device': 'user state',
      });
      final before = {for (final k in p.getKeys()) k: p.get(k)};
      await migrate(p);
      expect({for (final k in before.keys) k: p.get(k)}, before);
      expect(p.getInt('app.schemaVersion'), 2);
    },
  );
}
