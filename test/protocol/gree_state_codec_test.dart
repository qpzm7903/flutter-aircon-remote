import 'package:flutter_test/flutter_test.dart';

import 'dart:typed_data';

import 'package:flutter_aircon_remote/protocol/gree/gree_state_codec.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_protocol.dart';
import 'package:flutter_aircon_remote/domain/ac_enums.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';

import '../support/gree_vectors.dart';

void main() {
  for (final v in greeVectors) {
    test('decode reference ${v.name}', () {
      expect(
        GreeStateCodec(v.model).decode(Uint8List.fromList(v.bytes)),
        v.state,
      );
    });
    if (v.name != 'heat-indoor') {
      test('encode reference ${v.name}', () {
        final codec = GreeStateCodec(v.model);
        expect(codec.encode(v.state), v.bytes);
        expect(
          codec.encode(GreeProtocol(v.model).capabilities.normalize(v.state)),
          v.bytes,
        );
      });
    }
  }
  test('legacy heat vector canonicalizes only reserved field and checksum', () {
    final v = greeVectors.last;
    expect(GreeStateCodec(v.model).encode(v.state), [
      0x4C,
      0x04,
      0x60,
      0x50,
      0x01,
      0x22,
      0x00,
      0xC0,
    ]);
    expect(
      () => GreeStateCodec(v.model).decode(Uint8List(7)),
      throwsArgumentError,
    );
  });
  test(
    'sampled mode fan temperature flags preserve reserved bits and round trip',
    () {
      for (final model in GreeModel.values) {
        final protocol = GreeProtocol(model);
        final codec = GreeStateCodec(model);
        for (final mode in AcMode.values) {
          for (final fan in FanSpeed.values) {
            for (final t in [16, 23, 30]) {
              for (final enabled in [false, true]) {
                final s = protocol.capabilities.normalize(
                  const AcState.initial().copyWith(
                    mode: mode,
                    fan: fan,
                    targetTempC: t,
                    power: enabled,
                    turbo: enabled,
                    sleep: enabled,
                    xfan: enabled,
                    light: enabled,
                  ),
                );
                final b = codec.encode(s);
                expect(GreeStateCodec.isValid(b), true);
                expect(b[3], 0x50);
                expect(b[5] & 0x38, 0x20);
                expect(b[1] & 0xF0, 0);
                expect(b[2] & 15, 0);
                expect(b[4] & 0xF0, 0);
                expect(b[6], 0);
                expect(b[7] & 15, 0);
                expect(codec.decode(b), s);
              }
            }
          }
        }
      }
    },
  );
}
