import 'package:flutter_test/flutter_test.dart' hide Skip;
import 'package:flutter_aircon_remote/application/add_device_wizard.dart';
import 'package:flutter_aircon_remote/application/add_device_wizard_controller.dart';
import 'package:flutter_aircon_remote/application/device_list_controller.dart';
import 'package:flutter_aircon_remote/infrastructure/ir/fake_ir_transmitter.dart';
import 'package:flutter_aircon_remote/infrastructure/ir/ir_transmitter.dart';

import '../support/pump_app.dart';
import '../support/in_memory_device_repository.dart';

void main() {
  late InMemoryDeviceRepository repo;
  late DeviceListController ds;
  late FakeIrTransmitter ir;
  late AddDeviceWizardController c;
  setUp(() async {
    repo = InMemoryDeviceRepository();
    ds = DeviceListController(registry: testRegistry(), repository: repo);
    await ds.init();
    ir = FakeIrTransmitter();
    c = AddDeviceWizardController(
      registry: ds.registry,
      transmitter: ir,
      devices: ds,
    );
    await c.init();
  });
  tearDown(() {
    c.dispose();
    ds.dispose();
  });
  Future<void> advance() async {
    for (final e in [
      const Next(),
      const SetName('主卧'),
      const Next(),
      const Next(),
      const StartPairing(),
    ]) {
      await c.dispatch(e);
    }
  }

  test(
    'probes each variant; zero writes before Complete; confirmed initial state',
    () async {
      await advance();
      for (var i = 0; i < 3; i++) {
        expect(
          ir.sent[i].debugHex,
          ds.registry.all[i].encode(ds.registry.all[i].pairingProbe).debugHex,
        );
        expect(repo.writes, 0);
        expect(ds.devices, isEmpty);
        if (i < 2) await c.dispatch(const AnswerNo());
      }
      final done = c.completed.first;
      await c.dispatch(const AnswerYes());
      expect((await done).protocolId, 'gree.yx1fsf');
      expect(ds.devices.single.pairingConfirmed, true);
      expect(ds.devices.single.state.power, true);
      expect(repo.writes, 2);
    },
  );
  test('repair has no persistence and skip default is off', () async {
    await c.dispatch(const Next());
    await c.dispatch(const SetName('书房'));
    await c.dispatch(const Next());
    await c.dispatch(const Next());
    await c.dispatch(const Skip());
    expect(ds.devices.single.state.power, false);
    final repair = AddDeviceWizardController(
      registry: ds.registry,
      transmitter: ir,
      devices: ds,
      repairing: ds.devices.single,
    );
    addTearDown(repair.dispose);
    await repair.init();
    final writes = repo.writes;
    await repair.dispatch(const StartPairing());
    await repair.dispatch(const AnswerYes());
    expect(repo.writes, writes);
  });
  test('transmit exception becomes sendFailed', () async {
    ir.failure = const IrTransmitException(IrErrorCode.transmitFailed, 'test');
    await advance();
    expect(c.state.phase, PairingPhase.sendFailed);
    expect(repo.writes, 0);
  });
  test('cancel during probe ignores completion and does not save', () async {
    ir.delay = const Duration(milliseconds: 10);
    for (final e in [
      const Next(),
      const SetName('书房'),
      const Next(),
      const Next(),
    ]) {
      await c.dispatch(e);
    }
    final pending = c.dispatch(const StartPairing());
    await c.dispatch(const Back());
    await pending;
    expect(c.state.step, WizardStep.brand);
    expect(repo.writes, 0);
  });
  test('rejected add restores editable state and allows retry', () async {
    await advance();
    final before = c.state;
    for (var i = 0; i < DeviceListController.maxDevices; i++) {
      await ds.add(
        name: '空调$i',
        protocolId: 'gree.yaw1f',
        initialState: ds.registry.fallback.defaultState,
      );
    }
    await c.dispatch(const AnswerYes());
    expect(c.state, before);
    expect(c.state.outcome, isNull);
    await ds.remove(ds.devices.last.id);
    final done = c.completed.first;
    await c.dispatch(const AnswerYes());
    expect((await done).pairingConfirmed, true);
  });
}
