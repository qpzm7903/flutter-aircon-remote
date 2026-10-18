import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/device_settings_controller.dart';
import '../../application/remote_session_factory.dart';
import '../../application/add_device_wizard.dart';
import '../../domain/ac_device.dart';
import '../../domain/ac_enums.dart';
import '../strings.dart';
import 'home_page.dart';
import 'add_device_page.dart';
import 'control_help_sheet.dart';

class DeviceSettingsPage extends StatelessWidget {
  const DeviceSettingsPage({required this.deviceId, super.key});
  final String deviceId;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) =>
        context.read<RemoteSessionFactory>().createSettings(deviceId),
    child: const _SettingsBody(),
  );
}

class _SettingsBody extends StatefulWidget {
  const _SettingsBody();
  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  bool _allowPop = false;
  @override
  Widget build(BuildContext context) {
    final c = context.watch<DeviceSettingsController>();
    final d = c.draft;
    final p = c.protocolCapabilities;
    final e = c.effectiveCapabilities;
    Widget title(String text) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
    void changed(VoidCallback action) {
      action();
      if (c.lastRejected) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(Strings.keepOne)));
      }
    }

    return PopScope(
      canPop: _allowPop || !c.hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(Strings.discardQuestion),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(Strings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(Strings.discard),
              ),
            ],
          ),
        );
        if (discard == true && context.mounted) {
          setState(() => _allowPop = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
              Navigator.pop(context);
            }
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(Strings.settingsTitle),
          actions: [
            TextButton(
              onPressed: c.hasChanges
                  ? () async {
                      if (await c.save() && context.mounted) {
                        setState(() => _allowPop = true);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted &&
                              ModalRoute.of(context)?.isCurrent == true) {
                            Navigator.pop(context);
                          }
                        });
                      }
                    }
                  : null,
              child: const Text(Strings.save),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            title(Strings.basicInfo),
            TextFormField(
              initialValue: d.name,
              maxLength: 20,
              decoration: InputDecoration(
                labelText: Strings.name,
                errorText: c.nameError == null ? null : Strings.nameInvalid,
              ),
              onChanged: c.setName,
            ),
            TextFormField(
              initialValue: d.room,
              maxLength: 20,
              decoration: const InputDecoration(labelText: Strings.room),
              onChanged: c.setRoom,
            ),
            Wrap(
              children: [
                for (final icon in AcIcon.values)
                  ChoiceChip(
                    label: Text(Strings.iconNames[icon.index]),
                    selected: d.icon == icon,
                    onSelected: (_) => c.setIcon(icon),
                  ),
              ],
            ),
            title(Strings.protocolTitle),
            DropdownButton<String>(
              isExpanded: true,
              value: d.protocolId,
              items: [
                for (final p in c.protocolOptions)
                  DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.brandName} / ${p.modelName}'),
                  ),
              ],
              onChanged: (id) => c.setProtocol(id!),
            ),
            Text(
              c.protocolOptions.firstWhere((p) => p.id == d.protocolId).note,
            ),
            const Text(Strings.protocolHelp),
            TextButton(
              onPressed: () async {
                final result = await Navigator.push<WizardOutcome>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddDevicePage(repairing: d),
                  ),
                );
                if (result != null) {
                  c.setPairing(result.protocolId, result.pairingConfirmed);
                }
              },
              child: const Text(Strings.repairPairing),
            ),
            title(Strings.visibility),
            for (final m in p.modes)
              SwitchListTile(
                title: Text('${Strings.mode} · ${Strings.modes[m]}'),
                value: e.modes.contains(m),
                onChanged: (v) => changed(() => c.setModeVisible(m, v)),
              ),
            for (final f in p.fanSpeeds)
              SwitchListTile(
                title: Text('${Strings.fan} · ${Strings.fans[f]}'),
                value: e.fanSpeeds.contains(f),
                onChanged: (v) => changed(() => c.setFanSpeedVisible(f, v)),
              ),
            SwitchListTile(
              title: const Text(Strings.hasSwing),
              value: e.verticalSwings.length > 1,
              onChanged: c.setAllSwingVisible,
            ),
            if (e.verticalSwings.length > 1)
              for (final s in p.verticalSwings.where(
                (s) => s != VerticalSwing.off,
              ))
                SwitchListTile(
                  title: Text('${Strings.swing} · ${Strings.swings[s]}'),
                  value: e.verticalSwings.contains(s),
                  onChanged: (v) => c.setSwingVisible(s, v),
                ),
            if (e.features.contains(AcFeature.swingH))
              for (final h in p.horizontalSwings.where(
                (h) => h != HorizontalSwing.off,
              ))
                SwitchListTile(
                  title: Text(
                    '${Strings.horizontalSwing} · ${Strings.hSwings[h]}',
                  ),
                  value: e.horizontalSwings.contains(h),
                  onChanged: (v) => c.setHSwingVisible(h, v),
                ),
            for (final f in p.features)
              SwitchListTile(
                title: Text(Strings.featureNames[f]!),
                subtitle:
                    {
                          AcFeature.swingH,
                          AcFeature.wifi,
                          AcFeature.timer,
                          AcFeature.fahrenheit,
                        }.contains(f) &&
                        !e.features.contains(f)
                    ? const Text('此机型多数没有该功能，按需打开')
                    : null,
                value: e.features.contains(f),
                onChanged: (v) => c.setFeatureVisible(f, v),
              ),
            Text(Strings.tempRange(e.minTempC, e.maxTempC)),
            RangeSlider(
              min: p.minTempC.toDouble(),
              max: p.maxTempC.toDouble(),
              divisions: p.maxTempC - p.minTempC,
              values: RangeValues(e.minTempC.toDouble(), e.maxTempC.toDouble()),
              onChanged: (v) => c.setTempRange(v.start.round(), v.end.round()),
            ),
            const Text(Strings.hiddenHelp),
            TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => ControlHelpSheet(
                  protocol: p,
                  overrides: d.overrides,
                  state: d.state,
                ),
              ),
              child: const Text(Strings.helpTitle),
            ),
            title(Strings.dangerZone),
            TextButton(
              onPressed: () async {
                if (await confirmDelete(context, d)) {
                  setState(() => _allowPop = true);
                  await c.delete();
                  if (context.mounted &&
                      ModalRoute.of(context)?.isCurrent == true) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text(Strings.deleteDevice),
            ),
          ],
        ),
      ),
    );
  }
}
