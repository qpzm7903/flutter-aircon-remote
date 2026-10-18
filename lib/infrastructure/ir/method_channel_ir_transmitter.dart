import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../domain/ir_frame.dart';
import '../logging/log_service.dart';
import 'ir_transmitter.dart';

class MethodChannelIrTransmitter implements IrTransmitter {
  const MethodChannelIrTransmitter({
    this.channel = const MethodChannel(AppConstants.irChannelName),
  });
  final MethodChannel channel;
  @override
  Future<bool> hasIrEmitter() async {
    try {
      return await channel.invokeMethod<bool>('hasIrEmitter') ?? false;
    } catch (e) {
      LogService.warning('IR probe failed', e);
      return false;
    }
  }

  @override
  Future<List<CarrierRange>> getCarrierFrequencies() async {
    try {
      final values =
          await channel.invokeListMethod<Object?>('getCarrierFrequencies') ??
          [];
      return values.map((v) {
        final m = v as Map;
        return CarrierRange(m['min'] as int, m['max'] as int);
      }).toList();
    } catch (e) {
      LogService.warning('Carrier probe failed', e);
      return [];
    }
  }

  @override
  Future<void> transmit(IrFrame frame) async {
    try {
      frame.validate();
    } on ArgumentError catch (e) {
      final tooLong =
          frame.patternMicros.length > 1000 || frame.totalMicros >= 2000000;
      throw IrTransmitException(
        tooLong ? IrErrorCode.patternTooLong : IrErrorCode.invalidArgument,
        e.toString(),
      );
    }
    try {
      await channel.invokeMethod<void>('transmit', {
        'carrierHz': frame.carrierHz,
        'pattern': frame.patternMicros,
      });
    } on PlatformException catch (e) {
      throw IrTransmitException(
        _codes[e.code] ?? IrErrorCode.platform,
        e.message ?? e.code,
      );
    } on MissingPluginException catch (e) {
      throw IrTransmitException(IrErrorCode.platform, e.toString());
    }
  }

  static const _codes = {
    'NO_IR_EMITTER': IrErrorCode.noIrEmitter,
    'INVALID_ARGUMENT': IrErrorCode.invalidArgument,
    'PATTERN_TOO_LONG': IrErrorCode.patternTooLong,
    'UNSUPPORTED_FREQUENCY': IrErrorCode.unsupportedFrequency,
    'PERMISSION_DENIED': IrErrorCode.permissionDenied,
    'TRANSMIT_FAILED': IrErrorCode.transmitFailed,
  };
}
