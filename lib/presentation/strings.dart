import '../domain/ac_enums.dart';
import '../application/remote_event.dart';

abstract final class Strings {
  static const appName = '空调遥控';
  static const noIr = '此设备没有红外发射器，无法发送遥控信号';
  static const recheck = '重新检测';
  static const theme = '切换主题';
  static const diagnostics = '诊断';
  static const copy = '复制诊断信息';
  static const version = '版本';
  static const logPath = '日志路径';
  static const noLogs = '暂无日志';
  static const assumedState = '界面为假定状态，红外遥控无状态反馈';
  static const power = '电源';
  static const on = '开启';
  static const off = '关闭';
  static const decrease = '降低温度';
  static const increase = '升高温度';
  static const mode = '模式';
  static const fan = '风速';
  static const swing = '扫风';
  static const features = '功能';
  static const tempDisplay = '温度显示';
  static const modes = {
    AcMode.auto: '自动',
    AcMode.cool: '制冷',
    AcMode.dry: '除湿',
    AcMode.fan: '送风',
    AcMode.heat: '制热',
  };
  static const fans = {
    FanSpeed.auto: '自动',
    FanSpeed.low: '1',
    FanSpeed.medium: '2',
    FanSpeed.high: '3',
  };
  static const swings = {
    VerticalSwing.off: '关',
    VerticalSwing.auto: '自动',
    VerticalSwing.highest: '最上',
    VerticalSwing.high: '上',
    VerticalSwing.middle: '中',
    VerticalSwing.low: '下',
    VerticalSwing.lowest: '最下',
  };
  static const featureNames = {
    AcFeature.turbo: '强劲',
    AcFeature.light: '灯光',
    AcFeature.health: '健康',
    AcFeature.xfan: '换气',
    AcFeature.sleep: '睡眠',
    AcFeature.tempDisplay: tempDisplay,
  };
  static const displays = {
    TempDisplay.off: '关',
    TempDisplay.setpoint: '设定',
    TempDisplay.indoor: '室内',
    TempDisplay.outdoor: '室外',
  };
  static String error(IrErrorCode code) => switch (code) {
    IrErrorCode.noIrEmitter => noIr,
    IrErrorCode.invalidArgument => '红外信号参数无效',
    IrErrorCode.patternTooLong => '红外信号过长',
    IrErrorCode.unsupportedFrequency => '设备不支持此红外频率',
    IrErrorCode.permissionDenied => '红外权限被拒绝',
    IrErrorCode.transmitFailed => '红外发送失败，请重试',
    IrErrorCode.platform => '红外平台服务不可用',
  };
}
