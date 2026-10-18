import 'dart:typed_data';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/domain/ac_enums.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';
import 'package:flutter_aircon_remote/domain/capability_overrides.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_constants.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_state_codec.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_protocol.dart';

import '../support/gree_vectors.dart';

void main() {
  for (final v in v3DecodeVectors) {
    test('${v.provenance}: ${v.name}', () {
      expect(GreeStateCodec.isValid(v.bytes), true);
      expect(
        GreeStateCodec(v.model).decode(Uint8List.fromList(v.bytes)),
        v.state,
      );
    });
  }
  for (final v in v3Vectors) {
    test('${v.provenance}: ${v.name}', () {
      final codec = GreeStateCodec(v.model);
      expect(GreeStateCodec.isValid(v.bytes), true);
      expect(codec.encode(v.state), v.bytes);
      expect(codec.decode(Uint8List.fromList(v.bytes)), v.state);
    });
  }
  for (final row in greeFahrenheitTable) {
    test('Fahrenheit ${row.f} exact bits and roundtrip', () {
      const codec = GreeStateCodec(GreeModel.yaw1f);
      final b = codec.encode(
        const AcState.initial().copyWith(targetTempF: row.f),
      );
      expect(b[1] & 15, row.c - 16);
      expect(b[3], 0x58 | row.extra << 2);
      expect(codec.decode(b).targetTempF, row.f);
      expect(max(61, (9 * row.c + 160) ~/ 5 + row.extra), row.f);
      if (row.f != 70 && row.f != 79) {
        final numerator = 5 * row.f - 157;
        final c = (numerator ~/ 9).clamp(16, 30);
        expect(row.c, c);
        expect(row.extra, c == 30 ? 0 : ((2 * numerator ~/ 9) & 1));
      }
    });
  }
  test('C/F conversion and restricted ranges', () {
    final c = GreeProtocol(GreeModel.yaw1f).capabilities;
    for (var t = 16; t <= 30; t++) {
      expect(c.celsiusFor(c.fahrenheitFor(t)!), t);
    }
    final e = c.restrictedBy(
      const CapabilityOverrides(minTempC: 20, maxTempC: 26),
    );
    expect(e.fahrenheitRange, (min: 68, max: 79));
  });
  test('invalid nibble decoding and explicit swing bits', () {
    const codec = GreeStateCodec(GreeModel.yaw1f);
    for (final v in [8, 10, 12, 13, 14, 15]) {
      final b = codec.encode(const AcState.initial())..[4] = v | 0x70;
      expect(codec.decode(b).verticalSwing, VerticalSwing.off);
      expect(codec.decode(b).horizontalSwing, HorizontalSwing.off);
    }
    for (final e in greeVerticalSwingValues.entries) {
      final b = codec.encode(
        const AcState.initial().copyWith(verticalSwing: e.key),
      );
      expect(b[4] & 15, e.value);
      expect(b[0] & 64 != 0, [1, 7, 9, 11].contains(e.value));
    }
  });
  test('reference WiFi and IFeel captures', () {
    const codec = GreeStateCodec(GreeModel.yaw1f);
    for (final raw in [
      '09 09 60 50 00 40 00 00',
      '09 09 60 50 00 00 00 C0',
      '08 09 60 50 00 44 00 F0',
    ]) {
      final b = Uint8List.fromList(
        raw.split(' ').map((v) => int.parse(v, radix: 16)).toList(),
      );
      expect(GreeStateCodec.isValid(b), true);
      final state = codec.decode(b);
      expect(state.wifiPulse, b[5] & 64 != 0);
      expect(codec.encode(state)[5], b[5] & 64 != 0 ? 0x60 : 0x20);
      expect(codec.encode(state.copyWith(wifiPulse: false))[5], 0x20);
    }
  });
  test('reserved fields across random legal states', () {
    final random = Random(37);
    final p = GreeProtocol(GreeModel.yx1fsf);
    for (var i = 0; i < 500; i++) {
      final state = p.capabilities.normalize(
        const AcState.initial().copyWith(
          power: random.nextBool(),
          mode: AcMode.values[random.nextInt(6)],
          horizontalSwing: HorizontalSwing.values[random.nextInt(7)],
          verticalSwing: VerticalSwing.values[random.nextInt(10)],
          targetTempF: 61 + random.nextInt(26),
          timerMinutes: random.nextInt(49) * 30,
          timerSetAtMs: 0,
          wifiPulse: random.nextBool(),
        ),
      );
      final b = GreeStateCodec(p.model).encode(state);
      expect(b[3] & 0xF3, 0x50);
      expect(b[4] & 128, 0);
      expect(b[5] & 0xBC, 0x20);
      expect(b[6], 0);
      expect(b[7] & 15, 0);
      expect(GreeStateCodec.isValid(b), true);
    }
  });
  test('codec rejects unnormalized values', () {
    const c = GreeStateCodec(GreeModel.yaw1f);
    expect(
      () => c.encode(const AcState.initial().copyWith(targetTempF: 60)),
      throwsArgumentError,
    );
    expect(
      () => c.encode(const AcState.initial().copyWith(timerMinutes: 29)),
      throwsArgumentError,
    );
  });
  for (final model in GreeModel.values) {
    test('$model new capabilities and seeds', () {
      final p = GreeProtocol(model), c = GreeProtocol(model).capabilities;
      expect(c.horizontalSwings, HorizontalSwing.values);
      expect(c.verticalSwings, VerticalSwing.values);
      expect(c.timerStepMinutes, 30);
      expect(c.maxTimerMinutes, 1440);
      expect(
        p.recommendedOverrides.hiddenFeatures.contains(AcFeature.fahrenheit),
        model != GreeModel.yx1fsf,
      );
      for (final mode in c.modes) {
        for (final f in [
          AcFeature.swingH,
          AcFeature.wifi,
          AcFeature.timer,
          AcFeature.fahrenheit,
        ]) {
          expect(
            c.isFeatureEnabled(p.defaultState.copyWith(mode: mode), f),
            true,
          );
        }
      }
    });
  }
}
