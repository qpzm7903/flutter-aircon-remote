import '../infrastructure/ir/ir_transmitter.dart';
export '../infrastructure/ir/ir_transmitter.dart' show IrErrorCode;

sealed class RemoteEvent {}

final class TransmitSucceeded extends RemoteEvent {
  TransmitSucceeded({this.wifiPulse = false});
  final bool wifiPulse;
}

final class TransmitFailed extends RemoteEvent {
  TransmitFailed(this.code, this.message);
  final IrErrorCode code;
  final String message;
}

final class DeviceRemoved extends RemoteEvent {}
