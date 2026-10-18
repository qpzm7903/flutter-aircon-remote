import '../../domain/ac_state.dart';

class PersistedRemote {
  const PersistedRemote({
    this.protocolId,
    this.states = const {},
    this.themeModeName,
  });
  final String? protocolId;
  final Map<String, AcState> states;
  final String? themeModeName;
}

abstract interface class RemoteRepository {
  Future<PersistedRemote> load();
  Future<void> saveState(String protocolId, AcState state);
  Future<void> saveProtocolId(String protocolId);
  Future<void> saveThemeModeName(String name);
}
