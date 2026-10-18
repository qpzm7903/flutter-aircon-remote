import 'dart:typed_data';

import '../pulse/pulse_timing.dart';
import 'gree_constants.dart';

final class GreePulseBuilder {
  const GreePulseBuilder();
  List<int> build(Uint8List bytes) {
    if (bytes.length != 8) {
      throw ArgumentError('Expected eight bytes');
    }
    const t = GreeConstants.timings;
    final out = [t.headerMark, t.headerSpace];
    for (var i = 0; i < 8; i++) {
      appendBitsLsbFirst(out, bytes[i], 8, t);
      if (i == 3) {
        appendBitsLsbFirst(out, GreeConstants.blockFooter, 3, t);
        out.addAll([t.bitMark, t.gapSpace]);
      }
    }
    return out..addAll([t.bitMark, t.gapSpace]);
  }
}
