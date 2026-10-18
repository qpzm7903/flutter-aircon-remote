import 'package:flutter_aircon_remote/domain/ac_state.dart';
import 'package:flutter_aircon_remote/domain/ac_enums.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_state_codec.dart';

// Byte vectors transcribed verbatim from IRremoteESP8266 ir_Gree_test.cpp.
// NormalSynthetic, NormalRealExample, Issue814Power, DisplayTempSource.
class GreeVector {
  const GreeVector(
    this.name,
    this.model,
    this.state,
    this.bytes, {
    this.provenance = 'reference',
  });
  final String provenance;
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
    provenance: 'reference-decode',
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
    provenance: 'derived',
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
    provenance: 'derived',
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

final v3Vectors = <GreeVector>[
  GreeVector(
    'fahrenheit-63-ybofb',
    GreeModel.ybofb,
    const AcState.initial().copyWith(
      power: true,
      targetTempC: 17,
      targetTempF: 63,
    ),
    [0x09, 0x01, 0x20, 0x5C, 0x00, 0x20, 0x00, 0x20],
  ),
  GreeVector(
    'econo-77f-yx1fsf',
    GreeModel.yx1fsf,
    const AcState.initial().copyWith(
      power: true,
      mode: AcMode.econo,
      targetTempC: 25,
      targetTempF: 77,
      fan: FanSpeed.low,
    ),
    [0x1D, 0x09, 0x60, 0x58, 0x00, 0x20, 0x00, 0xA0],
  ),
  GreeVector(
    'raw-flags',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      targetTempC: 21,
      fan: FanSpeed.medium,
      light: false,
      turbo: true,
      sleep: true,
      xfan: true,
    ),
    [0xA9, 0x05, 0xD0, 0x50, 0x00, 0x20, 0x00, 0xA0],
  ),
  GreeVector(
    'swingh-auto',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      horizontalSwing: HorizontalSwing.auto,
    ),
    [0x09, 0x0A, 0x60, 0x50, 0x10, 0x20, 0x00, 0x00],
    provenance: 'derived',
  ),
  GreeVector(
    'swingh-maxLeft',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      horizontalSwing: HorizontalSwing.maxLeft,
    ),
    [0x09, 0x0A, 0x60, 0x50, 0x20, 0x20, 0x00, 0x10],
    provenance: 'derived',
  ),
  GreeVector(
    'swingh-left',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      horizontalSwing: HorizontalSwing.left,
    ),
    [0x09, 0x0A, 0x60, 0x50, 0x30, 0x20, 0x00, 0x20],
    provenance: 'derived',
  ),
  GreeVector(
    'swingh-middle',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      horizontalSwing: HorizontalSwing.middle,
    ),
    [0x09, 0x0A, 0x60, 0x50, 0x40, 0x20, 0x00, 0x30],
    provenance: 'derived',
  ),
  GreeVector(
    'swingh-right',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      horizontalSwing: HorizontalSwing.right,
    ),
    [0x09, 0x0A, 0x60, 0x50, 0x50, 0x20, 0x00, 0x40],
    provenance: 'derived',
  ),
  GreeVector(
    'swingh-maxRight',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      horizontalSwing: HorizontalSwing.maxRight,
    ),
    [0x09, 0x0A, 0x60, 0x50, 0x60, 0x20, 0x00, 0x50],
    provenance: 'derived',
  ),
  GreeVector(
    'swingv-autoDown',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      verticalSwing: VerticalSwing.autoDown,
    ),
    [0x49, 0x0A, 0x60, 0x50, 0x07, 0x20, 0x00, 0xF0],
    provenance: 'derived',
  ),
  GreeVector(
    'swingv-autoMiddle',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      verticalSwing: VerticalSwing.autoMiddle,
    ),
    [0x49, 0x0A, 0x60, 0x50, 0x09, 0x20, 0x00, 0xF0],
    provenance: 'derived',
  ),
  GreeVector(
    'swingv-autoUp',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      verticalSwing: VerticalSwing.autoUp,
    ),
    [0x49, 0x0A, 0x60, 0x50, 0x0B, 0x20, 0x00, 0xF0],
    provenance: 'derived',
  ),
  GreeVector(
    'wifi-pulse',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(power: true, wifiPulse: true),
    [0x09, 0x0A, 0x60, 0x50, 0x00, 0x60, 0x00, 0x30],
    provenance: 'derived',
  ),
  GreeVector(
    'timer-30',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      timerMinutes: 30,
      timerSetAtMs: 0,
    ),
    [0x09, 0x9A, 0x60, 0x50, 0x00, 0x20, 0x00, 0xF0],
    provenance: 'derived',
  ),
  GreeVector(
    'timer-60',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      timerMinutes: 60,
      timerSetAtMs: 0,
    ),
    [0x09, 0x8A, 0x61, 0x50, 0x00, 0x20, 0x00, 0x00],
    provenance: 'derived',
  ),
  GreeVector(
    'timer-90',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      timerMinutes: 90,
      timerSetAtMs: 0,
    ),
    [0x09, 0x9A, 0x61, 0x50, 0x00, 0x20, 0x00, 0x00],
    provenance: 'derived',
  ),
  GreeVector(
    'timer-600',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      timerMinutes: 600,
      timerSetAtMs: 0,
    ),
    [0x09, 0xAA, 0x60, 0x50, 0x00, 0x20, 0x00, 0xF0],
    provenance: 'derived',
  ),
  GreeVector(
    'timer-1410',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      timerMinutes: 1410,
      timerSetAtMs: 0,
    ),
    [0x09, 0xDA, 0x63, 0x50, 0x00, 0x20, 0x00, 0x20],
    provenance: 'derived',
  ),
  GreeVector(
    'timer-1440',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      timerMinutes: 1440,
      timerSetAtMs: 0,
    ),
    [0x09, 0xCA, 0x64, 0x50, 0x00, 0x20, 0x00, 0x30],
    provenance: 'derived',
  ),
  GreeVector(
    'f61-yaw1f',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      targetTempC: 16,
      targetTempF: 61,
    ),
    [0x09, 0x00, 0x60, 0x58, 0x00, 0x20, 0x00, 0xD0],
    provenance: 'derived',
  ),
  GreeVector(
    'f70-yaw1f',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      targetTempC: 21,
      targetTempF: 70,
    ),
    [0x09, 0x05, 0x60, 0x5C, 0x00, 0x20, 0x00, 0x60],
    provenance: 'derived',
  ),
  GreeVector(
    'f79-yaw1f',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      targetTempC: 26,
      targetTempF: 79,
    ),
    [0x09, 0x0A, 0x60, 0x5C, 0x00, 0x20, 0x00, 0xB0],
    provenance: 'derived',
  ),
  GreeVector(
    'f86-yaw1f',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      targetTempC: 30,
      targetTempF: 86,
    ),
    [0x09, 0x0E, 0x60, 0x58, 0x00, 0x20, 0x00, 0xB0],
    provenance: 'derived',
  ),
  GreeVector(
    'auto-77f-yaw1f',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      mode: AcMode.auto,
      targetTempC: 25,
      targetTempF: 77,
    ),
    [0x08, 0x09, 0x60, 0x58, 0x00, 0x20, 0x00, 0x50],
    provenance: 'derived',
  ),
];

// TestGreeClass.WiFi and IFeel: legacy unknown2=0, decode only.
final v3DecodeVectors = [
  GreeVector(
    'wifi-on-legacy',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      targetTempC: 25,
      wifiPulse: true,
    ),
    [0x09, 0x09, 0x60, 0x50, 0, 0x40, 0, 0],
    provenance: 'reference-decode',
  ),
  GreeVector(
    'wifi-off-legacy',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(power: true, targetTempC: 25),
    [0x09, 0x09, 0x60, 0x50, 0, 0, 0, 0xC0],
    provenance: 'reference-decode',
  ),
  GreeVector(
    'ifeel-on-legacy',
    GreeModel.yaw1f,
    const AcState.initial().copyWith(
      power: true,
      mode: AcMode.auto,
      targetTempC: 25,
      wifiPulse: true,
    ),
    [0x08, 0x09, 0x60, 0x50, 0, 0x44, 0, 0xF0],
    provenance: 'reference-decode',
  ),
];
