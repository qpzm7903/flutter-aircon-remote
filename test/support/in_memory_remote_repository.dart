import 'package:flutter_aircon_remote/domain/ac_state.dart';
import 'package:flutter_aircon_remote/infrastructure/persistence/remote_repository.dart';

class InMemoryRemoteRepository implements RemoteRepository {
  String? id, theme;
  bool fail = false;
  final Map<String, AcState> states = {};
  @override
  Future<PersistedRemote> load() async {
    if (fail) {
      throw StateError('Corrupt storage');
    }
    return PersistedRemote(
      protocolId: id,
      states: Map.of(states),
      themeModeName: theme,
    );
  }

  @override
  Future<void> saveState(String protocolId, AcState state) async {
    if (fail) {
      throw StateError('Storage failed');
    }
    states[protocolId] = state;
  }

  @override
  Future<void> saveProtocolId(String protocolId) async {
    id = protocolId;
  }

  @override
  Future<void> saveThemeModeName(String name) async {
    theme = name;
  }
}
