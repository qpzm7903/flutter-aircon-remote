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
