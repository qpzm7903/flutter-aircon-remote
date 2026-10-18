import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/add_device_wizard.dart';
import '../../application/add_device_wizard_controller.dart';
import '../../application/remote_session_factory.dart';
import '../../domain/ac_device.dart';
import '../strings.dart';
import '../widgets/no_ir_banner.dart';

class AddDevicePage extends StatelessWidget {
  const AddDevicePage({this.repairing, super.key});
  final AcDevice? repairing;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) =>
        context.read<RemoteSessionFactory>().createWizard(repairing: repairing)
          ..init(),
    child: const _WizardBody(),
  );
}

class _WizardBody extends StatefulWidget {
  const _WizardBody();
  @override
  State<_WizardBody> createState() => _WizardBodyState();
}

class _WizardBodyState extends State<_WizardBody> {
  StreamSubscription<WizardOutcome>? _sub;
  @override
  void initState() {
    super.initState();
    _sub = context.read<AddDeviceWizardController>().completed.listen((o) {
      if (!mounted) return;
      final repair =
          context.read<AddDeviceWizardController>().repairing != null;
      Navigator.pop(context, o);
      if (!repair) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Strings.added(o.name)),
                if (o.pairingConfirmed) const Text(Strings.pairingSuccess),
              ],
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AddDeviceWizardController>();
    final s = c.state;
    Widget button(String label, WizardEvent event) =>
        TextButton(onPressed: () => c.dispatch(event), child: Text(label));
    final items = <Widget>[];
    switch (s.step) {
      case WizardStep.intro:
        items.addAll([
          const Text(Strings.pairingIntro),
          if (c.ready && !s.irAvailable) NoIrBanner(onRecheck: c.init),
          button(Strings.start, const Next()),
        ]);
      case WizardStep.info:
        items.addAll([
          TextFormField(
            initialValue: s.name,
            maxLength: 20,
            decoration: InputDecoration(
              labelText: Strings.name,
              errorText: s.nameInvalid ? Strings.nameInvalid : null,
            ),
            onChanged: (v) => c.dispatch(SetName(v)),
          ),
          TextFormField(
            initialValue: s.room,
            maxLength: 20,
            decoration: const InputDecoration(labelText: Strings.room),
            onChanged: (v) => c.dispatch(SetRoom(v)),
          ),
          Wrap(
            children: [
              for (final icon in AcIcon.values)
                ChoiceChip(
                  label: Text(Strings.iconNames[icon.index]),
                  selected: s.icon == icon,
                  onSelected: (_) => c.dispatch(SetIcon(icon)),
                ),
            ],
          ),
          button(Strings.back, const Back()),
          button(Strings.next, const Next()),
        ]);
      case WizardStep.brand:
        items.addAll([
          const Text(Strings.confirmBrand),
          for (final id in c.brandIds)
            ChoiceChip(
              label: Text(c.brandNameOf(id)),
              selected: s.brandId == id,
              onSelected: (_) => c.dispatch(SetBrand(id)),
            ),
          button(Strings.back, const Back()),
          button(Strings.next, const Next()),
        ]);
      case WizardStep.pairing:
        items.add(const Text(Strings.probeWarning));
        if (!s.irAvailable) items.add(NoIrBanner(onRecheck: c.init));
        switch (s.phase) {
          case PairingPhase.idle:
            items.addAll([
              const Text(Strings.probeIntro),
              if (s.irAvailable)
                button(Strings.startProbe, const StartPairing()),
            ]);
          case PairingPhase.sending:
            items.addAll([
              Text(
                Strings.sendingProbe(
                  c.options
                      .firstWhere(
                        (p) => p.id == s.candidateIds[s.candidateIndex],
                      )
                      .modelName,
                  s.candidateIndex + 1,
                  s.candidateIds.length,
                ),
              ),
              const LinearProgressIndicator(),
            ]);
          case PairingPhase.awaitingAnswer:
            items.addAll([
              const Text(Strings.responseQuestion),
              const Text(Strings.pairingSuccess),
              button(Strings.yesResponse, const AnswerYes()),
              button(Strings.noResponse, const AnswerNo()),
              button(Strings.resend, const Resend()),
            ]);
          case PairingPhase.sendFailed:
            items.addAll([
              Text(Strings.error(s.sendError!)),
              if (s.irAvailable) button(Strings.resend, const Resend()),
            ]);
          case PairingPhase.exhausted:
            items.addAll([
              const Text(Strings.exhausted),
              for (final tip in Strings.pairingTips) Text(tip),
              DropdownButton<String>(
                value: s.selectedFallbackId,
                items: [
                  for (final p in c.options.where(
                    (p) => s.candidateIds.contains(p.id),
                  ))
                    DropdownMenuItem(value: p.id, child: Text(p.modelName)),
                ],
                onChanged: (id) => c.dispatch(SelectFallback(id!)),
              ),
              button(Strings.saveAnyway, const SaveFallback()),
              button(Strings.restartPairing, const StartPairing()),
            ]);
        }
        items.add(button(Strings.skip, const Skip()));
        if (s.mode == WizardMode.create) {
          items.add(button(Strings.back, const Back()));
        }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.mode == WizardMode.repair
              ? Strings.repairPairing
              : Strings.addDevice,
        ),
      ),
      body: !c.ready
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Column(
                  key: ValueKey(s.step),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: items,
                ),
              ),
            ),
    );
  }
}
