import 'dart:typed_data';

import 'gree_constants.dart';

import '../../domain/ac_state.dart';
import '../../domain/ac_enums.dart';

enum GreeModel { yaw1f, ybofb, yx1fsf }

final class GreeStateCodec {
  const GreeStateCodec(this.model);
  final GreeModel model;
  Uint8List encode(AcState s) {
    if (s.mode == AcMode.econo && model != GreeModel.yx1fsf) {
      throw ArgumentError('Unsupported econo');
    }
    final row = s.targetTempF == null
        ? null
        : greeFahrenheitTable.where((r) => r.f == s.targetTempF).firstOrNull;
    if (s.targetTempF != null && row == null ||
        s.timerMinutes % 30 != 0 ||
        s.timerMinutes < 0 ||
        s.timerMinutes > 1440) {
      throw ArgumentError('Invalid temperature/timer');
    }
    final m = s.timerMinutes;
    final hours = m ~/ 60;
    final b = Uint8List.fromList([
      s.mode.index |
          (s.power ? 8 : 0) |
          (s.fan.index << 4) |
          ({
                VerticalSwing.auto,
                VerticalSwing.autoDown,
                VerticalSwing.autoMiddle,
                VerticalSwing.autoUp,
              }.contains(s.verticalSwing)
              ? 64
              : 0) |
          (s.sleep ? 128 : 0),
      ((row?.c ?? s.targetTempC) - 16) |
          (m % 60 >= 30 ? 16 : 0) |
          ((hours ~/ 10) << 5) |
          (m >= 30 ? 128 : 0),
      (hours % 10) |
          (s.turbo ? 16 : 0) |
          (s.light ? 32 : 0) |
          (s.power && model != GreeModel.ybofb ? 64 : 0) |
          (s.xfan ? 128 : 0),
      0x50 | (row == null ? 0 : 8 | row.extra << 2),
      greeVerticalSwingValues[s.verticalSwing]! |
          (greeHorizontalSwingValues[s.horizontalSwing]! << 4),
      0x20 | s.tempDisplay.index | (s.wifiPulse ? 64 : 0),
      0,
      0,
    ]);
    b[7] = checksum(b) << 4;
    return b;
  }

  AcState decode(Uint8List b) {
    if (b.length != 8) {
      throw ArgumentError('Expected eight bytes');
    }
    final c = 16 + (b[1] & 15);
    final timer = b[1] & 128 == 0
        ? 0
        : (((b[1] >> 5) & 3) * 10 + (b[2] & 15)) * 60 +
              (b[1] & 16 != 0 ? 30 : 0);
    return const AcState.initial().copyWith(
      targetTempF: b[3] & 8 != 0
          ? (((9 * c + 160) ~/ 5) + ((b[3] >> 2) & 1)).clamp(61, 255)
          : null,
      timerMinutes: timer,
      timerSetAtMs: timer > 0 ? 0 : null,
      wifiPulse: b[5] & 64 != 0,
      horizontalSwing:
          greeHorizontalSwingValues.entries
              .where((e) => e.value == ((b[4] >> 4) & 7))
              .firstOrNull
              ?.key ??
          HorizontalSwing.off,
      power: b[0] & 8 != 0,
      mode:
          AcMode.values[(b[0] & 7) < (model == GreeModel.yx1fsf ? 6 : 5)
              ? b[0] & 7
              : 0],
      targetTempC: 16 + (b[1] & 15),
      fan: FanSpeed.values[(b[0] >> 4) & 3],
      turbo: b[2] & 16 != 0,
      light: b[2] & 32 != 0,
      xfan: b[2] & 128 != 0,
      sleep: b[0] & 128 != 0,
      verticalSwing:
          greeVerticalSwingValues.entries
              .where((e) => e.value == (b[4] & 15))
              .firstOrNull
              ?.key ??
          VerticalSwing.off,
      tempDisplay: TempDisplay.values[b[5] & 3],
    );
  }

  static int checksum(List<int> b) {
    var sum = 10;
    for (var i = 0; i < 4; i++) {
      sum += b[i] & 15;
    }
    for (var i = 4; i < 7; i++) {
      sum += b[i] >> 4;
    }
    return sum & 15;
  }

  static bool isValid(List<int> b) =>
      b.length == 8 &&
      b.every((v) => v >= 0 && v <= 255) &&
      b[7] >> 4 == checksum(b);
}
