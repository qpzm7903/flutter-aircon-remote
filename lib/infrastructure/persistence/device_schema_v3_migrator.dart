import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../logging/log_service.dart';

class DeviceSchemaV3Migrator {
  DeviceSchemaV3Migrator(this.prefs);
  final SharedPreferences prefs;
  Future<void> migrateIfNeeded() async {
    final schema = prefs.get(AppConstants.schemaVersionKey);
    if (schema is int && schema >= 3) return;
    final raw = prefs.get(AppConstants.deviceIndexKey);
    Map<String, dynamic>? index;
    if (raw != null) {
      try {
        index = jsonDecode(raw as String) as Map<String, dynamic>;
        if (index['devices'] is! List) throw const FormatException('devices');
      } catch (e) {
        LogService.warning('Corrupt v2 device index', e);
        return;
      }
      if (index['v'] is! int || index['v'] < 3) {
        for (final entry in index['devices'] as List) {
          if (entry is! Map) continue;
          final overrides = entry['overrides'] is Map
              ? Map<String, dynamic>.from(entry['overrides'] as Map)
              : <String, dynamic>{};
          void merge(String key, List<String> seed) {
            overrides[key] = {
              ...(overrides[key] is List ? overrides[key] as List : []),
              ...seed,
            }.toList();
          }

          merge('hiddenFeatures', ['swingH', 'wifi', 'timer', 'fahrenheit']);
          merge('hiddenSwings', ['autoDown', 'autoMiddle', 'autoUp']);
          overrides.putIfAbsent('hiddenHSwings', () => <String>[]);
          entry['overrides'] = overrides;
        }
        index['v'] = 3;
        if (!await prefs.setString(
          AppConstants.deviceIndexKey,
          jsonEncode(index),
        )) {
          await prefs.reload();
          throw StateError('v3 index write failed');
        }
      }
    }
    if (!await prefs.setInt(AppConstants.schemaVersionKey, 3)) {
      await prefs.reload();
      throw StateError('v3 commit failed');
    }
  }
}
