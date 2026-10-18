import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';
import 'package:flutter_aircon_remote/domain/ac_enums.dart';
import 'package:flutter_aircon_remote/domain/capability_overrides.dart';
import 'package:flutter_aircon_remote/domain/capability_explainer.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_protocol.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_state_codec.dart';

void main() {
  test('new fields JSON equality and nullable copy; pulse never persists', () {
    final s = const AcState.initial().copyWith(
      horizontalSwing: HorizontalSwing.right,
      targetTempF: 79,
      timerMinutes: 90,
      timerSetAtMs: 123,
      verticalSwing: VerticalSwing.autoUp,
    );
    expect(AcState.fromJson(s.toJson()), s);
    expect(AcState.fromJson(s.toJson()).hashCode, s.hashCode);
    expect(s.copyWith(wifiPulse: true).toJson(), s.toJson());
    expect(
      AcState.fromJson({...s.toJson(), 'wifiPulse': true}).wifiPulse,
      false,
    );
    expect(
      s.copyWith(targetTempF: null, timerSetAtMs: null).useFahrenheit,
      false,
    );
    expect(AcState.fromJson({'v': 1}), const AcState.initial());
    for (final changed in [
      s.copyWith(horizontalSwing: HorizontalSwing.left),
      s.copyWith(targetTempF: 78),
      s.copyWith(timerMinutes: 60),
      s.copyWith(timerSetAtMs: 124),
      s.copyWith(wifiPulse: true),
    ]) {
      expect(changed, isNot(s));
      expect(changed.hashCode, isNot(s.hashCode));
    }
  });
  test(
    'timer resolution rounds, expires, handles missing epoch and rollback',
    () {
      final s = const AcState.initial().copyWith(
        timerMinutes: 90,
        timerSetAtMs: 100000,
      );
      expect(s.resolveTimer(100000 + 31 * 60000).timerMinutes, 60);
      expect(s.resolveTimer(100001).timerMinutes, 90);
      expect(s.resolveTimer(0).timerMinutes, 90);
      expect(s.resolveTimer(100000 + 90 * 60000).timerSetAtMs, null);
      expect(s.copyWith(timerSetAtMs: null).resolveTimer(0).timerMinutes, 0);
    },
  );
  test('override horizontal JSON tolerance, off protected, isEmpty', () {
    const o = CapabilityOverrides(
      hiddenHSwings: {HorizontalSwing.off, HorizontalSwing.right},
    );
    expect(o.isEmpty, false);
    expect(CapabilityOverrides.fromJson(o.toJson()), o);
    expect(
      CapabilityOverrides.fromJson({
        'hiddenHSwings': ['bad', 'left', 42],
      }).hiddenHSwings,
      {HorizontalSwing.left},
    );
    expect(CapabilityOverrides.fromJson({'hiddenHSwings': 42}).isEmpty, true);
    final c = GreeProtocol(GreeModel.yaw1f).capabilities.restrictedBy(o);
    expect(c.horizontalSwings, contains(HorizontalSwing.off));
    expect(c.horizontalSwings, isNot(contains(HorizontalSwing.right)));
    expect(
      c
          .normalize(
            const AcState.initial().copyWith(
              horizontalSwing: HorizontalSwing.right,
            ),
          )
          .horizontalSwing,
      HorizontalSwing.off,
    );
  });
  test('all models normalize neutral fields, table temperatures, timer and idempotence', () {
    for (final model in GreeModel.values) {
      final p = GreeProtocol(model);
      final state = const AcState.initial().copyWith(
        horizontalSwing: HorizontalSwing.auto,
        targetTempF: 79,
        targetTempC: 26,
        timerMinutes: 90,
        timerSetAtMs: 0,
        wifiPulse: true,
      );
      final hidden = p.capabilities.restrictedBy(
        p.recommendedOverrides.copyWith(
          hiddenFeatures: {
            AcFeature.swingH,
            AcFeature.fahrenheit,
            AcFeature.timer,
            AcFeature.wifi,
          },
        ),
      );
      final n = hidden.normalize(state);
      expect(n.horizontalSwing, HorizontalSwing.off);
      expect(n.targetTempF, null);
      expect(n.timerMinutes, 0);
      expect(n.timerSetAtMs, null);
      expect(n.wifiPulse, false);
      expect(hidden.normalize(n), n);
      final c = p.capabilities;
      expect(c.normalize(state.copyWith(mode: AcMode.auto)).targetTempF, 77);
      expect(c.normalize(state.copyWith(timerSetAtMs: null)).timerMinutes, 0);
      for (final m in [0, 29, 30, 60, 90, 600, 1439, 1441, 1470]) {
        final n = c.normalize(state.copyWith(timerMinutes: m));
        expect(n.timerMinutes, (m.clamp(0, 1440) ~/ 30) * 30);
        expect(c.normalize(n), n);
      }
      for (final mode in c.modes) {
        final n = c.normalize(state.copyWith(mode: mode));
        expect(c.normalize(n), n);
      }
    }
  });
  test(
    'restricted fixed temperature preserves Fahrenheit using nearest step',
    () {
      for (final model in GreeModel.values) {
        for (final range in [(16, 20), (28, 30)]) {
          final c = GreeProtocol(model).capabilities.restrictedBy(
            CapabilityOverrides(minTempC: range.$1, maxTempC: range.$2),
          );
          final n = c.normalize(
            const AcState.initial().copyWith(
              mode: AcMode.auto,
              targetTempF: 77,
            ),
          );
          expect(n.useFahrenheit, true);
          expect(n.targetTempC, range.$1 == 16 ? 20 : 28);
          expect(c.normalize(n), n);
        }
      }
    },
  );
  test('new explanation hidden priority and unsupported controls', () {
    final c = GreeProtocol(GreeModel.yaw1f).capabilities;
    final e = explainControls(
      protocol: c,
      overrides: const CapabilityOverrides(hiddenFeatures: {AcFeature.swingH}),
    );
    expect(e.where((e) => e.kind == ControlKind.horizontalSwing).length, 6);
    expect(
      e
          .where((e) => e.kind == ControlKind.horizontalSwing)
          .every((e) => e.status == ControlStatus.hiddenByUser),
      true,
    );
    expect(e.any((e) => e.item == VerticalSwing.autoUp), true);
  });
}
