import 'dart:typed_data';

import '../../domain/ac_state.dart';
import '../../domain/ac_enums.dart';

enum GreeModel { yaw1f, ybofb }

final class GreeStateCodec {
  const GreeStateCodec(this.model);
  final GreeModel model;
  Uint8List encode(AcState s) {
    final b = Uint8List.fromList([
      s.mode.index |
          (s.power ? 8 : 0) |
          (s.fan.index << 4) |
          (s.verticalSwing == VerticalSwing.auto ? 64 : 0) |
          (s.sleep ? 128 : 0),
      s.targetTempC - 16,
      (s.turbo ? 16 : 0) |
          (s.light ? 32 : 0) |
          (s.power && model == GreeModel.yaw1f ? 64 : 0) |
          (s.xfan ? 128 : 0),
      0x50,
      s.verticalSwing.index,
      0x20 | s.tempDisplay.index,
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
    return const AcState.initial().copyWith(
      power: b[0] & 8 != 0,
      mode: AcMode.values[(b[0] & 7) < 5 ? b[0] & 7 : 0],
      targetTempC: 16 + (b[1] & 15),
      fan: FanSpeed.values[(b[0] >> 4) & 3],
      turbo: b[2] & 16 != 0,
      light: b[2] & 32 != 0,
      xfan: b[2] & 128 != 0,
      sleep: b[0] & 128 != 0,
      verticalSwing: VerticalSwing.values[(b[4] & 15) < 7 ? b[4] & 15 : 0],
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
