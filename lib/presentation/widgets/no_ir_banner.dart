import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/remote_controller.dart';
import '../strings.dart';

class NoIrBanner extends StatelessWidget {
  const NoIrBanner({super.key});
  @override
  Widget build(BuildContext context) => MaterialBanner(
    content: const Text(Strings.noIr),
    backgroundColor: Theme.of(context).colorScheme.errorContainer,
    actions: [
      TextButton(
        onPressed: context.read<RemoteController>().recheckIr,
        child: const Text(Strings.recheck),
      ),
    ],
  );
}
