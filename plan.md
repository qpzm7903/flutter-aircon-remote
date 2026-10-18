# 空调遥控 — 项目规划

## 长期目标

保持领域、协议、基础设施、应用与表现分层；通过协议注册扩展更多空调品牌。

## v0.1.0

- [x] M0：Flutter / Android 工程骨架、Groovy 构建、签名回退、Android CI。
- [x] M1：不可变状态、容错 JSON、能力约束与红外帧验证。
- [x] M2：Gree YAW1F / YBOFB 编码器、校验和、脉冲、已知向量测试。
- [x] M3：平台通道、模拟发送器、SharedPreferences、按日日志。
- [x] M4：Kotlin ConsumerIrManager 单线程发送与主线程回调。
- [x] M5：控制器、持久化、发送串行合并、一次性事件与主题。
- [x] M6：中文 Material 3 单页、长按调温、能力驱动控件、无红外提示、诊断。
- [x] M7：本地 analyze / test / release APK 验收。

## v0.2.0（已实现；详见 docs/versions/0.2.0.md 与 architecture §12–§19）

- [x] M8：领域——`AcMode.econo`、`AcDevice`、`CapabilityOverrides`、`restrictedBy` 与中性值归一化、`explainControls`。
- [x] M9：协议——Gree YX1FSF、按变体能力声明、`pairingProbe` / `modelNote`、新向量、registry 三变体。
- [x] M10：基础设施——`DeviceRepository`（schema v2）、`LegacyV1Migrator`、`RemoteRepository` 缩减为主题。
- [x] M11：应用层——`DeviceListController`、每设备 `RemoteController`、`RemoteSessionFactory`、`DeviceSettingsController`、`AddDeviceWizard` 状态机与控制器、`DiagnosticsController`。
- [x] M12：表现层——首页列表（空状态/增删改/排序）、添加空调向导、设备设置、按钮说明、遥控页去掉协议下拉。
- [x] M13：收尾——版本 0.2.0（pubspec / 常量 / README / version_test）、架构测试更新、analyze / test / release APK 验收。

## v0.3.0（已实现；详见 docs/versions/0.3.0.md 与 architecture §20–§26）

范围：Gree 水平扫风（按设备可隐藏，默认隐藏）+ 协议缺口补全（局部垂直扫风、华氏度、定时、Wi‑Fi 一次性键、温度显示循环顺序），schema v3 迁移。仍只做 Gree。跳过：I‑Feel、Econo 位、health。

- [x] M14：领域——新枚举（`HorizontalSwing`、`VerticalSwing` 局部扫风、`AcFeature.swingH/wifi/timer/fahrenheit`）、`FahrenheitStep`、`AcState` 新字段与 `resolveTimer`、`AcCapabilities` 新字段/`normalize`、`CapabilityOverrides.hiddenHSwings`、explainer。
- [x] M15：协议——原生值显式表、华氏表、codec 新字段、能力声明、`recommendedOverrides`、reference + derived 向量。
- [x] M16：基础设施——`DeviceSchemaV3Migrator`、仓库串联、schema=3。
- [x] M17：应用层——`RemoteController`（时钟、定时折算、wifiPulse 一次性、华氏、`cycleTempDisplay`）、`DeviceListController.add(overrides)`、设置控制器、向导种子。
- [x] M18：表现层——水平扫风行、℃/℉、定时、Wi‑Fi 按钮、温度显示「下一档」、设置页与按钮说明、字符串。
- [x] M19：收尾——版本 0.3.0（pubspec、`AppConstants.version`、`android/app/build.gradle`、`version_test`、`home_page_test`、README 当前版本）、架构测试、analyze / test / release APK 验收、真机回填。

说明：M14–M19 已实现，版本统一为 0.3.0；真机回填仍列为待验证，不以模拟发送代替。

## 本地验收结果（2026-10-18）

- `flutter pub get` 成功。
- `flutter analyze`：No issues found，零错误、警告与 info。
- `flutter test`：67 个测试全部通过。
- `flutter build apk --release --target-platform android-arm64` 成功，APK 约 26.6 MB。
- 解包确认仅 `lib/arm64-v8a/`；aapt 确认包名、版本 0.1.0、minSdk 35、targetSdk 37、中文应用名、TRANSMIT_IR 与可选 consumerir 特性。
- 仓库内无签名密钥/口令；架构文档保持原样，未提交或推送。

## 待设备与托管环境验证

- 带红外真机控制空调、OEM 频率与权限行为、真实触觉、冷启动恢复。
- GitHub push/PR 构建与 v* 标签发布（本次按要求不提交、不推送）。

## 实现偏差

1. 架构 §5.6 的 `heat-indoor` 原始向量 `4C 04 60 50 01 02 00 A0` 与 §5.3 的 byte5 保留位固定 `0x20` 不兼容。保留上游原始向量及解码、校验和、脉冲测试；编码遵守统一保留位，输出 `4C 04 60 50 01 22 00 C0` 并另设明确断言。没有为特定状态臆造编码特例，也没有改变领域模型。
2. §5.6 “翻转任一数据位校验失败”对 Kelvinator 半字节校验不成立；仅断言被公式覆盖的数据位及校验位翻转失败，保留上游校验公式。
3. 按用户最新要求本地执行全部验收（覆盖文档中“仅 CI 执行”），CI artifact 保留 7 天，Gradle 使用官方 services.gradle.org 分发地址。
4. §2 的泛化依赖限制与 §3/§10 明确接口存在冲突：core 常量由基础设施及诊断使用；应用按指定静态门面调用 LogService；协议注册器及协议层共享工具在本层复用。架构测试允许这些文档明确要求的依赖，仍禁止跨层具体协议、存储、发送器实现依赖。
5. Flutter 3.47.7 Gradle 插件会覆盖 defaultConfig 的 ABI 集合，导致传递 JNI 库仍打入其他架构。增加官方插件属性 `disable-abi-filtering=true`，让 app 中的 `arm64-v8a` 过滤生效；保持用户指定构建命令不变。

## v0.2.0 实现偏差

1. §13 的纯状态机需要 `IrErrorCode`，而 §18 禁止状态机导入任何 infrastructure 文件；原枚举定义在基础设施接口中。将枚举独立到 `domain/ir_error_code.dart`，原 `ir_transmitter.dart` 重新导出，保持既有调用兼容；状态机直接依赖领域枚举，未放宽架构规则。
2. Flutter 3.47.7 已弃用 `ReorderableListView.onReorder`。为满足 analyze 零问题，表现层使用 `onReorderItem`，适配其已调整的新索引，再调用设计指定语义的 `DeviceListController.reorder`；排序行为不变，widget 测试调用新回调。
3. 按 §17.1/§17.3：上游 YX1FSF 华氏抓包 `1D 09 60 58 00 20 00 A0` 只验证解码与校验和；本项目仅编码摄氏等价 `1D 09 60 50 00 20 00 20`，关机向量明确标为推导。沿用 v0.1 heat-indoor 保留位偏差，不新增编码特例。
4. 协议固定风速可以落在用户隐藏的风速之外（§12.3 明确固定值优先）。此时风速分段控件保持禁用、无选中可见档位，避免 Flutter 对“不在选项中的选中值”的断言；实际状态及发送仍为协议强制低风。已有 widget 回归测试。

## v0.2.0 本地验收（2026-10-18）

- `flutter pub get`：成功。
- `flutter analyze`：零问题。
- `flutter test`：135 个测试全部通过，包含 §18 新增/修改的全部测试文件与既有协议、平台通道测试。
- `flutter build apk --release --target-platform android-arm64`：成功，APK 约 27.4 MB，路径 `build/app/outputs/flutter-apk/app-release.apk`；解包确认仅 arm64-v8a，aapt 确认版本 0.2.0、minSdk 35、targetSdk 37。
- CI 已有 pub get → analyze → test → arm64 release APK 门禁，沿用并核对，无需改动工作流。
- 真机红外与实际空调响应仍需带红外的 Android 手机验证；没有把模拟发送当作真机验收。
- 未提交、未推送；未修改 prompt.md 或新增版本说明文件。


## v0.3.0 实现偏差

1. 沿用既有 application 控制器的 `ChangeNotifier` / Flutter foundation 依赖；§25 的“不 import Flutter”与原有控制器基类及 §23 的 notify 管线冲突，继续允许 foundation，未引入 material 或表现层依赖。
2. 新增领域与遥控 widget 回归部分集中于 `test/domain/v3_state_test.dart` 与 `test/presentation/v3_remote_test.dart`，与既有测试共同覆盖 §26 清单，不改变行为。
3. 真机红外与实际空调反应无法在当前环境验证，M19 的本地验收完成，真机回填保留为待办。
4. §10.1 的 I‑Feel 原帧 `08 09 60 50 00 44 00 F0` 同时含 Wi‑Fi 位（0x40）。按 §22.2 解码保留 `wifiPulse=true` 后直接重编码 byte5 应为 `0x60`，不是表中写的 `0x20`；测试分别断言直接重编码 `0x60`、清除一次性 Wi‑Fi 标记后 `0x20`，两者 I‑Feel 位均为 0。保留上游原始帧，不人为修改参考向量。

## v0.3.0 协议核对

- 对照 `/workspace/refs/irremote/ir_Gree.h` 联合体、`ir_Gree.cpp` 的 setTemp / setTimer / 扫风映射、`ir_Gree_test.cpp` reference 帧与 `IRsend.h`；Gree only。
- 按 `ir_Kelvinator.cpp::calcBlockChecksum` 原公式独立核对版本说明中的 29 处完整八字节帧（含重复出现的参考帧）：全部校验和正确，无需更正设计的派生帧算术。全部新增 reference / derived 编码向量与 reference-decode 向量均由测试验证。
- 华氏 70、79 两行遵循设计的显示往返修正；61 行保持 (16,0)，不由显示公式反推 extra；YX1FSF ModelA 与 unknown2 沿用既有实测/规范决策。
- `wifiPulse` 仅在控制器内存与单帧存活；JSON 与设备列表缓存均不保留。迁移失败时重载 SharedPreferences 缓存，使同进程重试与重启均安全。


## v0.3.0 本地验收（2026-10-18）

- `flutter pub get`：成功。
- `flutter analyze`：No issues found，零问题。
- `flutter test`：228 个测试全部通过（包含 v0.2 回归、全部新增帧向量、华氏 26 行、迁移失败重试、覆盖/归一化、控制器与 widget）。
- `flutter build apk --release --target-platform android-arm64`：成功，APK 27,428,073 字节（约 27.4 MB），路径 `build/app/outputs/flutter-apk/app-release.apk`。
- aapt 确认 versionName=0.3.0、minSdk=35、targetSdk=37；解包仅含 `lib/arm64-v8a/`。
- README 与架构/版本文档已同步实现状态及 foundation 允许规则；所有实现偏差及协议核对记录在上述专节。无新增品牌，未提交、未推送。
