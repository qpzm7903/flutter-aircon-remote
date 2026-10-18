import 'ac_capabilities.dart';
import 'ac_enums.dart';
import 'ac_state.dart';
import 'capability_overrides.dart';

enum ControlKind {
  mode,
  fanSpeed,
  verticalSwing,
  feature,
  temperature,
  horizontalSwing,
}

enum ControlStatus {
  available,
  hiddenByUser,
  unsupportedByProtocol,
  lockedByMode,
}

final class ControlExplanation {
  const ControlExplanation(this.kind, this.item, this.status);
  final ControlKind kind;
  final Object? item;
  final ControlStatus status;
}

List<ControlExplanation> explainControls({
  required AcCapabilities protocol,
  required CapabilityOverrides overrides,
  AcState? state,
}) {
  final effective = protocol.restrictedBy(overrides);
  final s = state == null ? null : effective.normalize(state);
  ControlExplanation item(
    ControlKind k,
    Object? v,
    bool supported,
    bool hidden, [
    bool locked = false,
  ]) => ControlExplanation(
    k,
    v,
    !supported
        ? ControlStatus.unsupportedByProtocol
        : hidden
        ? ControlStatus.hiddenByUser
        : locked
        ? ControlStatus.lockedByMode
        : ControlStatus.available,
  );
  return [
    for (final v in AcMode.values)
      item(
        ControlKind.mode,
        v,
        protocol.modes.contains(v),
        overrides.hiddenModes.contains(v),
      ),
    for (final v in FanSpeed.values)
      item(
        ControlKind.fanSpeed,
        v,
        protocol.fanSpeeds.contains(v),
        overrides.hiddenFanSpeeds.contains(v),
        s != null && !effective.canEditFan(s),
      ),
    for (final v in VerticalSwing.values.where((v) => v != VerticalSwing.off))
      item(
        ControlKind.verticalSwing,
        v,
        protocol.verticalSwings.contains(v),
        overrides.hiddenSwings.contains(v),
      ),
    for (final v in HorizontalSwing.values.where(
      (v) => v != HorizontalSwing.off,
    ))
      item(
        ControlKind.horizontalSwing,
        v,
        protocol.horizontalSwings.contains(v),
        overrides.hiddenHSwings.contains(v) ||
            overrides.hiddenFeatures.contains(AcFeature.swingH),
        s != null && !effective.isFeatureEnabled(s, AcFeature.swingH),
      ),
    for (final v in AcFeature.values)
      item(
        ControlKind.feature,
        v,
        protocol.features.contains(v),
        overrides.hiddenFeatures.contains(v),
        s != null && !effective.isFeatureEnabled(s, v),
      ),
    item(
      ControlKind.temperature,
      null,
      true,
      false,
      s != null && !effective.canEditTemp(s),
    ),
  ];
}
