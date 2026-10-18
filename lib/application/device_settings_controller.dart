import 'package:flutter/foundation.dart';

import '../domain/ac_device.dart';
import '../domain/ac_enums.dart';
import '../domain/ac_capabilities.dart';
import '../domain/capability_overrides.dart';
import '../protocol/protocol_registry.dart';
import 'device_list_controller.dart';

final class ProtocolOption {
  const ProtocolOption(this.id, this.brandName, this.modelName, this.note);
  final String id, brandName, modelName, note;
}

class DeviceSettingsController extends ChangeNotifier {
  DeviceSettingsController({
    required this.deviceId,
    required this.devices,
    required this.registry,
  }) {
    draft = devices.byId(deviceId)!;
    _original = draft;
  }
  final String deviceId;
  final DeviceListController devices;
  final AcProtocolRegistry registry;
  late AcDevice draft, _original;
  bool get hasChanges => draft != _original;
  String? get nameError => AcDevice.validateName(draft.name);
  bool lastRejected = false;
  List<ProtocolOption> get protocolOptions => registry
      .modelsOf((registry.byId(draft.protocolId) ?? registry.fallback).brandId)
      .map((p) => ProtocolOption(p.id, p.brandName, p.modelName, p.modelNote))
      .toList();
  AcCapabilities get protocolCapabilities =>
      (registry.byId(draft.protocolId) ?? registry.fallback).capabilities;
  AcCapabilities get effectiveCapabilities =>
      protocolCapabilities.restrictedBy(draft.overrides);
  void _set(AcDevice d) {
    draft = d;
    notifyListeners();
  }

  void setName(String v) => _set(draft.copyWith(name: v));
  void setRoom(String v) => _set(draft.copyWith(room: v));
  void setIcon(AcIcon v) => _set(draft.copyWith(icon: v));
  void setProtocol(String id) {
    if (registry.byId(id) != null) _set(draft.copyWith(protocolId: id));
  }

  // Keep the confirmation when repair retains the original protocol.
  void setPairing(String id, bool confirmed) {
    if (registry.byId(id) != null) {
      _set(
        draft.copyWith(
          protocolId: id,
          pairingConfirmed:
              confirmed ||
              (id == _original.protocolId && draft.pairingConfirmed),
        ),
      );
    }
  }

  Set<T> _visibility<T>(Set<T> hidden, T item, bool visible) =>
      visible ? ({...hidden}..remove(item)) : {...hidden, item};
  void _over(CapabilityOverrides o) => _set(draft.copyWith(overrides: o));
  void setModeVisible(AcMode m, bool v) {
    final set = _visibility(draft.overrides.hiddenModes, m, v);
    lastRejected = protocolCapabilities.modes.every(set.contains);
    if (!lastRejected) {
      _over(draft.overrides.copyWith(hiddenModes: set));
    } else {
      notifyListeners();
    }
  }

  void setFanSpeedVisible(FanSpeed f, bool v) {
    final set = _visibility(draft.overrides.hiddenFanSpeeds, f, v);
    lastRejected = protocolCapabilities.fanSpeeds.every(set.contains);
    if (!lastRejected) {
      _over(draft.overrides.copyWith(hiddenFanSpeeds: set));
    } else {
      notifyListeners();
    }
  }

  void setFeatureVisible(AcFeature f, bool v) => _over(
    draft.overrides.copyWith(
      hiddenFeatures: _visibility(draft.overrides.hiddenFeatures, f, v),
    ),
  );
  void setSwingVisible(VerticalSwing s, bool v) {
    if (s != VerticalSwing.off) {
      _over(
        draft.overrides.copyWith(
          hiddenSwings: _visibility(draft.overrides.hiddenSwings, s, v),
        ),
      );
    }
  }

  void setAllSwingVisible(bool v) => _over(
    draft.overrides.copyWith(
      hiddenSwings: v
          ? {}
          : protocolCapabilities.verticalSwings
                .where((s) => s != VerticalSwing.off)
                .toSet(),
    ),
  );
  void setTempRange(int? min, int? max) => _over(
    CapabilityOverrides(
      hiddenFeatures: draft.overrides.hiddenFeatures,
      hiddenModes: draft.overrides.hiddenModes,
      hiddenFanSpeeds: draft.overrides.hiddenFanSpeeds,
      hiddenSwings: draft.overrides.hiddenSwings,
      minTempC: min,
      maxTempC: max,
    ),
  );
  Future<bool> save() async {
    if (nameError != null || (draft.room?.runes.length ?? 0) > 20) return false;
    await devices.update(draft);
    draft = devices.byId(deviceId)!;
    _original = draft;
    notifyListeners();
    return true;
  }

  Future<void> delete() => devices.remove(deviceId);
}
