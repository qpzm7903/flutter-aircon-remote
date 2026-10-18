import '../domain/ac_state.dart';
import '../domain/capability_overrides.dart';
import '../domain/ac_capabilities.dart';
import '../domain/ir_frame.dart';

abstract interface class AcProtocol {
  CapabilityOverrides get recommendedOverrides;
  String get modelNote;
  AcState get pairingProbe;
  String get id;
  String get brandId;
  String get brandName;
  String get modelName;
  AcCapabilities get capabilities;
  AcState get defaultState;
  IrFrame encode(AcState state);
}
