import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/application/remote_controller.dart';
import 'package:flutter_aircon_remote/application/remote_event.dart';
import 'package:flutter_aircon_remote/application/device_list_controller.dart';
import 'package:flutter_aircon_remote/application/theme_controller.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';
import 'package:flutter_aircon_remote/domain/ac_enums.dart';
import 'package:flutter_aircon_remote/domain/capability_overrides.dart';
import 'package:flutter_aircon_remote/infrastructure/ir/fake_ir_transmitter.dart';
import 'package:flutter_aircon_remote/infrastructure/ir/ir_transmitter.dart';

import '../support/in_memory_device_repository.dart';
import '../support/in_memory_remote_repository.dart';
import '../support/pump_app.dart';
import '../support/gree_vectors.dart';

void main() {
  late InMemoryDeviceRepository repo;
  late DeviceListController devices;
  late RemoteController c;
  late FakeIrTransmitter ir;
  setUp(() async {
    repo = InMemoryDeviceRepository()
      ..devices = [
        testDevice(),
        testDevice(id: 'd2', protocolId: 'gree.ybofb'),
      ];
    devices = DeviceListController(registry: testRegistry(), repository: repo);
    await devices.init();
    ir = FakeIrTransmitter();
    c = RemoteController(
      deviceId: 'd1',
      registry: devices.registry,
      transmitter: ir,
      devices: devices,
    );
  });
  test(
    'v3 horizontal, Fahrenheit units/steps, cycling and one-shot WiFi',
    () async {
      await c.init();
      await c.setHorizontalSwing(HorizontalSwing.maxRight);
      expect(ir.sent.last.debugHex.split(' ')[4], '60');
      await c.setUseFahrenheit(true);
      expect(c.state.targetTempF, 79);
      await c.stepTemp(1);
      expect(c.state.targetTempF, 80);
      await c.setUseFahrenheit(false);
      expect(c.state.targetTempC, 27);
      for (final d in [
        TempDisplay.setpoint,
        TempDisplay.indoor,
        TempDisplay.outdoor,
        TempDisplay.off,
      ]) {
        await c.cycleTempDisplay();
        expect(c.state.tempDisplay, d);
      }
      ir.delay = const Duration(milliseconds: 10);
      final count = ir.sent.length;
      await Future.wait([c.pressWifi(), c.pressWifi(), c.stepTemp(1)]);
      final frames = ir.sent
          .skip(count)
          .map((f) => int.parse(f.debugHex.split(' ')[5], radix: 16))
          .toList();
      expect(frames.where((b) => b & 64 != 0).length, 1);
      expect(c.state.wifiPulse, false);
      await c.stepTemp(1);
      expect(int.parse(ir.sent.last.debugHex.split(' ')[5], radix: 16) & 64, 0);
    },
  );
  test(
    'injected clock timer folding, expiry on init and hidden neutralization',
    () async {
      c.dispose();
      var now = 100000;
      c = RemoteController(
        deviceId: 'd1',
        registry: devices.registry,
        transmitter: ir,
        devices: devices,
        nowMs: () => now,
      );
      await c.init();
      await c.setTimer(90);
      expect(c.state.timerSetAtMs, now);
      now += 31 * 60000;
      await c.stepTemp(1);
      expect(c.state.timerMinutes, 60);
      expect(c.state.timerSetAtMs, now);
      now += 61 * 60000;
      final count = ir.sent.length;
      await c.init();
      expect(c.state.timerMinutes, 0);
      expect(ir.sent.length, count);
      await c.setHorizontalSwing(HorizontalSwing.left);
      await c.setTimer(60);
      await c.setUseFahrenheit(true);
      final before = ir.sent.length;
      await devices.update(
        devices
            .byId('d1')!
            .copyWith(
              overrides: const CapabilityOverrides(
                hiddenFeatures: {
                  AcFeature.swingH,
                  AcFeature.timer,
                  AcFeature.fahrenheit,
                },
              ),
            ),
      );
      expect(c.state.horizontalSwing, HorizontalSwing.off);
      expect(c.state.timerMinutes, 0);
      expect(c.state.targetTempF, null);
      expect(ir.sent.length, before);
      await c.stepTemp(1);
      expect(ir.sent.last.debugHex.split(' ')[4], '00');
    },
  );
  test('second WiFi press during transmission is ignored', () async {
    await c.init();
    ir.delay = const Duration(milliseconds: 20);
    final first = c.pressWifi();
    expect(c.state.wifiPulse, true);
    expect(ir.active, 1);
    await c.pressWifi();
    await first;
    expect(ir.sent, hasLength(1));
    expect(c.state.wifiPulse, false);
  });
  test(
    'override changes during WiFi never cache or restore the pulse',
    () async {
      await c.init();
      ir.delay = const Duration(milliseconds: 20);
      final first = c.pressWifi();
      expect(c.state.wifiPulse, true);
      await devices.update(
        c.device.copyWith(overrides: const CapabilityOverrides(maxTempC: 28)),
      );
      expect(devices.byId('d1')!.state.wifiPulse, false);
      await first;
      expect(repo.states['d1']!.wifiPulse, false);
      await c.init();
      expect(c.state.wifiPulse, false);
      expect(ir.sent, hasLength(1));
    },
  );
  test('failed WiFi is cleared without retry', () async {
    await c.init();
    ir.failure = const IrTransmitException(
      IrErrorCode.transmitFailed,
      'failed',
    );
    await c.pressWifi();
    expect(c.state.wifiPulse, false);
    expect(devices.byId('d1')!.state.wifiPulse, false);
    await c.init();
    expect(c.state.wifiPulse, false);
    ir.failure = null;
    await c.stepTemp(1);
    expect(int.parse(ir.sent.last.debugHex.split(' ')[5], radix: 16) & 64, 0);
  });
  tearDown(() {
    c.dispose();
    devices.dispose();
  });
  test('init normalizes and never sends', () async {
    await devices.update(
      devices
          .byId('d1')!
          .copyWith(overrides: const CapabilityOverrides(maxTempC: 24)),
    );
    await c.init();
    expect(c.state.targetTempC, 24);
    expect(ir.sent, isEmpty);
  });
  test('known reference frame persists per device', () async {
    await c.init();
    await c.update((_) => greeVectors[1].state);
    await Future<void>.delayed(Duration.zero);
    expect(ir.sent.single.debugHex, '19 0A 60 50 02 23 00 F0');
    expect(repo.states['d1'], c.state);
  });
  test('devices isolate state and protocol', () async {
    final other = RemoteController(
      deviceId: 'd2',
      registry: devices.registry,
      transmitter: ir,
      devices: devices,
    );
    addTearDown(other.dispose);
    await c.init();
    await other.init();
    await c.stepTemp(1);
    expect(other.state.targetTempC, 26);
    expect(other.protocol.id, 'gree.ybofb');
    await other.togglePower();
    expect(c.state.power, false);
  });
  test('burst merges latest and serializes transmission', () async {
    await c.init();
    ir.delay = const Duration(milliseconds: 10);
    await Future.wait([
      c.stepTemp(1),
      c.stepTemp(1),
      c.stepTemp(1),
      c.stepTemp(1),
    ]);
    expect(ir.maxActive, 1);
    expect(ir.sent.length, 2);
    expect(c.state.targetTempC, 30);
    expect(ir.sent.last.debugHex, c.protocol.encode(c.state).debugHex);
    expect(c.isSending, false);
  });
  test('failure retains state and emits event', () async {
    await c.init();
    ir.failure = const IrTransmitException(
      IrErrorCode.permissionDenied,
      'denied',
    );
    final event = c.events.first;
    await c.togglePower();
    expect(await event, isA<TransmitFailed>());
    expect(c.state.power, true);
  });
  test('success, unchanged, unavailable', () async {
    await c.init();
    final event = c.events.first;
    await c.togglePower();
    expect(await event, isA<TransmitSucceeded>());
    await c.update((s) => s);
    ir.hasEmitter = false;
    await c.recheckIr();
    await c.togglePower();
    expect(ir.sent.length, 1);
    expect(c.state.power, true);
  });
  test(
    'hidden light stays on and turbo off in frame; settings never send',
    () async {
      await c.init();
      await devices.update(
        c.device.copyWith(
          overrides: const CapabilityOverrides(
            hiddenFeatures: {AcFeature.light, AcFeature.turbo},
          ),
        ),
      );
      expect(ir.sent, isEmpty);
      await c.update((s) => s.copyWith(power: true, light: false, turbo: true));
      final byte = int.parse(ir.sent.single.debugHex.split(' ')[2], radix: 16);
      expect(byte & 32, 32);
      expect(byte & 16, 0);
    },
  );
  test('hidden current mode normalizes and persists without send', () async {
    await c.init();
    await devices.update(
      c.device.copyWith(
        overrides: const CapabilityOverrides(hiddenModes: {AcMode.cool}),
      ),
    );
    expect(c.state.mode, AcMode.auto);
    expect(repo.states['d1'], c.state);
    expect(ir.sent, isEmpty);
  });
  test('protocol change clears pending without sending', () async {
    await c.init();
    ir.delay = const Duration(milliseconds: 10);
    final first = c.stepTemp(1);
    final pending = c.stepTemp(1);
    await devices.update(c.device.copyWith(protocolId: 'gree.ybofb'));
    await Future.wait([first, pending]);
    expect(ir.sent.length, 1);
    expect(c.protocol.id, 'gree.ybofb');
  });
  test('removed device emits and cancels pending', () async {
    await c.init();
    final event = c.events.first;
    await devices.remove('d1');
    expect(await event, isA<DeviceRemoved>());
  });
  test('failed writes retain optimistic state', () async {
    await c.init();
    repo.fail = true;
    await c.togglePower();
    await Future<void>.delayed(Duration.zero);
    expect(c.state.power, true);
    expect(devices.warnings, isNotEmpty);
  });
  test('theme restores and cycles', () async {
    final repo = InMemoryRemoteRepository();
    final theme = ThemeController(repo);
    addTearDown(theme.dispose);
    await theme.init();
    for (final name in ['light', 'dark', 'system']) {
      await theme.cycle();
      expect(repo.theme, name);
    }
  });
  test('device persistence queue preserves latest state', () async {
    final delayed = _DelayedRepository()..devices = [testDevice()];
    final ds = DeviceListController(
      registry: testRegistry(),
      repository: delayed,
    );
    await ds.init();
    final rc = RemoteController(
      deviceId: 'd1',
      registry: ds.registry,
      transmitter: ir,
      devices: ds,
    );
    await rc.init();
    addTearDown(rc.dispose);
    addTearDown(ds.dispose);
    await Future.wait([rc.stepTemp(1), rc.stepTemp(1), rc.stepTemp(1)]);
    expect(delayed.started.length, 1);
    for (var i = 0; i < 3; i++) {
      delayed.started[i].complete();
      await Future<void>.delayed(Duration.zero);
    }
    expect(delayed.states['d1'], rc.state);
  });
}

class _DelayedRepository extends InMemoryDeviceRepository {
  final started = <Completer<void>>[];
  @override
  Future<void> saveState(String id, AcState state) async {
    final gate = Completer<void>();
    started.add(gate);
    await gate.future;
    await super.saveState(id, state);
  }
}
