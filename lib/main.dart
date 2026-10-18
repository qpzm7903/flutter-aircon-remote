import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/constants.dart';
import 'application/device_list_controller.dart';
import 'application/remote_session_factory.dart';
import 'application/diagnostics_controller.dart';
import 'infrastructure/persistence/shared_prefs_device_repository.dart';
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
  final prefs = await SharedPreferences.getInstance();
  final repository = SharedPrefsRemoteRepository(prefs);
  final registry = AcProtocolRegistry([
    for (final model in GreeModel.values) GreeProtocol(model),
  ]);
  final transmitter = const bool.fromEnvironment('FAKE_IR')
      ? FakeIrTransmitter()
      : const MethodChannelIrTransmitter();
  final devices = DeviceListController(
    registry: registry,
    repository: SharedPrefsDeviceRepository(
      prefs,
      fallbackProtocolId: registry.fallback.id,
    ),
  );
  final theme = ThemeController(repository);
  final sessions = RemoteSessionFactory(
    registry: registry,
    transmitter: transmitter,
    devices: devices,
  );
  runApp(
    AircondRemoteApp(
      devices: devices,
      sessions: sessions,
      diagnostics: DiagnosticsController(),
      themeController: theme,
    ),
  );
  await Future.wait([devices.init(), theme.init()]);
}
