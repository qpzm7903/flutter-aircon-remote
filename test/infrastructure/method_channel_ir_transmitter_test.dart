import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_aircon_remote/core/constants.dart';
import 'package:flutter_aircon_remote/domain/ir_frame.dart';
import 'package:flutter_aircon_remote/infrastructure/ir/ir_transmitter.dart';
import 'package:flutter_aircon_remote/infrastructure/ir/method_channel_ir_transmitter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(AppConstants.irChannelName);
  const ir = MethodChannelIrTransmitter();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const frame = IrFrame(carrierHz: 38000, patternMicros: [620, 540]);
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  test('channel arguments emitter and frequency ranges', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'hasIrEmitter') {
        return true;
      }
      if (call.method == 'getCarrierFrequencies') {
        return [
          {'min': 30000, 'max': 60000},
        ];
      }
      expect(call.method, 'transmit');
      expect(call.arguments, {
        'carrierHz': 38000,
        'pattern': [620, 540],
      });
      return null;
    });
    expect(await ir.hasIrEmitter(), true);
    final ranges = await ir.getCarrierFrequencies();
    expect(ranges.single.minHz, 30000);
    expect(ranges.single.maxHz, 60000);
    await ir.transmit(frame);
  });
  final codes = {
    'NO_IR_EMITTER': IrErrorCode.noIrEmitter,
    'INVALID_ARGUMENT': IrErrorCode.invalidArgument,
    'PATTERN_TOO_LONG': IrErrorCode.patternTooLong,
    'UNSUPPORTED_FREQUENCY': IrErrorCode.unsupportedFrequency,
    'PERMISSION_DENIED': IrErrorCode.permissionDenied,
    'TRANSMIT_FAILED': IrErrorCode.transmitFailed,
    'OTHER': IrErrorCode.platform,
  };
  for (final entry in codes.entries) {
    test('maps ${entry.key}', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: entry.key),
      );
      await expectLater(
        ir.transmit(frame),
        throwsA(
          isA<IrTransmitException>().having((e) => e.code, 'code', entry.value),
        ),
      );
      expect(await ir.hasIrEmitter(), false);
      expect(await ir.getCarrierFrequencies(), isEmpty);
    });
  }
  test('missing plugin and local frame validation', () async {
    expect(await ir.hasIrEmitter(), false);
    expect(await ir.getCarrierFrequencies(), isEmpty);
    await expectLater(
      ir.transmit(frame),
      throwsA(
        isA<IrTransmitException>().having(
          (e) => e.code,
          'code',
          IrErrorCode.platform,
        ),
      ),
    );
    await expectLater(
      ir.transmit(const IrFrame(carrierHz: 0, patternMicros: [1])),
      throwsA(
        isA<IrTransmitException>().having(
          (e) => e.code,
          'code',
          IrErrorCode.invalidArgument,
        ),
      ),
    );
    await expectLater(
      ir.transmit(const IrFrame(carrierHz: 1, patternMicros: [2000000])),
      throwsA(
        isA<IrTransmitException>().having(
          (e) => e.code,
          'code',
          IrErrorCode.patternTooLong,
        ),
      ),
    );
  });
}
