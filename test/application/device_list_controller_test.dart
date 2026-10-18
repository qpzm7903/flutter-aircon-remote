import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/application/device_list_controller.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';
import 'package:flutter_aircon_remote/domain/ac_enums.dart';
import 'package:flutter_aircon_remote/domain/capability_overrides.dart';

import '../support/pump_app.dart';
import '../support/in_memory_device_repository.dart';

void main() {
  late InMemoryDeviceRepository repo;
  late DeviceListController c;
  var id = 0;
  setUp(() {
    repo = InMemoryDeviceRepository();
    c = DeviceListController(
      registry: testRegistry(),
      repository: repo,
      idGenerator: () => 'd${id++}',
    );
  });
  tearDown(() => c.dispose());
  test('init unknown protocol falls back and normalizes', () async {
    repo.devices = [testDevice(protocolId: 'bad')];
    await c.init();
    expect(c.loaded, true);
    expect(c.devices.single.protocolId, 'gree.yaw1f');
    expect(c.warnings, isNotEmpty);
  });
  test('add trims, validates and caps at 20', () async {
    await c.init();
    expect(
      await c.add(
        name: ' ',
        protocolId: 'gree.yaw1f',
        initialState: const AcState.initial(),
      ),
      null,
    );
    for (var i = 0; i < 20; i++) {
      expect(
        await c.add(
          name: ' 卧室 ',
          room: ' ',
          protocolId: 'gree.yaw1f',
          initialState: const AcState.initial(),
        ),
        isNotNull,
      );
    }
    expect(c.devices.first.name, '卧室');
    expect(c.devices.first.room, null);
    expect(c.isFull, true);
    expect(
      await c.add(
        name: '21',
        protocolId: 'gree.yaw1f',
        initialState: const AcState.initial(),
      ),
      null,
    );
  });
  test('update normalizes; remove cleans; reorder semantics', () async {
    repo.devices = [
      testDevice(id: 'a'),
      testDevice(id: 'b'),
      testDevice(id: 'c'),
    ];
    await c.init();
    await c.reorder(0, 3);
    expect(c.devices.map((d) => d.id), ['b', 'c', 'a']);
    expect(c.devices.map((d) => d.sortOrder), [0, 1, 2]);
    await c.reorder(2, 0);
    expect(repo.devices.map((d) => d.id), ['a', 'b', 'c']);
    await c.update(
      c
          .byId('a')!
          .copyWith(
            overrides: const CapabilityOverrides(
              hiddenModes: {AcMode.cool},
              maxTempC: 24,
            ),
          ),
    );
    expect(c.byId('a')!.state.mode, AcMode.auto);
    expect(repo.states['a']!.targetTempC, 25);
    await c.remove('a');
    expect(c.byId('a'), null);
    expect(repo.states.containsKey('a'), false);
  });
  test('saveState does not notify and write failure keeps memory', () async {
    repo.devices = [testDevice()];
    await c.init();
    var count = 0;
    c.addListener(() => count++);
    c.saveState('d1', const AcState.initial().copyWith(power: true));
    await Future<void>.delayed(Duration.zero);
    expect(count, 0);
    expect(repo.states['d1']!.power, true);
    repo.fail = true;
    await c.update(c.devices.single.copyWith(name: '新名'));
    expect(c.devices.single.name, '新名');
    expect(c.warnings, isNotEmpty);
  });
  test('update validates room length after trimming', () async {
    repo.devices = [testDevice()];
    await c.init();
    final room = List.filled(20, '房').join();
    await c.update(c.devices.single.copyWith(room: ' $room '));
    expect(c.devices.single.room?.trim(), room);
    await c.update(c.devices.single.copyWith(room: '$room房'));
    expect(c.devices.single.room?.trim(), room);
  });
}
