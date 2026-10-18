import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/remote_controller.dart';
import '../../domain/ac_enums.dart';
import '../strings.dart';

class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key});
  @override
  Widget build(BuildContext context) {
    final selected = context.select<RemoteController, (AcMode, String)>(
      (c) => (c.state.mode, c.protocol.id),
    );
    final c = context.watch<RemoteController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(Strings.mode),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<AcMode>(
            showSelectedIcon: false,
            segments: c.capabilities.modes
                .map(
                  (v) => ButtonSegment(
                    value: v,
                    label: Text(Strings.modes[v]!),
                    icon: v == AcMode.econo ? const Icon(Icons.eco) : null,
                  ),
                )
                .toList(),
            selected: {selected.$1},
            onSelectionChanged: (s) => c.setMode(s.first),
          ),
        ),
      ],
    );
  }
}
