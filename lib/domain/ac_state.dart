import 'ac_enums.dart';

final class AcState {
  const AcState({
    this.horizontalSwing = HorizontalSwing.off,
    this.targetTempF,
    this.timerMinutes = 0,
    this.timerSetAtMs,
    this.wifiPulse = false,
    required this.power,
    required this.mode,
    required this.targetTempC,
    required this.fan,
    required this.turbo,
    required this.verticalSwing,
    required this.light,
    required this.health,
    required this.xfan,
    required this.sleep,
    required this.tempDisplay,
  });
  const AcState.initial()
    : horizontalSwing = HorizontalSwing.off,
      targetTempF = null,
      timerMinutes = 0,
      timerSetAtMs = null,
      wifiPulse = false,
      power = false,
      mode = AcMode.cool,
      targetTempC = 26,
      fan = FanSpeed.auto,
      turbo = false,
      verticalSwing = VerticalSwing.off,
      light = true,
      health = false,
      xfan = false,
      sleep = false,
      tempDisplay = TempDisplay.off;
  final HorizontalSwing horizontalSwing;
  final int? targetTempF;
  final int timerMinutes;
  final int? timerSetAtMs;
  final bool wifiPulse;
  static const _unset = Object();
  bool get useFahrenheit => targetTempF != null;
  int timerRemainingMinutes(int nowMs) =>
      timerSetAtMs == null || timerMinutes <= 0
      ? 0
      : (timerMinutes - ((nowMs - timerSetAtMs!).clamp(0, 1 << 62) / 60000))
            .ceil()
            .clamp(0, timerMinutes);
  AcState resolveTimer(int nowMs) {
    final remaining = timerRemainingMinutes(nowMs);
    return remaining <= 0
        ? copyWith(timerMinutes: 0, timerSetAtMs: null)
        : copyWith(
            timerMinutes: ((remaining + 29) ~/ 30) * 30,
            timerSetAtMs: nowMs,
          );
  }

  final bool power;
  final AcMode mode;
  final int targetTempC;
  final FanSpeed fan;
  final bool turbo;
  final VerticalSwing verticalSwing;
  final bool light;
  final bool health;
  final bool xfan;
  final bool sleep;
  final TempDisplay tempDisplay;
  AcState copyWith({
    HorizontalSwing? horizontalSwing,
    Object? targetTempF = _unset,
    int? timerMinutes,
    Object? timerSetAtMs = _unset,
    bool? wifiPulse,
    bool? power,
    AcMode? mode,
    int? targetTempC,
    FanSpeed? fan,
    bool? turbo,
    VerticalSwing? verticalSwing,
    bool? light,
    bool? health,
    bool? xfan,
    bool? sleep,
    TempDisplay? tempDisplay,
  }) => AcState(
    horizontalSwing: horizontalSwing ?? this.horizontalSwing,
    targetTempF: identical(targetTempF, _unset)
        ? this.targetTempF
        : targetTempF as int?,
    timerMinutes: timerMinutes ?? this.timerMinutes,
    timerSetAtMs: identical(timerSetAtMs, _unset)
        ? this.timerSetAtMs
        : timerSetAtMs as int?,
    wifiPulse: wifiPulse ?? this.wifiPulse,
    power: power ?? this.power,
    mode: mode ?? this.mode,
    targetTempC: targetTempC ?? this.targetTempC,
    fan: fan ?? this.fan,
    turbo: turbo ?? this.turbo,
    verticalSwing: verticalSwing ?? this.verticalSwing,
    light: light ?? this.light,
    health: health ?? this.health,
    xfan: xfan ?? this.xfan,
    sleep: sleep ?? this.sleep,
    tempDisplay: tempDisplay ?? this.tempDisplay,
  );
  Map<String, Object?> toJson() => {
    'v': 2,
    'horizontalSwing': horizontalSwing.name,
    'targetTempF': targetTempF,
    'timerMinutes': timerMinutes,
    'timerSetAtMs': timerSetAtMs,
    'power': power,
    'mode': mode.name,
    'targetTempC': targetTempC,
    'fan': fan.name,
    'turbo': turbo,
    'verticalSwing': verticalSwing.name,
    'light': light,
    'health': health,
    'xfan': xfan,
    'sleep': sleep,
    'tempDisplay': tempDisplay.name,
  };
  factory AcState.fromJson(Map<String, Object?> json) => AcState(
    horizontalSwing:
        HorizontalSwing.values
            .where((v) => v.name == json['horizontalSwing'])
            .firstOrNull ??
        HorizontalSwing.off,
    targetTempF: json['targetTempF'] is int ? json['targetTempF'] as int : null,
    timerMinutes: json['timerMinutes'] is int ? json['timerMinutes'] as int : 0,
    timerSetAtMs: json['timerSetAtMs'] is int
        ? json['timerSetAtMs'] as int
        : null,
    power: json['power'] is bool ? json['power'] as bool : false,
    mode:
        AcMode.values.where((v) => v.name == json['mode']).firstOrNull ??
        AcMode.cool,
    targetTempC: json['targetTempC'] is int ? json['targetTempC'] as int : 26,
    fan:
        FanSpeed.values.where((v) => v.name == json['fan']).firstOrNull ??
        FanSpeed.auto,
    turbo: json['turbo'] is bool ? json['turbo'] as bool : false,
    verticalSwing:
        VerticalSwing.values
            .where((v) => v.name == json['verticalSwing'])
            .firstOrNull ??
        VerticalSwing.off,
    light: json['light'] is bool ? json['light'] as bool : true,
    health: json['health'] is bool ? json['health'] as bool : false,
    xfan: json['xfan'] is bool ? json['xfan'] as bool : false,
    sleep: json['sleep'] is bool ? json['sleep'] as bool : false,
    tempDisplay:
        TempDisplay.values
            .where((v) => v.name == json['tempDisplay'])
            .firstOrNull ??
        TempDisplay.off,
  );
  @override
  bool operator ==(Object other) =>
      other is AcState &&
      horizontalSwing == other.horizontalSwing &&
      targetTempF == other.targetTempF &&
      timerMinutes == other.timerMinutes &&
      timerSetAtMs == other.timerSetAtMs &&
      wifiPulse == other.wifiPulse &&
      power == other.power &&
      mode == other.mode &&
      targetTempC == other.targetTempC &&
      fan == other.fan &&
      turbo == other.turbo &&
      verticalSwing == other.verticalSwing &&
      light == other.light &&
      health == other.health &&
      xfan == other.xfan &&
      sleep == other.sleep &&
      tempDisplay == other.tempDisplay;
  @override
  int get hashCode => Object.hash(
    horizontalSwing,
    targetTempF,
    timerMinutes,
    timerSetAtMs,
    wifiPulse,
    power,
    mode,
    targetTempC,
    fan,
    turbo,
    verticalSwing,
    light,
    health,
    xfan,
    sleep,
    tempDisplay,
  );
  @override
  String toString() => toJson().toString();
}
