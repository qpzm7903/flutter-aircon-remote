import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_aircon_remote/app.dart';
import 'package:flutter_aircon_remote/application/remote_controller.dart';
import 'package:flutter_aircon_remote/application/device_list_controller.dart';
import 'package:flutter_aircon_remote/application/remote_session_factory.dart';
import 'package:flutter_aircon_remote/application/diagnostics_controller.dart';
import 'package:flutter_aircon_remote/application/theme_controller.dart';
import 'package:flutter_aircon_remote/domain/ac_device.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';
import 'package:flutter_aircon_remote/domain/capability_overrides.dart';
import 'package:flutter_aircon_remote/infrastructure/ir/fake_ir_transmitter.dart';
import 'package:flutter_aircon_remote/protocol/protocol_registry.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_protocol.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_state_codec.dart';
import 'package:flutter_aircon_remote/presentation/pages/remote_page.dart';

import 'in_memory_remote_repository.dart';
import 'in_memory_device_repository.dart';

AcProtocolRegistry testRegistry() =>
    AcProtocolRegistry([for (final m in GreeModel.values) GreeProtocol(m)]);
AcDevice testDevice({
  String id = 'd1',
  String name = '主卧',
  String protocolId = 'gree.yaw1f',
  CapabilityOverrides overrides = CapabilityOverrides.none,
}) => AcDevice(
  id: id,
  name: name,
  room: '二楼',
  protocolId: protocolId,
  state: const AcState.initial(),
  overrides: overrides,
);
Future<(DeviceListController, FakeIrTransmitter)> pumpHome(
  WidgetTester tester, {
  bool empty = false,
  bool hasEmitter = true,
  List<AcDevice>? initial,
}) async {
  final repo = InMemoryDeviceRepository()
    ..devices = initial ?? (empty ? [] : [testDevice()]);
  final registry = testRegistry();
  final devices = DeviceListController(registry: registry, repository: repo);
  final ir = FakeIrTransmitter(hasEmitter: hasEmitter);
  final theme = ThemeController(InMemoryRemoteRepository());
  await devices.init();
  await theme.init();
  await tester.pumpWidget(
    AircondRemoteApp(
      devices: devices,
      sessions: RemoteSessionFactory(
        registry: registry,
        transmitter: ir,
        devices: devices,
      ),
      diagnostics: DiagnosticsController(),
      themeController: theme,
    ),
  );
  addTearDown(() {
    devices.dispose();
    theme.dispose();
  });
  return (devices, ir);
}

Future<(RemoteController, FakeIrTransmitter)> pumpApp(
  WidgetTester tester, {
  bool hasEmitter = true,
  AcDevice? device,
}) async {
  final (devices, ir) = await pumpHome(
    tester,
    hasEmitter: hasEmitter,
    initial: [device ?? testDevice()],
  );
  final context = tester.element(find.text((device ?? testDevice()).name));
  final factory = context.read<RemoteSessionFactory>();
  final c = factory.create(devices.devices.first.id);
  await c.init();
  if (context.mounted) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            ChangeNotifierProvider.value(value: c, child: const RemotePage()),
      ),
    );
  }
  await tester.pumpAndSettle();
  addTearDown(c.dispose);
  return (c, ir);
}
