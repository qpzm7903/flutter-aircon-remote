import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/remote_controller.dart';
import '../../domain/ac_enums.dart';
import '../strings.dart';

class HorizontalSwingSelector extends StatelessWidget {
  const HorizontalSwingSelector({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.watch<RemoteController>();
    if (!c.capabilities.features.contains(AcFeature.swingH) ||
        c.capabilities.horizontalSwings.length <= 1) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(Strings.horizontalSwing),
        Wrap(
          spacing: 8,
          children: [
            for (final h in c.capabilities.horizontalSwings)
              ChoiceChip(
                label: Text(Strings.hSwings[h]!),
                selected: c.state.horizontalSwing == h,
                onSelected:
                    c.capabilities.isFeatureEnabled(c.state, AcFeature.swingH)
                    ? (_) => c.setHorizontalSwing(h)
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
