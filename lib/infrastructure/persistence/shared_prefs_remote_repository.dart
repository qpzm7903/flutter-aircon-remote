import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import 'remote_repository.dart';

class SharedPrefsRemoteRepository implements RemoteRepository {
  SharedPrefsRemoteRepository(this.prefs);
  final SharedPreferences prefs;
  @override
  Future<PersistedRemote> load() async {
    final theme = prefs.get(AppConstants.themeKey);
    return PersistedRemote(
      themeModeName: ['system', 'light', 'dark'].contains(theme)
          ? theme as String
          : null,
    );
  }

  @override
  Future<void> saveThemeModeName(String name) async {
    if (!await prefs.setString(AppConstants.themeKey, name)) {
      throw StateError('Theme write failed');
    }
  }
}
