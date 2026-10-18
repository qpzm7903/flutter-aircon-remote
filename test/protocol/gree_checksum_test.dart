import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_state_codec.dart';

import '../support/gree_vectors.dart';

void main() {
  for (final v in greeVectors) {
    test('checksum ${v.name} and protected bit corruption', () {
      expect(GreeStateCodec.isValid(v.bytes), true);
      for (var i = 0; i < 7; i++) {
        // Kelvinator sum covers only low nibbles of 0..3 and high nibbles of 4..6.
        for (var bit = i < 4 ? 0 : 4; bit < (i < 4 ? 4 : 8); bit++) {
          final b = List<int>.of(v.bytes);
          b[i] ^= 1 << bit;
          expect(GreeStateCodec.isValid(b), false);
        }
      }
      for (var bit = 4; bit < 8; bit++) {
        final b = List<int>.of(v.bytes);
        b[7] ^= 1 << bit;
        expect(GreeStateCodec.isValid(b), false);
      }
    });
  }
  test('invalid length and byte values', () {
    expect(GreeStateCodec.isValid([]), false);
    expect(GreeStateCodec.isValid(List.filled(9, 0)), false);
    expect(GreeStateCodec.isValid(List.filled(8, -1)), false);
  });
}
