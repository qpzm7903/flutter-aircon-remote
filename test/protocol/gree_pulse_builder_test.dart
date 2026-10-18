import 'package:flutter_test/flutter_test.dart';

import 'dart:typed_data';

import 'package:flutter_aircon_remote/protocol/gree/gree_pulse_builder.dart';
import 'package:flutter_aircon_remote/domain/ir_frame.dart';

import '../support/gree_vectors.dart';

void main() {
  for (final v in greeVectors) {
    test('pulse shape and independent decode ${v.name}', () {
      final p = const GreePulseBuilder().build(Uint8List.fromList(v.bytes));
      expect(p.length, 140);
      expect(p.take(2), [9000, 4500]);
      expect(p.sublist(66, 72), [620, 540, 620, 1600, 620, 540]);
      expect(p.sublist(72, 74), [620, 19980]);
      expect(p.sublist(138), [620, 19980]);
      for (var i = 2; i < p.length; i++) {
        expect(p[i], i.isEven ? 620 : isIn([540, 1600, 19980]));
      }
      final decoded = <int>[];
      for (var byte = 0; byte < 8; byte++) {
        final start = byte < 4 ? 2 + byte * 16 : 74 + (byte - 4) * 16;
        var value = 0;
        for (var bit = 0; bit < 8; bit++) {
          if (p[start + bit * 2 + 1] == 1600) {
            value |= 1 << bit;
          }
        }
        decoded.add(value);
      }
      expect(decoded, v.bytes);
      final frame = IrFrame(carrierHz: 38000, patternMicros: p);
      frame.validate();
      expect(frame.totalMicros, lessThan(2000000));
    });
  }
  test('reject wrong byte length', () {
    expect(
      () => const GreePulseBuilder().build(Uint8List(9)),
      throwsArgumentError,
    );
  });
  test('frame validation rejects invalid and oversized signals', () {
    for (final frame in [
      const IrFrame(carrierHz: 0, patternMicros: [1]),
      const IrFrame(carrierHz: 1, patternMicros: []),
      const IrFrame(carrierHz: 1, patternMicros: [0]),
      const IrFrame(carrierHz: 1, patternMicros: [2000000]),
      IrFrame(carrierHz: 1, patternMicros: List.filled(1001, 1)),
    ]) {
      expect(frame.validate, throwsArgumentError);
    }
  });
}
