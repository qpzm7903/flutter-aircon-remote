import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'application/remote_controller.dart';
import 'application/theme_controller.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/pages/remote_page.dart';
import 'presentation/strings.dart';

class AircondRemoteApp extends StatelessWidget {
  const AircondRemoteApp({
    required this.remoteController,
    required this.themeController,
    super.key,
  });
  final RemoteController remoteController;
  final ThemeController themeController;
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: remoteController),
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
        home: const RemotePage(),
      ),
    ),
  );
}
