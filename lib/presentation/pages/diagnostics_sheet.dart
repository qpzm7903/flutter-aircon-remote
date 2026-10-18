import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../application/diagnostics_controller.dart';
import '../../core/constants.dart';
import '../strings.dart';

class DiagnosticsSheet extends StatelessWidget {
  const DiagnosticsSheet({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.read<DiagnosticsController>();
    final text =
        '${Strings.version}: ${AppConstants.version}\n${Strings.logPath}: ${c.logFilePath()}\n\n${c.logSnapshot().join('\n')}';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      Strings.diagnostics,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: Strings.copy,
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: text)),
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(child: SelectableText(text)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
