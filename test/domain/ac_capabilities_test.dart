import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';
import 'package:flutter_aircon_remote/domain/ac_enums.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_protocol.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_state_codec.dart';
import 'package:flutter_aircon_remote/domain/ac_capabilities.dart';

void main() {
  final c = GreeProtocol(GreeModel.yaw1f).capabilities;
  test('Gree mode rules, clamp, feature intersection and editability', () {
    const s = AcState.initial();
    expect(c.normalize(s.copyWith(targetTempC: 10)).targetTempC, 16);
    expect(c.normalize(s.copyWith(targetTempC: 40)).targetTempC, 30);
    expect(c.normalize(s.copyWith(mode: AcMode.auto)).targetTempC, 25);
    expect(c.canEditTemp(s.copyWith(mode: AcMode.auto)), false);
    expect(c.canEditTemp(s.copyWith(mode: AcMode.fan)), false);
    expect(
      c.normalize(s.copyWith(mode: AcMode.dry, fan: FanSpeed.high)).fan,
      FanSpeed.low,
    );
    expect(c.canEditFan(s.copyWith(mode: AcMode.dry)), false);
    final fan = c.normalize(
      s.copyWith(
        mode: AcMode.fan,
        turbo: true,
        xfan: true,
        sleep: true,
        health: true,
      ),
    );
    expect(fan.turbo || fan.xfan || fan.sleep || fan.health, false);
    expect(c.isFeatureEnabled(s, AcFeature.health), false);
  });
  test('normalization is idempotent across mode fan temperature and flags', () {
    for (final mode in AcMode.values) {
      for (final fan in FanSpeed.values) {
        for (final t in [-100, 16, 25, 30, 100]) {
          final s = const AcState.initial().copyWith(
            power: true,
            mode: mode,
            fan: fan,
            targetTempC: t,
            turbo: true,
            xfan: true,
            sleep: true,
            health: true,
          );
          final n = c.normalize(s);
          expect(c.normalize(n), n);
          expect(n.power, true);
        }
      }
    }
  });
  test('capabilities reject unsupported enums and hide absent features', () {
    const caps = AcCapabilities(
      minTempC: 18,
      maxTempC: 28,
      modes: [AcMode.cool],
      fanSpeeds: [FanSpeed.low],
      verticalSwings: [],
      tempDisplays: [TempDisplay.off],
      features: {},
      modeRules: {AcMode.cool: ModeRule()},
    );
    final s = caps.normalize(
      const AcState.initial().copyWith(
        mode: AcMode.heat,
        verticalSwing: VerticalSwing.auto,
        tempDisplay: TempDisplay.indoor,
      ),
    );
    expect(s.mode, AcMode.cool);
    expect(s.fan, FanSpeed.low);
    expect(s.verticalSwing, VerticalSwing.off);
    expect(s.tempDisplay, TempDisplay.off);
    expect(s.light, false);
  });
}
