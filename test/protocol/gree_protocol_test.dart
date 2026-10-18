import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_protocol.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_state_codec.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';

void main() {
  test('three model declarations and exact pairing probes', () {
    final expected = [
      '09 0A 60 50 00 20 00 F0',
      '09 0A 20 50 00 20 00 F0',
      '0D 0A 60 50 00 20 00 30',
    ];
    for (final m in GreeModel.values) {
      final p = GreeProtocol(m);
      expect(p.capabilities.modes.length, m == GreeModel.yx1fsf ? 6 : 5);
      expect(p.modelNote, isNotEmpty);
      final frame = p.encode(p.pairingProbe);
      expect(frame.debugHex, expected[m.index]);
      expect(frame.carrierHz, 38000);
      expect(() => frame.validate(), returnsNormally);
    }
  });

  test('end to end frame and defaults', () {
    final p = GreeProtocol(GreeModel.yaw1f);
    final f = p.encode(const AcState.initial());
    expect(f.carrierHz, 38000);
    expect(f.debugHex, '01 0A 20 50 00 20 00 70');
    expect(f.debugHex, matches(RegExp(r'^[0-9A-F]{2}( [0-9A-F]{2}){7}$')));
    expect(f.validate, returnsNormally);
  });
}
