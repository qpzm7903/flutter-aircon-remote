import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/domain/ac_enums.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';
import 'package:flutter_aircon_remote/domain/capability_overrides.dart';
import 'package:flutter_aircon_remote/domain/capability_explainer.dart';

import '../support/pump_app.dart';

void main() {
  test('four statuses, unsupported and hidden priority', () {
    final p = testRegistry().fallback.capabilities;
    const o = CapabilityOverrides(
      hiddenFeatures: {AcFeature.sleep, AcFeature.health},
    );
    final items = explainControls(
      protocol: p,
      overrides: o,
      state: const AcState.initial().copyWith(mode: AcMode.fan),
    );
    ControlStatus status(Object v) =>
        items.firstWhere((e) => e.item == v).status;
    expect(status(AcFeature.health), ControlStatus.unsupportedByProtocol);
    expect(status(AcFeature.sleep), ControlStatus.hiddenByUser);
    expect(status(AcFeature.turbo), ControlStatus.lockedByMode);
    expect(status(AcFeature.light), ControlStatus.available);
    expect(items.map((e) => e.status).toSet().length, 4);
    expect(
      explainControls(
        protocol: p,
        overrides: o,
      ).any((e) => e.status == ControlStatus.lockedByMode),
      false,
    );
  });
}
