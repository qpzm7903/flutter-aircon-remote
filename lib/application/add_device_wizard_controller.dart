import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/ac_device.dart';
import '../protocol/protocol_registry.dart';
import '../infrastructure/ir/ir_transmitter.dart';
import '../infrastructure/logging/log_service.dart';
import 'device_list_controller.dart';
import 'device_settings_controller.dart';
import 'add_device_wizard.dart';

class AddDeviceWizardController extends ChangeNotifier {
  AddDeviceWizardController({
    required this.registry,
    required this._transmitter,
    required this.devices,
    this.repairing,
  }) : machine = AddDeviceWizard(registry: registry) {
    state = machine.initial(irAvailable: false, repairing: repairing);
  }
  final AcProtocolRegistry registry;
  final IrTransmitter _transmitter;
  final DeviceListController devices;
  final AcDevice? repairing;
  final AddDeviceWizard machine;
  late WizardState state;
  bool _disposed = false, ready = false;
  final _completed = StreamController<WizardOutcome>.broadcast();
  Stream<WizardOutcome> get completed => _completed.stream;
  List<String> get brandIds => registry.brandIds;
  String brandNameOf(String id) => registry.brandNameOf(id);
  List<ProtocolOption> get options => registry.all
      .map((p) => ProtocolOption(p.id, p.brandName, p.modelName, p.modelNote))
      .toList();
  Future<void> init() async {
    var available = false;
    try {
      available = await _transmitter.hasIrEmitter();
    } catch (e) {
      LogService.warning('Pair IR check failed', e);
    }
    if (_disposed) return;
    state = machine.initial(irAvailable: available, repairing: repairing);
    ready = true;
    notifyListeners();
  }

  Future<void> dispatch(WizardEvent event) async {
    if (_disposed || !ready) return;
    final previous = state;
    final transition = machine.handle(state, event);
    state = transition.state;
    notifyListeners();
    for (final effect in transition.effects) {
      if (effect is SendProbe) {
        IrErrorCode? error;
        try {
          final p = registry.byId(effect.protocolId)!;
          final frame = p.encode(p.pairingProbe);
          LogService.info('pair | ${p.id} | ${frame.debugHex}');
          await _transmitter.transmit(frame);
        } on IrTransmitException catch (e) {
          error = e.code;
        } catch (e) {
          error = IrErrorCode.platform;
          LogService.warning('Pair send failed', e);
        }
        await dispatch(ProbeResult(effect.seq, error));
      }
      if (effect is Complete) {
        if (repairing == null) {
          final p = registry.byId(effect.outcome.protocolId)!;
          final added = await devices.add(
            name: effect.outcome.name,
            room: effect.outcome.room,
            icon: effect.outcome.icon,
            protocolId: p.id,
            initialState: effect.outcome.pairingConfirmed
                ? p.capabilities.normalize(p.pairingProbe)
                : p.defaultState,
            pairingConfirmed: effect.outcome.pairingConfirmed,
          );
          if (added == null) {
            if (!_disposed) {
              state = previous;
              notifyListeners();
            }
            continue;
          }
        }
        if (!_disposed) _completed.add(effect.outcome);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_completed.close());
    super.dispose();
  }
}
