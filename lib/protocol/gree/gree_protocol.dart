import '../../domain/ac_state.dart';
import '../../domain/ac_enums.dart';
import '../../domain/ac_capabilities.dart';
import '../../domain/ir_frame.dart';
import '../ac_protocol.dart';
import 'gree_constants.dart';
import 'gree_state_codec.dart';
import 'gree_pulse_builder.dart';

class GreeProtocol implements AcProtocol {
  GreeProtocol(this.model);
  final GreeModel model;
  @override
  String get id => 'gree.${model.name}';
  @override
  String get brandId => 'gree';
  @override
  String get brandName => '格力 Gree';
  @override
  String get modelName => model.name.toUpperCase();
  static const common = {AcFeature.light, AcFeature.tempDisplay};
  @override
  final capabilities = const AcCapabilities(
    minTempC: 16,
    maxTempC: 30,
    modes: AcMode.values,
    fanSpeeds: FanSpeed.values,
    verticalSwings: VerticalSwing.values,
    tempDisplays: TempDisplay.values,
    features: {
      AcFeature.turbo,
      AcFeature.light,
      AcFeature.xfan,
      AcFeature.sleep,
      AcFeature.tempDisplay,
    },
    modeRules: {
      AcMode.auto: ModeRule(
        fixedTempC: 25,
        allowedFeatures: {...common, AcFeature.sleep},
      ),
      AcMode.cool: ModeRule(
        allowedFeatures: {
          ...common,
          AcFeature.turbo,
          AcFeature.xfan,
          AcFeature.sleep,
        },
      ),
      AcMode.dry: ModeRule(
        fixedFan: FanSpeed.low,
        allowedFeatures: {...common, AcFeature.xfan, AcFeature.sleep},
      ),
      AcMode.fan: ModeRule(tempEditable: false, allowedFeatures: common),
      AcMode.heat: ModeRule(
        allowedFeatures: {...common, AcFeature.turbo, AcFeature.sleep},
      ),
    },
  );
  @override
  AcState get defaultState => capabilities.normalize(const AcState.initial());
  @override
  IrFrame encode(AcState state) {
    final bytes = GreeStateCodec(model).encode(capabilities.normalize(state));
    return IrFrame(
      carrierHz: GreeConstants.carrierHz,
      patternMicros: List.unmodifiable(const GreePulseBuilder().build(bytes)),
      debugHex: bytes
          .map((v) => v.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' '),
    )..validate();
  }
}
