import 'package:flutter/material.dart';

import '../../domain/ac_capabilities.dart';
import '../../domain/ac_state.dart';
import '../../domain/ac_enums.dart';
import '../../domain/capability_overrides.dart';
import '../../domain/capability_explainer.dart';
import '../strings.dart';

class ControlHelpSheet extends StatelessWidget {
  const ControlHelpSheet({
    required this.protocol,
    required this.overrides,
    this.state,
    super.key,
  });
  final AcCapabilities protocol;
  final CapabilityOverrides overrides;
  final AcState? state;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(Strings.helpTitle, style: Theme.of(context).textTheme.titleLarge),
        const Text(Strings.helpIntro),
        for (final e in explainControls(
          protocol: protocol,
          overrides: overrides,
          state: state,
        ))
          ListTile(
            title: Text(switch (e.item) {
              final AcMode m => '${Strings.mode} · ${Strings.modes[m]}',
              final FanSpeed f => '${Strings.fan} · ${Strings.fans[f]}',
              final VerticalSwing v =>
                '${Strings.swing} · ${Strings.swings[v]}',
              final AcFeature f => Strings.featureNames[f]!,
              _ => Strings.temperature,
            }),
            subtitle: Text(Strings.statusNames[e.status.index]),
          ),
      ],
    ),
  );
}
