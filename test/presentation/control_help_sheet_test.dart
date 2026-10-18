import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/domain/ac_enums.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';
import 'package:flutter_aircon_remote/domain/capability_overrides.dart';
import 'package:flutter_aircon_remote/presentation/pages/control_help_sheet.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('all status badges and unsupported health', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ControlHelpSheet(
            protocol: testRegistry().fallback.capabilities,
            overrides: const CapabilityOverrides(
              hiddenFeatures: {AcFeature.sleep},
            ),
            state: const AcState.initial().copyWith(mode: AcMode.fan),
          ),
        ),
      ),
    );
    expect(find.text('可用'), findsWidgets);
    await t.scrollUntilVisible(find.text('健康'), 250);
    expect(find.text('此协议不支持'), findsWidgets);
    expect(find.text('当前模式不可用'), findsWidgets);
    await t.scrollUntilVisible(find.text('已隐藏（去设置恢复）'), 100);
    expect(find.text('已隐藏（去设置恢复）'), findsOneWidget);
  });
}
