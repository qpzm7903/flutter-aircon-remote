import 'package:flutter_aircon_remote/infrastructure/persistence/remote_repository.dart';

class InMemoryRemoteRepository implements RemoteRepository {
  String? theme;
  bool fail = false;
  @override
  Future<PersistedRemote> load() async {
    if (fail) throw StateError('Storage failed');
    return PersistedRemote(themeModeName: theme);
  }

  @override
  Future<void> saveThemeModeName(String name) async {
    if (fail) throw StateError('Storage failed');
    theme = name;
  }
}
