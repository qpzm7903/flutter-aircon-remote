import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/application/device_list_controller.dart';
import 'package:flutter_aircon_remote/application/device_settings_controller.dart';
import 'package:flutter_aircon_remote/domain/ac_enums.dart';

import '../support/pump_app.dart';
import '../support/in_memory_device_repository.dart';

void main() {
  late DeviceListController ds;
  late DeviceSettingsController c;
  setUp(() async {
    ds = DeviceListController(
      registry: testRegistry(),
      repository: InMemoryDeviceRepository()..devices = [testDevice()],
    );
    await ds.init();
    c = DeviceSettingsController(
      deviceId: 'd1',
      devices: ds,
      registry: ds.registry,
    );
  });
  tearDown(() {
    c.dispose();
    ds.dispose();
  });
  test('draft validation and save', () async {
    expect(c.hasChanges, false);
    c.setName(' ');
    expect(c.nameError, 'empty');
    expect(await c.save(), false);
    expect(ds.devices.single.name, '主卧');
    c.setName('客厅');
    c.setRoom('一楼');
    c.setIcon(c.draft.icon);
    c.setFeatureVisible(AcFeature.light, false);
    expect(c.effectiveCapabilities.features.contains(AcFeature.light), false);
    expect(await c.save(), true);
    expect(c.hasChanges, false);
    expect(ds.devices.single.name, '客厅');
  });
  test('cannot hide last mode or fan; protocol switch preserves overrides', () {
    for (final m in c.protocolCapabilities.modes) {
      c.setModeVisible(m, false);
    }
    expect(c.lastRejected, true);
    expect(c.effectiveCapabilities.modes.length, 1);
    for (final f in c.protocolCapabilities.fanSpeeds) {
      c.setFanSpeedVisible(f, false);
    }
    expect(c.lastRejected, true);
    expect(c.effectiveCapabilities.fanSpeeds.length, 1);
    c.setProtocol('gree.yx1fsf');
    expect(c.protocolCapabilities.modes, contains(AcMode.econo));
    expect(c.protocolOptions.length, 3);
    c.setAllSwingVisible(false);
    expect(c.effectiveCapabilities.verticalSwings, [VerticalSwing.off]);
    c.setTempRange(18, 28);
    expect(c.effectiveCapabilities.minTempC, 18);
  });
  test('repair saves confirmation and rejects unknown protocols', () async {
    c.setPairing('gree.ybofb', true);
    expect(c.draft.pairingConfirmed, true);
    await c.save();
    expect(ds.devices.single.pairingConfirmed, true);
    c.setPairing('gree.ybofb', false);
    expect(c.draft.pairingConfirmed, true);
    final before = c.draft;
    c.setPairing('unknown', true);
    expect(c.draft, before);
    c.setPairing('gree.yx1fsf', false);
    expect(c.draft.pairingConfirmed, false);
  });
}
