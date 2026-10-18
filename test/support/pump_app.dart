import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/app.dart';
import 'package:flutter_aircon_remote/application/remote_controller.dart';
import 'package:flutter_aircon_remote/application/theme_controller.dart';
import 'package:flutter_aircon_remote/infrastructure/ir/fake_ir_transmitter.dart';
import 'package:flutter_aircon_remote/protocol/protocol_registry.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_protocol.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_state_codec.dart';

import 'in_memory_remote_repository.dart';

Future<(RemoteController, FakeIrTransmitter)> pumpApp(
  WidgetTester tester, {
  bool hasEmitter = true,
}) async {
  final repo = InMemoryRemoteRepository();
  final ir = FakeIrTransmitter(hasEmitter: hasEmitter);
  final c = RemoteController(
    registry: AcProtocolRegistry([
      GreeProtocol(GreeModel.yaw1f),
      GreeProtocol(GreeModel.ybofb),
    ]),
    transmitter: ir,
    repository: repo,
  );
  final theme = ThemeController(repo);
  await c.init();
  await theme.init();
  await tester.pumpWidget(
    AircondRemoteApp(remoteController: c, themeController: theme),
  );
  addTearDown(() {
    c.dispose();
    theme.dispose();
  });
  return (c, ir);
}
