import '../../domain/ir_frame.dart';
import 'ir_transmitter.dart';

class FakeIrTransmitter implements IrTransmitter {
  FakeIrTransmitter({
    this.hasEmitter = true,
    this.failure,
    this.delay = Duration.zero,
  });
  bool hasEmitter;
  IrTransmitException? failure;
  Duration delay;
  final List<IrFrame> sent = [];
  int active = 0, maxActive = 0;
  @override
  Future<bool> hasIrEmitter() async => hasEmitter;
  @override
  Future<List<CarrierRange>> getCarrierFrequencies() async =>
      hasEmitter ? [const CarrierRange(30000, 60000)] : [];
  @override
  Future<void> transmit(IrFrame frame) async {
    frame.validate();
    active++;
    if (active > maxActive) {
      maxActive = active;
    }
    try {
      await Future<void>.delayed(delay);
      if (!hasEmitter) {
        throw const IrTransmitException(IrErrorCode.noIrEmitter, 'No emitter');
      }
      if (failure != null) {
        throw failure!;
      }
      sent.add(frame);
    } finally {
      active--;
    }
  }
}
