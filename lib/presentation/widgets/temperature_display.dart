import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/remote_controller.dart';
import '../../domain/ac_enums.dart';
import '../strings.dart';

class TemperatureDisplay extends StatelessWidget {
  const TemperatureDisplay({super.key});
  @override
  Widget build(BuildContext context) {
    final data = context
        .select<
          RemoteController,
          (int, bool, AcMode, FanSpeed, VerticalSwing, bool)
        >(
          (c) => (
            c.state.targetTempC,
            c.capabilities.canEditTemp(c.state),
            c.state.mode,
            c.state.fan,
            c.state.verticalSwing,
            c.state.power,
          ),
        );
    final c = context.read<RemoteController>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '${Strings.modes[data.$3]} · ${Strings.fan}${Strings.fans[data.$4]} · ${Strings.swing}${Strings.swings[data.$5]}',
            ),
            Text(data.$6 ? Strings.on : Strings.off),
            Semantics(
              liveRegion: true,
              child: Text(
                '${data.$1} °C',
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RepeatButton(
                  icon: Icons.remove,
                  label: Strings.decrease,
                  onStep: data.$2 && data.$1 > c.capabilities.minTempC
                      ? () => c.stepTemp(-1)
                      : null,
                ),
                const SizedBox(width: 40),
                _RepeatButton(
                  icon: Icons.add,
                  label: Strings.increase,
                  onStep: data.$2 && data.$1 < c.capabilities.maxTempC
                      ? () => c.stepTemp(1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RepeatButton extends StatefulWidget {
  const _RepeatButton({
    required this.icon,
    required this.label,
    required this.onStep,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onStep;
  @override
  State<_RepeatButton> createState() => _RepeatButtonState();
}

class _RepeatButtonState extends State<_RepeatButton> {
  Timer? _timer;
  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didUpdateWidget(covariant _RepeatButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onStep == null) {
      _stop();
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: widget.label,
    child: GestureDetector(
      onLongPressStart: widget.onStep == null
          ? null
          : (_) {
              widget.onStep?.call();
              _timer = Timer.periodic(
                const Duration(milliseconds: 150),
                (_) => widget.onStep?.call(),
              );
            },
      onLongPressEnd: (_) => _stop(),
      onLongPressCancel: _stop,
      child: IconButton.outlined(
        onPressed: widget.onStep,
        icon: Icon(widget.icon),
      ),
    ),
  );
}
