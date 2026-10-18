import 'package:flutter_aircon_remote/domain/ac_state.dart';
import 'package:flutter_aircon_remote/domain/ac_enums.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_state_codec.dart';

// Byte vectors transcribed verbatim from IRremoteESP8266 ir_Gree_test.cpp.
// NormalSynthetic, NormalRealExample, Issue814Power, DisplayTempSource.
class GreeVector {
  const GreeVector(this.name, this.model, this.state, this.bytes);
  final String name;
  final GreeModel model;
  final AcState state;
  final List<int> bytes;
}

final greeVectors = [
  GreeVector(
    'baseline-off',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(mode: AcMode.auto, targetTempC: 25),
    [0x00, 0x09, 0x20, 0x50, 0x00, 0x20, 0x00, 0x50],
  ),
  GreeVector(
    'real-cool',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      fan: FanSpeed.low,
      verticalSwing: VerticalSwing.highest,
      tempDisplay: TempDisplay.outdoor,
    ),
    [0x19, 0x0A, 0x60, 0x50, 0x02, 0x23, 0x00, 0xF0],
  ),
  GreeVector(
    'on-yaw1f',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      targetTempC: 23,
      fan: FanSpeed.low,
      verticalSwing: VerticalSwing.auto,
    ),
    [0x59, 0x07, 0x60, 0x50, 0x01, 0x20, 0x00, 0xC0],
  ),
  GreeVector(
    'on-ybofb',
    GreeModel.ybofb,
    const AcState.initial().copyWith(
      power: true,
      targetTempC: 23,
      fan: FanSpeed.low,
      verticalSwing: VerticalSwing.auto,
    ),
    [0x59, 0x07, 0x20, 0x50, 0x01, 0x20, 0x00, 0xC0],
  ),
  for (final model in GreeModel.values)
    GreeVector(
      'off-${model.name}',
      model,
      const AcState.initial().copyWith(
        targetTempC: 23,
        fan: FanSpeed.low,
        verticalSwing: VerticalSwing.auto,
      ),
      [0x51, 0x07, 0x20, 0x50, 0x01, 0x20, 0x00, 0x40],
    ),
  // Legacy unknown2=0; decode only. Canonical outgoing frame has unknown2=4.
  GreeVector(
    'heat-indoor',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      mode: AcMode.heat,
      targetTempC: 20,
      verticalSwing: VerticalSwing.auto,
      tempDisplay: TempDisplay.indoor,
    ),
    [0x4C, 0x04, 0x60, 0x50, 0x01, 0x02, 0x00, 0xA0],
  ),
];

// Issue1821EnergySaver: upstream Fahrenheit capture 1D096058002000A0.
// Celsius equivalent; the power-off vector is derived, not a captured frame.
final yx1fsfVectors = [
  GreeVector(
    'econo-on-yx1fsf',
    GreeModel.yx1fsf,
    const AcState.initial().copyWith(
      power: true,
      mode: AcMode.econo,
      targetTempC: 25,
      fan: FanSpeed.low,
    ),
    [0x1D, 0x09, 0x60, 0x50, 0, 0x20, 0, 0x20],
  ),
  GreeVector(
    'econo-off-yx1fsf-derived',
    GreeModel.yx1fsf,
    const AcState.initial().copyWith(
      mode: AcMode.econo,
      targetTempC: 25,
      fan: FanSpeed.low,
    ),
    [0x15, 0x09, 0x20, 0x50, 0, 0x20, 0, 0xA0],
  ),
  GreeVector('cool-on-yx1fsf', GreeModel.yx1fsf, greeVectors[2].state, [
    0x59,
    0x07,
    0x60,
    0x50,
    1,
    0x20,
    0,
    0xC0,
  ]),
];
