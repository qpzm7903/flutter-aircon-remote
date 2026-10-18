import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/remote_controller.dart';
import '../../domain/ac_enums.dart';
import '../strings.dart';

class FeatureToggles extends StatelessWidget {
  const FeatureToggles({super.key});
  @override
  Widget build(BuildContext context) {
    final data = context.select(
      (RemoteController c) => (c.state, c.protocol.id),
    );
    final c = context.watch<RemoteController>();
    final s = data.$1;
    bool selected(AcFeature f) => switch (f) {
      AcFeature.turbo => s.turbo,
      AcFeature.light => s.light,
      AcFeature.health => s.health,
      AcFeature.xfan => s.xfan,
      AcFeature.sleep => s.sleep,
      AcFeature.tempDisplay => false,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(Strings.features),
        Wrap(
          spacing: 8,
          children: c.capabilities.features
              .where((f) => f != AcFeature.tempDisplay)
              .map(
                (f) => FilterChip(
                  label: Text(Strings.featureNames[f]!),
                  selected: selected(f),
                  onSelected: c.capabilities.isFeatureEnabled(s, f)
                      ? (_) => c.toggleFeature(f)
                      : null,
                ),
              )
              .toList(),
        ),
        if (c.capabilities.features.contains(AcFeature.tempDisplay) &&
            c.capabilities.tempDisplays.length > 1)
          Row(
            children: [
              const Text(Strings.tempDisplay),
              const SizedBox(width: 16),
              DropdownButton<TempDisplay>(
                value: s.tempDisplay,
                items: c.capabilities.tempDisplays
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(Strings.displays[d]!),
                      ),
                    )
                    .toList(),
                onChanged:
                    c.capabilities.isFeatureEnabled(s, AcFeature.tempDisplay)
                    ? (d) {
                        if (d != null) {
                          c.setTempDisplay(d);
                        }
                      }
                    : null,
              ),
            ],
          ),
      ],
    );
  }
}
