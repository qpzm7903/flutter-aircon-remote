class PersistedRemote {
  const PersistedRemote({this.themeModeName});
  final String? themeModeName;
}

abstract interface class RemoteRepository {
  Future<PersistedRemote> load();
  Future<void> saveThemeModeName(String name);
}
