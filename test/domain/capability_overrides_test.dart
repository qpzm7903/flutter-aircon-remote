import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/domain/ac_enums.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';
import 'package:flutter_aircon_remote/domain/capability_overrides.dart';

import '../support/pump_app.dart';

void main() {
  const o = CapabilityOverrides(
    hiddenFeatures: {AcFeature.light, AcFeature.turbo},
    hiddenModes: {AcMode.heat},
    hiddenFanSpeeds: {FanSpeed.high},
    hiddenSwings: {VerticalSwing.off, VerticalSwing.auto},
    minTempC: 18,
    maxTempC: 28,
  );
  test('JSON roundtrip and malformed fields', () {
    expect(CapabilityOverrides.fromJson(o.toJson()), o);
    expect(o.copyWith(minTempC: null).minTempC, null);
    expect(CapabilityOverrides.fromJson(2), CapabilityOverrides.none);
    final parsed = CapabilityOverrides.fromJson({
      'hiddenFeatures': ['light', 'bad'],
      'minTempC': '18',
      'maxTempC': 28,
    });
    expect(parsed.hiddenFeatures, {AcFeature.light});
    expect(parsed.minTempC, null);
    expect(parsed.maxTempC, 28);
    expect(CapabilityOverrides.none.isEmpty, true);
  });
  for (final p in testRegistry().all) {
    test('${p.id} intersections, neutral values, idempotence and subsets', () {
      for (final override in [
        CapabilityOverrides.none,
        o,
        const CapabilityOverrides(
          hiddenModes: {...AcMode.values},
          hiddenFanSpeeds: {...FanSpeed.values},
        ),
        const CapabilityOverrides(minTempC: 31, maxTempC: 10),
      ]) {
        final c = p.capabilities.restrictedBy(override);
        final twice = c.restrictedBy(override);
        expect(p.capabilities.modes.toSet().containsAll(c.modes), true);
        expect(p.capabilities.features.containsAll(c.features), true);
        expect(p.capabilities.fanSpeeds.toSet().containsAll(c.fanSpeeds), true);
        expect(c.verticalSwings, contains(VerticalSwing.off));
        expect(c.modes, isNotEmpty);
        expect(c.fanSpeeds, isNotEmpty);
        for (final mode in p.capabilities.modes) {
          final s = const AcState.initial().copyWith(
            mode: mode,
            light: false,
            turbo: true,
            targetTempC: 40,
          );
          expect(c.normalize(c.normalize(s)), c.normalize(s));
          expect(twice.normalize(s), c.normalize(s));
          if (override.isEmpty) {
            expect(c.normalize(s), p.capabilities.normalize(s));
          }
        }
      }
      final c = p.capabilities.restrictedBy(o);
      expect(c.features.contains(AcFeature.light), false);
      expect(
        c.normalize(const AcState.initial().copyWith(light: false)).light,
        true,
      );
      expect(
        c
            .normalize(const AcState.initial().copyWith(mode: AcMode.auto))
            .targetTempC,
        25,
      );
      expect(
        c.normalize(const AcState.initial().copyWith(mode: AcMode.dry)).fan,
        FanSpeed.low,
      );
      expect(c.minTempC, 18);
      expect(c.maxTempC, 28);
    });
  }
  test('fallbacks and all neutral fields', () {
    final c = testRegistry().fallback.capabilities.restrictedBy(
      const CapabilityOverrides(
        hiddenFeatures: {...AcFeature.values},
        hiddenModes: {AcMode.cool},
        hiddenFanSpeeds: {FanSpeed.high},
        hiddenSwings: {VerticalSwing.high},
        minTempC: 18,
        maxTempC: 28,
      ),
    );
    final s = c.normalize(
      const AcState.initial().copyWith(
        turbo: true,
        xfan: true,
        sleep: true,
        health: true,
        light: false,
        mode: AcMode.heat,
        fan: FanSpeed.high,
        verticalSwing: VerticalSwing.high,
        tempDisplay: TempDisplay.indoor,
        targetTempC: 40,
      ),
    );
    expect(s.light, true);
    expect(s.turbo || s.xfan || s.sleep || s.health, false);
    expect(s.tempDisplay, TempDisplay.off);
    expect(s.fan, FanSpeed.auto);
    expect(s.verticalSwing, VerticalSwing.off);
    expect(s.targetTempC, 28);
  });
}
