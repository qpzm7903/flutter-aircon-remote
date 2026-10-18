import '../domain/ac_state.dart';
import '../domain/ac_capabilities.dart';
import '../domain/ir_frame.dart';

abstract interface class AcProtocol {
  String get id;
  String get brandId;
  String get brandName;
  String get modelName;
  AcCapabilities get capabilities;
  AcState get defaultState;
  IrFrame encode(AcState state);
}
