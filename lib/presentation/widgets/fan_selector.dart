import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/remote_controller.dart';
import '../../domain/ac_enums.dart';
import '../strings.dart';

class FanSelector extends StatelessWidget {
  const FanSelector({super.key});
  @override
  Widget build(BuildContext context) {
    final selected = context.select<RemoteController, (FanSpeed, String)>(
      (c) => (c.state.fan, c.protocol.id),
    );
    final c = context.watch<RemoteController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(Strings.fan),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<FanSpeed>(
            showSelectedIcon: false,
            segments: c.capabilities.fanSpeeds
                .map(
                  (v) => ButtonSegment(value: v, label: Text(Strings.fans[v]!)),
                )
                .toList(),
            emptySelectionAllowed: true,
            selected: c.capabilities.fanSpeeds.contains(selected.$1)
                ? {selected.$1}
                : {},
            onSelectionChanged: c.capabilities.canEditFan(c.state)
                ? (s) => c.setFan(s.first)
                : null,
          ),
        ),
      ],
    );
  }
}
