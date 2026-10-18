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
      _ => false,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c.capabilities.isFeatureEnabled(s, AcFeature.wifi))
          ActionChip(onPressed: c.pressWifi, label: const Text('空调 Wi‑Fi')),
        if (c.capabilities.isFeatureEnabled(s, AcFeature.timer)) ...[
          ActionChip(
            label: Text(
              c.timerRemainingMinutes == null
                  ? '定时（实验） · 未设置'
                  : '定时（实验）（估算） · 约 ${c.timerRemainingMinutes! ~/ 60} 小时 ${c.timerRemainingMinutes! % 60} 分后',
            ),
            onPressed: () async {
              final minutes = await showModalBottomSheet<int>(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(Strings.timerNote),
                      ),
                      Expanded(
                        child: ListView(
                          children: [
                            for (
                              var m = 0;
                              m <= c.capabilities.maxTimerMinutes;
                              m += c.capabilities.timerStepMinutes
                            )
                              ListTile(
                                title: Text(
                                  m == 0
                                      ? '关'
                                      : m < 60
                                      ? '$m 分钟'
                                      : '${m ~/ 60} 小时${m % 60 == 0 ? '' : ' ${m % 60} 分'}',
                                ),
                                onTap: () => Navigator.pop(context, m),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
              if (minutes != null) await c.setTimer(minutes);
            },
          ),
        ],
        const Text(Strings.features),
        Wrap(
          spacing: 8,
          children: c.capabilities.features
              .where(
                (f) => {
                  AcFeature.turbo,
                  AcFeature.light,
                  AcFeature.health,
                  AcFeature.xfan,
                  AcFeature.sleep,
                }.contains(f),
              )
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
              TextButton(
                onPressed:
                    c.capabilities.isFeatureEnabled(s, AcFeature.tempDisplay)
                    ? c.cycleTempDisplay
                    : null,
                child: Text('${Strings.displays[s.tempDisplay]} · 下一档'),
              ),
            ],
          ),
      ],
    );
  }
}
