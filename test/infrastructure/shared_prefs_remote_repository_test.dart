import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_aircon_remote/infrastructure/persistence/shared_prefs_remote_repository.dart';

void main() {
  test('only theme persists; invalid theme defaults', () async {
    SharedPreferences.setMockInitialValues({
      'ui.themeMode': 42,
      'remote.protocolId': 'old',
    });
    final p = await SharedPreferences.getInstance();
    final r = SharedPrefsRemoteRepository(p);
    expect((await r.load()).themeModeName, null);
    await r.saveThemeModeName('dark');
    expect((await r.load()).themeModeName, 'dark');
    expect(p.getString('remote.protocolId'), 'old');
  });
}
