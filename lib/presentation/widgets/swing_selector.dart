import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/remote_controller.dart';
import '../../domain/ac_enums.dart';
import '../strings.dart';

class SwingSelector extends StatelessWidget {
  const SwingSelector({super.key});
  @override
  Widget build(BuildContext context) {
    final data = context.select<RemoteController, (VerticalSwing, String)>(
      (c) => (c.state.verticalSwing, c.protocol.id),
    );
    final c = context.watch<RemoteController>();
    if (c.capabilities.verticalSwings.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(Strings.swing),
        Wrap(
          spacing: 8,
          children: c.capabilities.verticalSwings
              .map(
                (v) => ChoiceChip(
                  label: Text(Strings.swings[v]!),
                  selected: data.$1 == v,
                  onSelected: (_) => c.setSwing(v),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
