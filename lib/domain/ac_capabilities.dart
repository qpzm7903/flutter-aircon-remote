import 'ac_enums.dart';
import 'ac_state.dart';
import 'capability_overrides.dart';

class ModeRule {
  const ModeRule({
    this.fixedTempC,
    this.tempEditable = true,
    this.fixedFan,
    this.allowedFeatures = const {},
  });
  final int? fixedTempC;
  final bool tempEditable;
  final FanSpeed? fixedFan;
  final Set<AcFeature> allowedFeatures;
}

class AcCapabilities {
  const AcCapabilities({
    required this.minTempC,
    required this.maxTempC,
    required this.modes,
    required this.fanSpeeds,
    required this.verticalSwings,
    required this.tempDisplays,
    required this.features,
    required this.modeRules,
    this.suppressedFeatures = const {},
  });
  final int minTempC, maxTempC;
  final List<AcMode> modes;
  final List<FanSpeed> fanSpeeds;
  final List<VerticalSwing> verticalSwings;
  final List<TempDisplay> tempDisplays;
  final Set<AcFeature> features;
  final Set<AcFeature> suppressedFeatures;
  final Map<AcMode, ModeRule> modeRules;
  bool isFeatureEnabled(AcState s, AcFeature f) =>
      features.contains(f) && modeRules[s.mode]!.allowedFeatures.contains(f);
  bool canEditTemp(AcState s) =>
      modeRules[s.mode]!.tempEditable && modeRules[s.mode]!.fixedTempC == null;
  bool canEditFan(AcState s) => modeRules[s.mode]!.fixedFan == null;
  AcCapabilities restrictedBy(CapabilityOverrides o) {
    final ms = modes.where((v) => !o.hiddenModes.contains(v)).toList();
    final fs = fanSpeeds.where((v) => !o.hiddenFanSpeeds.contains(v)).toList();
    var lo = o.minTempC == null
        ? minTempC
        : o.minTempC! > minTempC
        ? o.minTempC!
        : minTempC;
    var hi = o.maxTempC == null
        ? maxTempC
        : o.maxTempC! < maxTempC
        ? o.maxTempC!
        : maxTempC;
    if (lo > hi) {
      lo = minTempC;
      hi = maxTempC;
    }
    return AcCapabilities(
      minTempC: lo,
      maxTempC: hi,
      modes: ms.isEmpty ? modes : ms,
      fanSpeeds: fs.isEmpty ? fanSpeeds : fs,
      verticalSwings: verticalSwings
          .where((v) => v == VerticalSwing.off || !o.hiddenSwings.contains(v))
          .toList(),
      tempDisplays: tempDisplays,
      features: features.difference(o.hiddenFeatures),
      suppressedFeatures: {
        ...suppressedFeatures,
        ...features.intersection(o.hiddenFeatures),
      },
      modeRules: modeRules,
    );
  }

  AcState normalize(AcState s) {
    final mode = modes.contains(s.mode) ? s.mode : modes.first;
    final rule = modeRules[mode]!;
    final n = s.copyWith(mode: mode);
    bool enabled(AcFeature f) => isFeatureEnabled(n, f);
    return n.copyWith(
      targetTempC: rule.fixedTempC ?? s.targetTempC.clamp(minTempC, maxTempC),
      fan:
          rule.fixedFan ??
          (fanSpeeds.contains(s.fan) ? s.fan : fanSpeeds.first),
      verticalSwing: verticalSwings.contains(s.verticalSwing)
          ? s.verticalSwing
          : VerticalSwing.off,
      turbo: enabled(AcFeature.turbo) && s.turbo,
      light:
          suppressedFeatures.contains(AcFeature.light) ||
          (enabled(AcFeature.light) && s.light),
      health: enabled(AcFeature.health) && s.health,
      xfan: enabled(AcFeature.xfan) && s.xfan,
      sleep: enabled(AcFeature.sleep) && s.sleep,
      tempDisplay:
          enabled(AcFeature.tempDisplay) && tempDisplays.contains(s.tempDisplay)
          ? s.tempDisplay
          : TempDisplay.off,
    );
  }
}
