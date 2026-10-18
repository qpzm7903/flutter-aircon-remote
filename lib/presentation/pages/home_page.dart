import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/device_list_controller.dart';
import '../../application/remote_session_factory.dart';
import '../../application/theme_controller.dart';
import '../../domain/ac_device.dart';
import '../strings.dart';
import 'remote_page.dart';
import 'add_device_page.dart';
import 'device_settings_page.dart';
import 'diagnostics_sheet.dart';

const deviceIcons = [
  Icons.ac_unit,
  Icons.bed,
  Icons.weekend,
  Icons.menu_book,
  Icons.kitchen,
  Icons.child_care,
  Icons.work,
];
Future<bool> confirmDelete(BuildContext context, AcDevice d) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Strings.deleteQuestion(d.name)),
        content: const Text(Strings.deleteHelp),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(Strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(Strings.delete),
          ),
        ],
      ),
    ) ??
    false;

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.watch<DeviceListController>();
    final factory = context.read<RemoteSessionFactory>();
    void add() => Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const AddDevicePage()),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.homeTitle),
        actions: [
          IconButton(
            tooltip: Strings.theme,
            onPressed: context.read<ThemeController>().cycle,
            icon: const Icon(Icons.brightness_6),
          ),
          IconButton(
            tooltip: Strings.diagnostics,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const DiagnosticsSheet(),
            ),
            icon: const Icon(Icons.receipt_long),
          ),
          IconButton(
            tooltip: Strings.discoveryQuestion,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AlertDialog(
                title: Text(Strings.discoveryQuestion),
                content: Text(Strings.pairingIntro),
              ),
            ),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: !c.loaded
          ? const Center(child: CircularProgressIndicator())
          : c.devices.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.ac_unit, size: 64),
                    const Text(Strings.emptyTitle),
                    const Text(Strings.emptyBody),
                    FilledButton(
                      onPressed: add,
                      child: const Text(Strings.addDevice),
                    ),
                  ],
                ),
              ),
            )
          : ReorderableListView(
              onReorderItem: (oldIndex, newIndex) => c.reorder(
                oldIndex,
                newIndex > oldIndex ? newIndex + 1 : newIndex,
              ),
              children: [
                for (final d in c.devices)
                  ListTile(
                    key: ValueKey(d.id),
                    leading: Icon(deviceIcons[d.icon.index]),
                    title: Text(d.name),
                    subtitle: Text(factory.subtitle(d)),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ChangeNotifierProvider(
                          create: (_) => factory.create(d.id)..init(),
                          child: const RemotePage(),
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'settings') {
                              await Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      DeviceSettingsPage(deviceId: d.id),
                                ),
                              );
                            } else if (await confirmDelete(context, d)) {
                              await c.remove(d.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'settings',
                              child: Text(Strings.settings),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(Strings.delete),
                            ),
                          ],
                        ),
                        ReorderableDragStartListener(
                          index: c.devices.indexOf(d),
                          child: const Icon(Icons.drag_handle),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
      floatingActionButton: Tooltip(
        message: c.isFull ? Strings.maxDevices : Strings.addDevice,
        child: FloatingActionButton.extended(
          onPressed: !c.loaded || c.isFull ? null : add,
          label: Text(c.isFull ? Strings.maxDevices : Strings.addDevice),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}
