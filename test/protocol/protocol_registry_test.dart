import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_protocol.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_state_codec.dart';
import 'package:flutter_aircon_remote/protocol/protocol_registry.dart';

void main() {
  test('registration lookup order immutability and duplicates', () {
    final a = GreeProtocol(GreeModel.yaw1f);
    final b = GreeProtocol(GreeModel.ybofb);
    final c = GreeProtocol(GreeModel.yx1fsf);
    final r = AcProtocolRegistry([a, b, c]);
    expect(r.brandNameOf('gree'), '格力 Gree');
    expect(r.byId('gree.yaw1f'), a);
    expect(r.byId('unknown'), null);
    expect(r.fallback, a);
    expect(r.brandIds, ['gree']);
    expect(r.modelsOf('gree'), [a, b, c]);
    expect(r.modelsOf('other'), isEmpty);
    expect(() => AcProtocolRegistry([]), throwsStateError);
    expect(() => AcProtocolRegistry([a, a]), throwsStateError);
    expect(() => r.all.clear(), throwsUnsupportedError);
  });
}
