import '../../domain/ir_frame.dart';

import '../../domain/ir_error_code.dart';
export '../../domain/ir_error_code.dart';

class IrTransmitException implements Exception {
  const IrTransmitException(this.code, this.message);
  final IrErrorCode code;
  final String message;
  @override
  String toString() => '${code.name}: $message';
}

class CarrierRange {
  const CarrierRange(this.minHz, this.maxHz);
  final int minHz, maxHz;
}

abstract interface class IrTransmitter {
  Future<bool> hasIrEmitter();
  Future<List<CarrierRange>> getCarrierFrequencies();
  Future<void> transmit(IrFrame frame);
}
