import 'package:flutter_test/flutter_test.dart';

import 'dart:io';

import 'package:flutter_aircon_remote/core/constants.dart';

void main() {
  test('version agrees with pubspec and native channel agrees with Dart', () {
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
