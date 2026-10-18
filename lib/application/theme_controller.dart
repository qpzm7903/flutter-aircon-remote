import 'package:flutter/foundation.dart';

import '../infrastructure/persistence/remote_repository.dart';
import '../infrastructure/logging/log_service.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this.repository);
  final RemoteRepository repository;
  String _modeName = 'system';
  String get modeName => _modeName;
  Future<void> init() async {
    try {
      final name = (await repository.load()).themeModeName;
      if (['system', 'light', 'dark'].contains(name)) {
        _modeName = name!;
      }
    } catch (e) {
      LogService.warning('Theme load failed', e);
    }
    notifyListeners();
  }

  Future<void> cycle() async {
    _modeName = switch (_modeName) {
      'system' => 'light',
      'light' => 'dark',
      _ => 'system',
    };
    notifyListeners();
    try {
      await repository.saveThemeModeName(_modeName);
    } catch (e) {
      LogService.warning('Theme save failed', e);
    }
  }
}
