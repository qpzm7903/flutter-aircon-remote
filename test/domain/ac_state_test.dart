import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';
import 'package:flutter_aircon_remote/domain/ac_enums.dart';

void main() {
  test('econo JSON and unknown mode fallback', () {
    final s = const AcState.initial().copyWith(mode: AcMode.econo);
    expect(AcState.fromJson(s.toJson()), s);
    expect(AcState.fromJson({'mode': 'bad'}).mode, AcMode.cool);
  });

  test('initial state, JSON schema and value equality', () {
    const s = AcState.initial();
    expect(s.power, false);
    expect(s.targetTempC, 26);
    expect(s.light, true);
    expect(s.toJson()['v'], 1);
    expect(AcState.fromJson(s.toJson()), s);
    expect(s.copyWith().hashCode, s.hashCode);
    final n = s.copyWith(
      power: true,
      mode: AcMode.heat,
      targetTempC: 20,
      fan: FanSpeed.high,
      turbo: true,
      verticalSwing: VerticalSwing.low,
      light: false,
      health: true,
      xfan: true,
      sleep: true,
      tempDisplay: TempDisplay.indoor,
    );
    expect(n, isNot(s));
    expect(AcState.fromJson(n.toJson()), n);
    expect(n.toString(), contains('heat'));
  });
  test('corrupt and unknown fields fall back independently', () {
    expect(
      AcState.fromJson({
        'mode': 'new',
        'fan': 1,
        'targetTempC': '20',
        'power': null,
      }),
      const AcState.initial(),
    );
    expect(
      AcState.fromJson({'light': false, 'targetTempC': -20}).targetTempC,
      -20,
    );
    expect(AcState.fromJson({'light': false}).light, false);
  });
}
