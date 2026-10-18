import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../application/remote_controller.dart';
import '../../application/remote_event.dart';
import '../../application/theme_controller.dart';
import '../strings.dart';
import 'diagnostics_sheet.dart';
import '../widgets/brand_selector.dart';
import '../widgets/no_ir_banner.dart';
import '../widgets/power_button.dart';
import '../widgets/temperature_display.dart';
import '../widgets/mode_selector.dart';
import '../widgets/fan_selector.dart';
import '../widgets/swing_selector.dart';
import '../widgets/feature_toggles.dart';

class RemotePage extends StatefulWidget {
  const RemotePage({super.key});
  @override
  State<RemotePage> createState() => _RemotePageState();
}

class _RemotePageState extends State<RemotePage> {
  StreamSubscription<RemoteEvent>? _subscription;
  @override
  void initState() {
    super.initState();
    _subscription = context.read<RemoteController>().events.listen((event) {
      if (!mounted) {
        return;
      }
      if (event is TransmitSucceeded) {
        unawaited(HapticFeedback.lightImpact());
      }
      if (event is TransmitFailed) {
        unawaited(HapticFeedback.heavyImpact());
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(Strings.error(event.code))));
      }
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availability = context.select<RemoteController, IrAvailability>(
      (c) => c.irAvailability,
    );
    final theme = context.select<ThemeController, String>((c) => c.modeName);
    final sending = context.select<RemoteController, bool>((c) => c.isSending);
    return Scaffold(
      appBar: AppBar(
        title: const BrandSelector(),
        actions: [
          IconButton(
            tooltip: Strings.theme,
            onPressed: context.read<ThemeController>().cycle,
            icon: Icon(switch (theme) {
              'light' => Icons.light_mode,
              'dark' => Icons.dark_mode,
              _ => Icons.brightness_auto,
            }),
          ),
          IconButton(
            tooltip: Strings.diagnostics,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<RemoteController>(),
                child: const DiagnosticsSheet(),
              ),
            ),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (availability == IrAvailability.unknown || sending)
              const LinearProgressIndicator(),
            if (availability == IrAvailability.unavailable) const NoIrBanner(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        IgnorePointer(
                          ignoring: availability == IrAvailability.unavailable,
                          child: Opacity(
                            opacity: availability == IrAvailability.unavailable
                                ? .4
                                : 1,
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TemperatureDisplay(),
                                SizedBox(height: 16),
                                PowerButton(),
                                SizedBox(height: 24),
                                ModeSelector(),
                                SizedBox(height: 20),
                                FanSelector(),
                                SizedBox(height: 20),
                                SwingSelector(),
                                SizedBox(height: 20),
                                FeatureToggles(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          Strings.assumedState,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
