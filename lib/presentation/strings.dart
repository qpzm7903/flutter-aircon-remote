import '../domain/ac_enums.dart';
import '../application/remote_event.dart';

abstract final class Strings {
  static const keepOne = '至少保留一个';
  static const discardQuestion = '放弃未保存的修改？';
  static const cancel = '取消';
  static const discard = '放弃';
  static const settingsTitle = '设备设置';
  static const save = '保存';
  static const basicInfo = '基本信息';
  static const name = '名称';
  static const nameInvalid = '请输入名称（1–20 个字）';
  static const room = '房间（可选）';
  static const repairPairing = '重新配对测试';
  static const visibility = '功能显示';
  static const hasSwing = '有扫风功能';
  static const dangerZone = '危险区';
  static const deleteDevice = '删除此空调';
  static const start = '开始';
  static const back = '上一步';
  static const next = '下一步';
  static const confirmBrand = '只有 Gree 时也请确认';
  static const probeWarning = '测试会让空调开机并制冷 26 °C（YX1FSF 使用节能模式）';
  static const probeIntro = '点击开始，手机会向空调发送一条“开机·制冷·26 °C”测试信号';
  static const startProbe = '开始测试';
  static const responseQuestion = '空调有响应（滴声）吗？';
  static const yesResponse = '有响应';
  static const noResponse = '没反应，试下一个';
  static const resend = '重发';
  static const exhausted = '三种型号都没有听到响应';
  static const saveAnyway = '仍然保存';
  static const restartPairing = '重新测试';
  static const skip = '跳过';
  static const deleteHelp = '仅删除本应用中的记录，不影响空调本身。';
  static const delete = '删除';
  static const discoveryQuestion = '为什么不能自动发现？';
  static const settings = '设置';
  static const maxDevices = '最多 20 台';
  static const deviceRemoved = '该空调已被删除';
  static const temperature = '温度';
  static String deleteQuestion(String name) => '删除“$name”？';
  static String added(String name) => '已添加“$name”';
  static String tempRange(int min, int max) => '温度范围 $min–$max °C';
  static String sendingProbe(String model, int index, int total) =>
      '正在发送：$model（$index/$total）…';

  static const homeTitle = '我的空调';
  static const addDevice = '添加空调';
  static const emptyTitle = '还没有添加空调';
  static const emptyBody = '红外遥控是单向的，手机无法自动发现空调。点击下方按钮添加，并对准空调做一次配对测试。';
  static const pairingIntro =
      '红外是单向的，手机无法自动发现或检测空调；请把手机顶部红外发射口对准空调接收窗（几米内、无遮挡），按提示做一次测试。';
  static const pairingTips = [
    '手机红外口通常在机身顶部，对准空调接收窗，距离几米以内，取下手机壳或遮挡。',
    '确认遥控器上有格力 Gree 标识，且空调电源已接通。',
    '部分空调可关闭提示音，请看面板指示灯是否闪。',
    '可用另一部手机相机观察发射口，部分相机可见红外灯闪烁。',
    '红外无反馈，“没反应”也可能是手机无红外或被遮挡。',
  ];
  static const pairingSuccess =
      '采用第一个有响应的型号。若之后某些按键行为不符，可在设备设置中改选其他型号或重新配对。若遥控器有“节能 Econo”模式键，请改选 YX1FSF；它与 YAW1F 的非节能帧相同，配对测试无法区分。';
  static const protocolTitle = '遥控协议型号';
  static const protocolHelp = '同一品牌的不同遥控器编码，不是不同的空调。选错可能导致部分按键无效';
  static const helpTitle = '按钮说明';
  static const helpIntro =
      '按钮由“遥控协议能做的”与“你在设置里保留的”共同决定。\n灰色表示当前模式下不可用，切模式可恢复。\n隐藏的功能发送时保持默认：灯光=亮，其余=关。';
  static const hiddenHelp = '隐藏的功能不会出现在遥控页，发送时保持默认（灯光=亮，其余=关）';
  static const statusNames = ['可用', '已隐藏（去设置恢复）', '此协议不支持', '当前模式不可用'];
  static const iconNames = ['空调', '卧室', '客厅', '书房', '厨房', '儿童房', '办公室'];
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
    AcMode.econo: '节能',
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
