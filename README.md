# 空调遥控

Android 手机内置红外遥控器，当前版本 **0.1.0**。

## 功能

- 电源、自动 / 制冷 / 除湿 / 送风 / 制热，16–30 °C 温度调节，长按每 150 ms 连续调温。
- 自动与三级风速、垂直扫风及固定位置、强劲、灯光、换气/防霉、睡眠与温度显示。
- 每次有效状态变化发送完整红外帧；快速操作合并为最新状态，发送不重叠。
- 每个型号独立保存状态；启动恢复状态但不发送。支持系统 / 浅色 / 深色主题。
- 无红外发射器时提示并禁用遥控操作，主题、型号和诊断仍可使用。
- 诊断页查看与复制日志，日志按日保存并保留七天。

## 支持的品牌与协议

目前支持 **格力 Gree YAW1F、YBOFB**，38 kHz、8 字节有状态协议。不同型号仅 ModelA 位不同。不是所有格力空调均兼容，请按实际机型试用。健康/负离子位缺乏验证，当前不提供；不支持定时、华氏度、水平扫风、Wi-Fi、I-Feel、红外学习或外接发射器。

需要 Android 15（API 35）或更高的 arm64 手机及内置红外发射器。目标 API 37。应用仅请求普通权限 `TRANSMIT_IR`，不需运行时授权；无红外手机也可安装。红外没有反馈，界面显示假定状态，请将手机发射器对准空调。自动模式锁温 25 °C，除湿锁低风，送风禁用调温；切换模式时不兼容的功能会关闭，切回不会恢复。

## 下载 APK

在本仓库 **Actions → Build and Release → 成功的运行 → Artifacts** 下载 `*-android-aarch64.apk` 压缩包并解压安装（需要登录 GitHub，产物保留 7 天）。也可打开仓库 **Releases**，从 `v*` 版本附件下载 APK；预发布版本会标记 prerelease。首次安装需要允许浏览器或文件管理器安装未知来源应用。

## 构建方式

环境：Flutter 3.47.7 / Dart 3.13.5、JDK 21、Android SDK 37、NDK 30.0.16248370。项目采用 Groovy、AGP 9.2.1、Kotlin 2.3.21、Gradle 9.5.1。

```bash
export PATH=/home/box/sdk/flutter/bin:$PATH
export ANDROID_HOME=/home/box/sdk/android
flutter pub get
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64
```

输出：`build/app/outputs/flutter-apk/app-release.apk`。可用 `flutter run --dart-define=FAKE_IR=true` 在无红外设备上演示（模拟发送，不会控制空调）。可选 `USE_ALIYUN_MAVEN=true` 启用参考项目的 Maven 镜像。

默认 release 使用 Android 自动生成的 debug 签名。正式签名可在本地创建被忽略的 `android/key.properties`，包含 `storeFile`（相对 `android/app`）、`storePassword`、`keyAlias`、`keyPassword`；禁止提交密钥和口令。CI 可配置可选 secrets：`ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD`。使用不同签名安装时可能需要先卸载旧包（会清除状态）。

## 架构与版本

见 [架构设计](docs/architecture.md)、[开发规划及实现偏差](plan.md)、[0.1.0 版本说明](docs/versions/0.1.0.md)。纯 Dart 领域及协议层通过已知字节向量验证；新增品牌只需新增协议实现并在 `main.dart` 注册。

## 协议参考与致谢

协议位域、校验和、时序和测试向量参考 [IRremoteESP8266](https://github.com/crankyoldgit/IRremoteESP8266) 的 `ir_Gree.h`、`ir_Gree.cpp`、`ir_Gree_test.cpp` 和 `ir_Kelvinator.cpp`。感谢上游贡献者；本项目为独立 Dart 实现，测试数据出处见 `test/support/gree_vectors.dart`。

## 许可

[MIT](LICENSE)，Copyright (c) 2026 qpzm7903。
