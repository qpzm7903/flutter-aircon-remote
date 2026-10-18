import 'dart:convert';

import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/method_channel_shared_preferences.dart';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_aircon_remote/infrastructure/persistence/shared_prefs_device_repository.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';

import '../support/pump_app.dart';

import 'package:flutter_aircon_remote/domain/ac_enums.dart';
import 'package:flutter_aircon_remote/domain/capability_overrides.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<SharedPrefsDeviceRepository> repo(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues({'app.schemaVersion': 2, ...values});
    return SharedPrefsDeviceRepository(
      await SharedPreferences.getInstance(),
      fallbackProtocolId: 'gree.yaw1f',
    );
  }

  test('v3 state and horizontal override roundtrip', () async {
    final r = await repo({'app.schemaVersion': 3});
    final state = const AcState.initial().copyWith(
      targetTempF: 79,
      timerMinutes: 90,
      timerSetAtMs: 123,
      horizontalSwing: HorizontalSwing.left,
      verticalSwing: VerticalSwing.autoUp,
    );
    final d = testDevice(
      overrides: const CapabilityOverrides(
        hiddenHSwings: {HorizontalSwing.right},
      ),
    ).copyWith(state: state);
    await r.saveDevices([d]);
    await r.saveState(d.id, state.copyWith(wifiPulse: true));
    final actual = (await r.load()).single;
    expect(actual.state, state);
    expect(actual.overrides, d.overrides);
  });
  test(
    'metadata and state CRUD; ordering renumbered; orphan preserved',
    () async {
      final r = await repo({'device.state.orphan': '{}'});
      await r.saveDevices([
        testDevice(id: 'b').copyWith(sortOrder: 9),
        testDevice(id: 'a'),
      ]);
      final p = await SharedPreferences.getInstance();
      expect(p.get('device.state.b'), null);
      await r.saveState('b', const AcState.initial().copyWith(power: true));
      final ds = await r.load();
      expect(ds.map((d) => d.id), ['b', 'a']);
      expect(ds.map((d) => d.sortOrder), [0, 1]);
      expect(ds.first.state.power, true);
      await r.saveDevices([ds.last.copyWith(name: '更新')]);
      await r.deleteState('b');
      expect((await r.load()).single.name, '更新');
      expect(p.get('device.state.b'), null);
      expect(p.get('device.state.orphan'), '{}');
    },
  );
  for (final bad in ['{', '{}', '{"devices":4}', 42]) {
    test('index corruption $bad backed up', () async {
      final r = await repo({'device.index': bad});
      expect(await r.load(), isEmpty);
      final p = await SharedPreferences.getInstance();
      expect(p.getString('device.index.corrupt'), bad.toString());
    });
  }
  test(
    'bad entries skipped, duplicate first kept, state fallback and stable sort',
    () async {
      final r = await repo({
        'device.index': jsonEncode({
          'v': 2,
          'devices': [
            4,
            {},
            testDevice().toMetaJson(),
            testDevice().copyWith(name: '重复').toMetaJson(),
            testDevice(id: 'd2').toMetaJson(),
          ],
        }),
        'device.state.d1': '[',
        'device.state.d2': 42,
      });
      final ds = await r.load();
      expect(ds.map((d) => d.id), ['d1', 'd2']);
      expect(ds.first.name, '主卧');
      expect(ds.every((d) => d.state == const AcState.initial()), true);
    },
  );
  test('write false throws StateError', () async {
    SharedPreferences.resetStatic();
    SharedPreferencesStorePlatform.instance =
        MethodChannelSharedPreferencesStore();
    const channel = MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getAll') return <String, Object>{};
          return false;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      SharedPreferences.resetStatic();
    });
    final r = SharedPrefsDeviceRepository(
      await SharedPreferences.getInstance(),
      fallbackProtocolId: 'gree.yaw1f',
    );
    await expectLater(r.saveDevices([testDevice()]), throwsStateError);
    await expectLater(
      r.saveState('d1', const AcState.initial()),
      throwsStateError,
    );
  });
}
