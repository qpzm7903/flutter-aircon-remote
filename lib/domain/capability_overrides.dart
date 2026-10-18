import 'ac_enums.dart';

final class CapabilityOverrides {
  const CapabilityOverrides({
    this.hiddenFeatures = const {},
    this.hiddenModes = const {},
    this.hiddenFanSpeeds = const {},
    this.hiddenSwings = const {},
    this.minTempC,
    this.maxTempC,
  });
  static const none = CapabilityOverrides();
  final Set<AcFeature> hiddenFeatures;
  final Set<AcMode> hiddenModes;
  final Set<FanSpeed> hiddenFanSpeeds;
  final Set<VerticalSwing> hiddenSwings;
  final int? minTempC, maxTempC;
  bool get isEmpty =>
      hiddenFeatures.isEmpty &&
      hiddenModes.isEmpty &&
      hiddenFanSpeeds.isEmpty &&
      hiddenSwings.isEmpty &&
      minTempC == null &&
      maxTempC == null;
  static const _unset = Object();
  CapabilityOverrides copyWith({
    Set<AcFeature>? hiddenFeatures,
    Set<AcMode>? hiddenModes,
    Set<FanSpeed>? hiddenFanSpeeds,
    Set<VerticalSwing>? hiddenSwings,
    Object? minTempC = _unset,
    Object? maxTempC = _unset,
  }) => CapabilityOverrides(
    hiddenFeatures: hiddenFeatures ?? this.hiddenFeatures,
    hiddenModes: hiddenModes ?? this.hiddenModes,
    hiddenFanSpeeds: hiddenFanSpeeds ?? this.hiddenFanSpeeds,
    hiddenSwings: hiddenSwings ?? this.hiddenSwings,
    minTempC: identical(minTempC, _unset) ? this.minTempC : minTempC as int?,
    maxTempC: identical(maxTempC, _unset) ? this.maxTempC : maxTempC as int?,
  );
  Map<String, Object?> toJson() => {
    'hiddenFeatures': hiddenFeatures.map((v) => v.name).toList(),
    'hiddenModes': hiddenModes.map((v) => v.name).toList(),
    'hiddenFanSpeeds': hiddenFanSpeeds.map((v) => v.name).toList(),
    'hiddenSwings': hiddenSwings.map((v) => v.name).toList(),
    'minTempC': minTempC,
    'maxTempC': maxTempC,
  };
  factory CapabilityOverrides.fromJson(Object? json) {
    if (json is! Map) return none;
    Set<T> read<T extends Enum>(String key, List<T> values) => json[key] is List
        ? values.where((v) => (json[key] as List).contains(v.name)).toSet()
        : {};
    return CapabilityOverrides(
      hiddenFeatures: read('hiddenFeatures', AcFeature.values),
      hiddenModes: read('hiddenModes', AcMode.values),
      hiddenFanSpeeds: read('hiddenFanSpeeds', FanSpeed.values),
      hiddenSwings: read('hiddenSwings', VerticalSwing.values),
      minTempC: json['minTempC'] is int ? json['minTempC'] as int : null,
      maxTempC: json['maxTempC'] is int ? json['maxTempC'] as int : null,
    );
  }
  @override
  bool operator ==(Object other) =>
      other is CapabilityOverrides &&
      _same(hiddenFeatures, other.hiddenFeatures) &&
      _same(hiddenModes, other.hiddenModes) &&
      _same(hiddenFanSpeeds, other.hiddenFanSpeeds) &&
      _same(hiddenSwings, other.hiddenSwings) &&
      minTempC == other.minTempC &&
      maxTempC == other.maxTempC;
  static bool _same(Set<Object> a, Set<Object> b) =>
      a.length == b.length && a.containsAll(b);
  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(hiddenFeatures),
    Object.hashAllUnordered(hiddenModes),
    Object.hashAllUnordered(hiddenFanSpeeds),
    Object.hashAllUnordered(hiddenSwings),
    minTempC,
    maxTempC,
  );
}
