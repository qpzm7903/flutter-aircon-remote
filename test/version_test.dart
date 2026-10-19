import 'package:flutter_test/flutter_test.dart';

import 'dart:io';

import 'package:flutter_aircon_remote/core/constants.dart';

void main() {
  test('version agrees with pubspec and native channel agrees with Dart', () {
    expect(AppConstants.version, '0.3.1');
    expect(
      File('android/app/build.gradle').readAsStringSync(),
      contains("'flutter.versionName', '${AppConstants.version}'"),
    );
    final readme = File('README.md').readAsStringSync();
    expect(readme, contains('**v0.3.1 已实现**'));
    expect(readme, isNot(contains('尚未实现')));
    expect(readme, isNot(contains('0.2.0 不支持')));
    expect(readme, isNot(contains('版本说明（设计）')));
    expect(File('docs/versions/0.3.1.md').existsSync(), true);
    expect(
      File('docs/architecture.md').readAsStringSync(),
      contains('v0.3.1 变更'),
    );
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version: (\S+)$',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1)!.split('+');
    expect(version.first, AppConstants.version);
    final buildNumber = int.parse(version[1]);
    expect(buildNumber, 301);
    expect(buildNumber, greaterThan(1));
    expect(
      File('android/app/build.gradle').readAsStringSync(),
      contains("'flutter.versionCode', '$buildNumber'"),
    );
    expect(
      File(
        'android/app/src/main/kotlin/com/example/flutter_aircon_remote/IrChannelHandler.kt',
      ).readAsStringSync(),
      contains('"${AppConstants.irChannelName}"'),
    );
  });
}
