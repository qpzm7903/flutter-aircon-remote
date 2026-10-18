import 'package:flutter_test/flutter_test.dart';

import 'dart:io';

void main() {
  test('layer imports obey architecture dependencies', () {
    final imports = RegExp(r'''(?:import|export)\s+['"]([^'"]+)['"]''');
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final layer = file.path.split('/')[1];
      for (final match in imports.allMatches(file.readAsStringSync())) {
        final uri = match[1]!;
        final target = uri.startsWith('.') ? file.uri.resolve(uri).path : uri;
        void forbids(bool condition) {
          expect(condition, false, reason: '${file.path} -> $uri');
        }

        forbids(uri.startsWith('package:flutter_aircon_remote/'));
        if (target.endsWith('/legacy_v1_migrator.dart')) {
          forbids(layer != 'infrastructure');
        }
        if (file.path.endsWith('/add_device_wizard.dart')) {
          forbids(
            uri.startsWith('package:flutter') ||
                uri == 'dart:io' ||
                target.contains('/infrastructure/'),
          );
        }
        if (layer == 'domain') {
          forbids(
            uri.startsWith('package:') ||
                uri.startsWith('dart:io') ||
                [
                  'protocol',
                  'infrastructure',
                  'application',
                  'presentation',
                  'core',
                ].any((s) => target.contains('/$s/')),
          );
        }
        if (layer == 'protocol') {
          forbids(
            uri.startsWith('package:flutter') ||
                uri == 'dart:io' ||
                [
                  'infrastructure',
                  'application',
                  'presentation',
                  'core',
                ].any((s) => target.contains('/$s/')),
          );
        }
        if (layer == 'infrastructure') {
          forbids(
            [
              'protocol',
              'application',
              'presentation',
            ].any((s) => target.contains('/$s/')),
          );
        }
        if (layer == 'application') {
          forbids(
            uri == 'package:flutter/material.dart' ||
                target.contains('/presentation/'),
          );
          if (target.contains('/protocol/')) {
            forbids(
              !target.endsWith('/ac_protocol.dart') &&
                  !target.endsWith('/protocol_registry.dart'),
            );
          }
          if (target.contains('/infrastructure/')) {
            forbids(
              ![
                '/ir_transmitter.dart',
                '/remote_repository.dart',
                '/device_repository.dart',
                '/log_service.dart',
              ].any(target.endsWith),
            );
          }
        }
        if (layer == 'presentation') {
          forbids(
            target.contains('/protocol/') ||
                target.contains('/infrastructure/'),
          );
        }
      }
    }
  });
}
