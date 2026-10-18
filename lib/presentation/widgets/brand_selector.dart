import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/remote_controller.dart';

class BrandSelector extends StatelessWidget {
  const BrandSelector({super.key});
  @override
  Widget build(BuildContext context) {
    final id = context.select<RemoteController, String>((c) => c.protocol.id);
    final c = context.read<RemoteController>();
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: id,
        items: c.registry.all
            .map(
              (p) => DropdownMenuItem(
                value: p.id,
                child: Text(
                  '${p.brandName} / ${p.modelName}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (id) {
          if (id != null) {
            c.setProtocol(id);
          }
        },
      ),
    );
  }
}
