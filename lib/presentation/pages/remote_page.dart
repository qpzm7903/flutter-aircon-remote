import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../application/remote_controller.dart';
import '../../application/remote_event.dart';
import '../strings.dart';
import 'device_settings_page.dart';
import 'control_help_sheet.dart';
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
      if (event is DeviceRemoved) {
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(Strings.deviceRemoved)));
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
    final sending = context.select<RemoteController, bool>((c) => c.isSending);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.watch<RemoteController>().title),
        actions: [
          IconButton(
            tooltip: Strings.helpTitle,
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              final c = context.read<RemoteController>();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => ControlHelpSheet(
                  protocol: c.protocol.capabilities,
                  overrides: c.device.overrides,
                  state: c.state,
                ),
              );
            },
          ),
          IconButton(
            tooltip: Strings.settingsTitle,
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => DeviceSettingsPage(
                  deviceId: context.read<RemoteController>().deviceId,
                ),
              ),
            ),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const TemperatureDisplay(),
                                const SizedBox(height: 16),
                                const PowerButton(),
                                const SizedBox(height: 24),
                                if (context
                                        .watch<RemoteController>()
                                        .capabilities
                                        .modes
                                        .length >
                                    1)
                                  const ModeSelector(),
                                const SizedBox(height: 20),
                                if (context
                                        .watch<RemoteController>()
                                        .capabilities
                                        .fanSpeeds
                                        .length >
                                    1)
                                  const FanSelector(),
                                const SizedBox(height: 20),
                                if (context
                                        .watch<RemoteController>()
                                        .capabilities
                                        .verticalSwings
                                        .length >
                                    1)
                                  const SwingSelector(),
                                const SizedBox(height: 20),
                                const FeatureToggles(),
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
