import '../../domain/ac_state.dart';
import '../../domain/fahrenheit_step.dart';
import '../../domain/capability_overrides.dart';
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
  @override
  String get modelNote => switch (model) {
    GreeModel.yaw1f => '常见格力遥控编码',
    GreeModel.ybofb => '另一种格力遥控编码，电源位不同',
    GreeModel.yx1fsf => '类似 YAW1F，另有“节能（Econo）”模式；Soleus Air 窗机等',
  };
  @override
  AcState get pairingProbe => capabilities.normalize(
    defaultState.copyWith(
      power: true,
      mode: model == GreeModel.yx1fsf ? AcMode.econo : AcMode.cool,
    ),
  );
  @override
  CapabilityOverrides get recommendedOverrides => CapabilityOverrides(
    hiddenFeatures: {
      AcFeature.swingH,
      AcFeature.wifi,
      AcFeature.timer,
      if (model != GreeModel.yx1fsf) AcFeature.fahrenheit,
    },
    hiddenSwings: {
      VerticalSwing.autoDown,
      VerticalSwing.autoMiddle,
      VerticalSwing.autoUp,
    },
  );
  static const common = {
    AcFeature.light,
    AcFeature.tempDisplay,
    AcFeature.swingH,
    AcFeature.wifi,
    AcFeature.timer,
    AcFeature.fahrenheit,
  };
  @override
  AcCapabilities get capabilities => AcCapabilities(
    horizontalSwings: HorizontalSwing.values,
    fahrenheitSteps: [
      for (final r in greeFahrenheitTable) FahrenheitStep(r.f, r.c),
    ],
    timerStepMinutes: 30,
    maxTimerMinutes: 1440,
    minTempC: 16,
    maxTempC: 30,
    modes: model == GreeModel.yx1fsf
        ? AcMode.values
        : AcMode.values.take(5).toList(),
    fanSpeeds: FanSpeed.values,
    verticalSwings: VerticalSwing.values,
    tempDisplays: TempDisplay.values,
    features: {
      ...common,
      AcFeature.turbo,
      AcFeature.light,
      AcFeature.xfan,
      AcFeature.sleep,
      AcFeature.tempDisplay,
    },
    modeRules: {
      AcMode.econo: const ModeRule(allowedFeatures: common),
      AcMode.auto: const ModeRule(
        fixedTempC: 25,
        allowedFeatures: {...common, AcFeature.sleep},
      ),
      AcMode.cool: const ModeRule(
        allowedFeatures: {
          ...common,
          AcFeature.turbo,
          AcFeature.xfan,
          AcFeature.sleep,
        },
      ),
      AcMode.dry: const ModeRule(
        fixedFan: FanSpeed.low,
        allowedFeatures: {...common, AcFeature.xfan, AcFeature.sleep},
      ),
      AcMode.fan: const ModeRule(tempEditable: false, allowedFeatures: common),
      AcMode.heat: const ModeRule(
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
