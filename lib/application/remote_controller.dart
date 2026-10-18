import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/ac_state.dart';
import '../domain/ac_capabilities.dart';
import '../domain/ac_enums.dart';
import '../protocol/ac_protocol.dart';
import '../protocol/protocol_registry.dart';
import '../infrastructure/ir/ir_transmitter.dart';
import '../domain/ac_device.dart';
import 'device_list_controller.dart';
import '../infrastructure/logging/log_service.dart';
import 'remote_event.dart';

enum IrAvailability { unknown, available, unavailable }

class RemoteController extends ChangeNotifier {
  RemoteController({
    required this.deviceId,
    required this.registry,
    required this._transmitter,
    required this._devices,
  }) {
    _lastDevice = device;
    _state = capabilities.normalize(device.state);
    _devices.addListener(_onDevicesChanged);
  }
  final String deviceId;
  final AcProtocolRegistry registry;
  final IrTransmitter _transmitter;
  final DeviceListController _devices;
  late AcDevice _lastDevice;
  AcDevice get device => _devices.byId(deviceId) ?? _lastDevice;
  String get title => device.name;
  AcProtocol get protocol =>
      registry.byId(device.protocolId) ?? registry.fallback;
  late AcState _state;
  AcState get state => _state;
  AcCapabilities get capabilities =>
      protocol.capabilities.restrictedBy(device.overrides);
  void _onDevicesChanged() {
    if (_disposed) return;
    final next = _devices.byId(deviceId);
    if (next == null) {
      _removed = true;
      _pending = null;
      _events.add(DeviceRemoved());
      return;
    }
    if (next.protocolId != _lastDevice.protocolId ||
        next.overrides != _lastDevice.overrides) {
      _pending = null;
      _state = capabilities.normalize(_state);
      _devices.saveState(deviceId, _state);
    }
    _lastDevice = next;
    _notify();
  }

  IrAvailability _availability = IrAvailability.unknown;
  IrAvailability get irAvailability => _availability;
  bool _sending = false, _disposed = false, _removed = false;
  bool get isSending => _sending;
  final _events = StreamController<RemoteEvent>.broadcast();
  Stream<RemoteEvent> get events => _events.stream;
  AcState? _pending;
  AcProtocol? _pendingProtocol;
  Future<void>? _drainFuture;
  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> init() async {
    _state = capabilities.normalize(device.state);
    await recheckIr();
  }

  Future<void> recheckIr() async {
    _availability = IrAvailability.unknown;
    _notify();
    try {
      _availability = await _transmitter.hasIrEmitter()
          ? IrAvailability.available
          : IrAvailability.unavailable;
    } catch (e) {
      _availability = IrAvailability.unavailable;
      LogService.warning('IR probe failed', e);
    }
    LogService.info('IR availability: ${_availability.name}');
    _notify();
  }

  Future<void> update(AcState Function(AcState s) mutate) async {
    if (_disposed || _removed || _availability == IrAvailability.unavailable) {
      return;
    }
    final next = capabilities.normalize(mutate(state));
    if (next == state) {
      return;
    }
    _state = next;
    _devices.saveState(deviceId, next);
    _notify();
    _pending = next;
    _pendingProtocol = protocol;
    if (!_sending) {
      _drainFuture = _drain();
    }
    await _drainFuture;
  }

  Future<void> _drain() async {
    _sending = true;
    _notify();
    try {
      while (_pending != null && !_disposed && !_removed) {
        final next = _pending!;
        final encoder = _pendingProtocol!;
        _pending = null;
        try {
          final frame = encoder.encode(next);
          LogService.info(
            '$deviceId | ${encoder.id} | ${frame.debugHex} | ${frame.patternMicros.length} | ${frame.totalMicros / 1000}ms',
          );
          await _transmitter.transmit(frame);
          LogService.info('Transmit succeeded');
          if (!_disposed) {
            _events.add(TransmitSucceeded());
          }
        } catch (e, stack) {
          final failure = e is IrTransmitException
              ? e
              : IrTransmitException(IrErrorCode.invalidArgument, e.toString());
          LogService.error('Transmit failed: ${failure.code.name}', e, stack);
          if (!_disposed) {
            _events.add(TransmitFailed(failure.code, failure.message));
          }
        }
      }
    } finally {
      _sending = false;
      _notify();
    }
  }

  Future<void> togglePower() => update((s) => s.copyWith(power: !s.power));
  Future<void> setMode(AcMode m) => update((s) => s.copyWith(mode: m));
  Future<void> stepTemp(int delta) async {
    if (capabilities.canEditTemp(state)) {
      await update((s) => s.copyWith(targetTempC: s.targetTempC + delta));
    }
  }

  Future<void> setFan(FanSpeed f) => update((s) => s.copyWith(fan: f));
  Future<void> setSwing(VerticalSwing s) =>
      update((state) => state.copyWith(verticalSwing: s));
  Future<void> setTempDisplay(TempDisplay d) =>
      update((s) => s.copyWith(tempDisplay: d));
  Future<void> toggleFeature(AcFeature f) => update(
    (s) => switch (f) {
      AcFeature.turbo => s.copyWith(turbo: !s.turbo),
      AcFeature.light => s.copyWith(light: !s.light),
      AcFeature.health => s.copyWith(health: !s.health),
      AcFeature.xfan => s.copyWith(xfan: !s.xfan),
      AcFeature.sleep => s.copyWith(sleep: !s.sleep),
      AcFeature.tempDisplay => s,
    },
  );
  @override
  void dispose() {
    _devices.removeListener(_onDevicesChanged);
    _disposed = true;
    _pending = null;
    unawaited(_events.close());
    super.dispose();
  }
}
