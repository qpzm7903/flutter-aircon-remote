import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/remote_controller.dart';
import '../strings.dart';

class PowerButton extends StatelessWidget {
  const PowerButton({super.key});
  @override
  Widget build(BuildContext context) {
    final power = context.select<RemoteController, bool>((c) => c.state.power);
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Semantics(
        toggled: power,
        label: Strings.power,
        child: IconButton.filled(
          tooltip: '${Strings.power} · ${power ? Strings.on : Strings.off}',
          iconSize: 40,
          padding: const EdgeInsets.all(24),
          style: IconButton.styleFrom(
            backgroundColor: power
                ? colors.primary
                : colors.surfaceContainerHighest,
            foregroundColor: power ? colors.onPrimary : colors.onSurfaceVariant,
          ),
          onPressed: context.read<RemoteController>().togglePower,
          icon: const Icon(Icons.power_settings_new),
        ),
      ),
    );
  }
}
