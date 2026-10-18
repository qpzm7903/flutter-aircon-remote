import 'package:flutter_test/flutter_test.dart';

import 'dart:io';

import 'package:flutter_aircon_remote/core/constants.dart';

void main() {
  test('version agrees with pubspec and native channel agrees with Dart', () {
    expect(AppConstants.version, '0.2.0');
    expect(
      File('android/app/build.gradle').readAsStringSync(),
      contains("'flutter.versionName', '${AppConstants.version}'"),
    );
    expect(File('README.md').readAsStringSync(), contains('0.2.0'));
    expect(File('docs/versions/0.2.0.md').existsSync(), true);
    expect(
      File('docs/architecture.md').readAsStringSync(),
      contains('v0.2.0 变更'),
    );
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('version: ${AppConstants.version}'),
    );
    expect(
      File(
        'android/app/src/main/kotlin/com/example/flutter_aircon_remote/IrChannelHandler.kt',
      ).readAsStringSync(),
      contains('"${AppConstants.irChannelName}"'),
    );
  });
}
