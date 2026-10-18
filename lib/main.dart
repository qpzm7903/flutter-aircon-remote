import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/constants.dart';
import 'application/remote_controller.dart';
import 'application/theme_controller.dart';
import 'infrastructure/ir/fake_ir_transmitter.dart';
import 'infrastructure/ir/method_channel_ir_transmitter.dart';
import 'infrastructure/logging/log_service.dart';
import 'infrastructure/persistence/shared_prefs_remote_repository.dart';
import 'protocol/protocol_registry.dart';
import 'protocol/gree/gree_protocol.dart';
import 'protocol/gree/gree_state_codec.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LogService.init();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    LogService.error('Flutter error', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    LogService.error('Unhandled error', error, stack);
    return true;
  };
  LogService.info('${AppConstants.appName} ${AppConstants.version}');
  final repository = SharedPrefsRemoteRepository(
    await SharedPreferences.getInstance(),
  );
  final remote = RemoteController(
    registry: AcProtocolRegistry([
      GreeProtocol(GreeModel.yaw1f),
      GreeProtocol(GreeModel.ybofb),
    ]),
    transmitter: const bool.fromEnvironment('FAKE_IR')
        ? FakeIrTransmitter()
        : const MethodChannelIrTransmitter(),
    repository: repository,
  );
  final theme = ThemeController(repository);
  runApp(AircondRemoteApp(remoteController: remote, themeController: theme));
  await Future.wait([remote.init(), theme.init()]);
}
