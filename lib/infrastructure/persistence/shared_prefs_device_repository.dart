import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../domain/ac_device.dart';
import '../../domain/ac_state.dart';
import '../logging/log_service.dart';
import 'device_repository.dart';
import 'legacy_v1_migrator.dart';

class SharedPrefsDeviceRepository implements DeviceRepository {
  SharedPrefsDeviceRepository(this.prefs, {required this.fallbackProtocolId});
  final SharedPreferences prefs;
  final String fallbackProtocolId;
  @override
  Future<List<AcDevice>> load() async {
    try {
      await LegacyV1Migrator(
        prefs,
        fallbackProtocolId: fallbackProtocolId,
      ).migrateIfNeeded();
    } catch (e) {
      LogService.warning('Migration failed', e);
      return [];
    }
    final raw = prefs.get(AppConstants.deviceIndexKey);
    if (raw == null) return [];
    List<dynamic> entries;
    try {
      entries =
          (jsonDecode(raw as String) as Map<String, dynamic>)['devices']
              as List<dynamic>;
    } catch (e) {
      LogService.warning('Corrupt device index', e);
      try {
        await prefs.setString(AppConstants.corruptIndexKey, raw.toString());
      } catch (error) {
        LogService.warning('Corrupt index backup failed', error);
      }
      return [];
    }
    final result = <AcDevice>[];
    final ids = <String>{};
    for (final entry in entries) {
      if (entry is! Map<String, dynamic> ||
          entry['id'] is! String ||
          (entry['id'] as String).isEmpty ||
          !ids.add(entry['id'] as String)) {
        continue;
      }
      var state = const AcState.initial();
      final rawState = prefs.get(
        '${AppConstants.deviceStatePrefix}${entry['id']}',
      );
      if (rawState != null) {
        try {
          state = AcState.fromJson(
            jsonDecode(rawState as String) as Map<String, dynamic>,
          );
        } catch (e) {
          LogService.warning('Corrupt device state', e);
        }
      }
      result.add(AcDevice.fromMetaJson(entry, state: state));
    }
    final indexed = result.indexed.toList()
      ..sort((a, b) {
        final order = a.$2.sortOrder.compareTo(b.$2.sortOrder);
        return order == 0 ? a.$1.compareTo(b.$1) : order;
      });
    return indexed.map((v) => v.$2).toList();
  }

  Future<void> _write(String key, String value) async {
    if (!await prefs.setString(key, value)) {
      throw StateError('Preference write failed: $key');
    }
  }

  @override
  Future<void> saveDevices(List<AcDevice> devices) => _write(
    AppConstants.deviceIndexKey,
    jsonEncode({
      'v': 2,
      'devices': [
        for (var i = 0; i < devices.length; i++)
          devices[i].copyWith(sortOrder: i).toMetaJson(),
      ],
    }),
  );
  @override
  Future<void> saveState(String deviceId, AcState state) => _write(
    '${AppConstants.deviceStatePrefix}$deviceId',
    jsonEncode(state.toJson()),
  );
  @override
  Future<void> deleteState(String deviceId) async {
    if (!await prefs.remove('${AppConstants.deviceStatePrefix}$deviceId')) {
      throw StateError('State deletion failed');
    }
  }
}
