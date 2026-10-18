import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../domain/ac_device.dart';
import '../../domain/ac_state.dart';
import '../logging/log_service.dart';

class LegacyV1Migrator {
  LegacyV1Migrator(this.prefs, {required this.fallbackProtocolId});
  final SharedPreferences prefs;
  final String fallbackProtocolId;
  Future<void> migrateIfNeeded() async {
    final schema = prefs.get(AppConstants.schemaVersionKey);
    if (schema is int && schema >= 2) return;
    final raw = prefs.get(AppConstants.protocolKey);
    final id = raw is String ? raw : fallbackProtocolId;
    final keys = prefs.getKeys().where(
      (k) => k.startsWith(AppConstants.statePrefix),
    );
    if (prefs.get(AppConstants.deviceIndexKey) == null &&
        (raw is String || keys.isNotEmpty)) {
      var state = const AcState.initial();
      for (final key in keys) {
        try {
          final j =
              jsonDecode(prefs.get(key) as String) as Map<String, dynamic>;
          if (key == '${AppConstants.statePrefix}$id') {
            state = AcState.fromJson(j);
          }
        } catch (e) {
          LogService.warning('Corrupt legacy state: $key', e);
        }
      }
      final device = AcDevice(
        id: 'legacy-1',
        name: '我的空调',
        protocolId: id,
        state: state,
      );
      if (!await prefs.setString(
        '${AppConstants.deviceStatePrefix}legacy-1',
        jsonEncode(state.toJson()),
      )) {
        throw StateError('Migration state write failed');
      }
      if (!await prefs.setString(
        AppConstants.deviceIndexKey,
        jsonEncode({
          'v': 2,
          'devices': [device.toMetaJson()],
        }),
      )) {
        throw StateError('Migration index write failed');
      }
    }
    if (!await prefs.setInt(AppConstants.schemaVersionKey, 2)) {
      throw StateError('Migration commit failed');
    }
  }
}
