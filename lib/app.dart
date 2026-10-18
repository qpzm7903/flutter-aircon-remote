import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'application/device_list_controller.dart';
import 'application/remote_session_factory.dart';
import 'application/diagnostics_controller.dart';
import 'application/theme_controller.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/strings.dart';

class AircondRemoteApp extends StatelessWidget {
  const AircondRemoteApp({
    required this.devices,
    required this.sessions,
    required this.diagnostics,
    required this.themeController,
    super.key,
  });
  final DeviceListController devices;
  final RemoteSessionFactory sessions;
  final DiagnosticsController diagnostics;
  final ThemeController themeController;
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: devices),
      Provider.value(value: sessions),
      Provider.value(value: diagnostics),
      ChangeNotifierProvider.value(value: themeController),
    ],
    child: Consumer<ThemeController>(
      builder: (context, controller, child) => MaterialApp(
        title: Strings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: switch (controller.modeName) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        },
        home: const HomePage(),
      ),
    ),
  );
}
