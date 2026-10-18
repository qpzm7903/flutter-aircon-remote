import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../domain/ac_state.dart';
import '../logging/log_service.dart';
import 'remote_repository.dart';

class SharedPrefsRemoteRepository implements RemoteRepository {
  SharedPrefsRemoteRepository(this.prefs);
  final SharedPreferences prefs;
  @override
  Future<PersistedRemote> load() async {
    String? readString(String key) {
      final value = prefs.get(key);
      if (value is String) {
        return value;
      }
      if (value != null) {
        LogService.warning('Invalid preference: $key');
      }
      return null;
    }

    final states = <String, AcState>{};
    for (final key in prefs.getKeys().where(
      (k) => k.startsWith(AppConstants.statePrefix),
    )) {
      try {
        final json = jsonDecode(readString(key) ?? '') as Map<String, dynamic>;
        final state = AcState.fromJson(json);
        if (jsonEncode(json) != jsonEncode(state.toJson())) {
          LogService.warning('Recovered state fields: $key');
        }
        states[key.substring(AppConstants.statePrefix.length)] = state;
      } catch (e) {
        LogService.warning('Corrupt state: $key', e);
      }
    }
    final theme = readString(AppConstants.themeKey);
    return PersistedRemote(
      protocolId: readString(AppConstants.protocolKey),
      states: states,
      themeModeName: ['system', 'light', 'dark'].contains(theme) ? theme : null,
    );
  }

  Future<void> _save(String key, String value) async {
    if (!await prefs.setString(key, value)) {
      throw StateError('Preference write failed: $key');
    }
  }

  @override
  Future<void> saveState(String protocolId, AcState state) => _save(
    '${AppConstants.statePrefix}$protocolId',
    jsonEncode(state.toJson()),
  );
  @override
  Future<void> saveProtocolId(String protocolId) =>
      _save(AppConstants.protocolKey, protocolId);
  @override
  Future<void> saveThemeModeName(String name) =>
      _save(AppConstants.themeKey, name);
}
