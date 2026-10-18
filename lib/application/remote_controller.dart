import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/ac_state.dart';
import '../domain/ac_capabilities.dart';
import '../domain/ac_enums.dart';
import '../protocol/ac_protocol.dart';
import '../protocol/protocol_registry.dart';
import '../infrastructure/ir/ir_transmitter.dart';
import '../infrastructure/persistence/remote_repository.dart';
import '../infrastructure/logging/log_service.dart';
import 'remote_event.dart';

enum IrAvailability { unknown, available, unavailable }

class RemoteController extends ChangeNotifier {
  RemoteController({
    required this.registry,
    required this._transmitter,
    required this._repository,
  }) {
    _protocol = registry.fallback;
    _state = _protocol.defaultState;
  }
  final AcProtocolRegistry registry;
  final IrTransmitter _transmitter;
  final RemoteRepository _repository;
  late AcProtocol _protocol;
  late AcState _state;
  AcProtocol get protocol => _protocol;
  AcState get state => _state;
  AcCapabilities get capabilities => protocol.capabilities;
  IrAvailability _availability = IrAvailability.unknown;
  IrAvailability get irAvailability => _availability;
  bool _sending = false, _disposed = false;
  bool get isSending => _sending;
  final _events = StreamController<RemoteEvent>.broadcast();
  Stream<RemoteEvent> get events => _events.stream;
  final Map<String, AcState> _states = {};
  AcState? _pending;
  AcProtocol? _pendingProtocol;
  Future<void>? _drainFuture;
  Future<void> _persistenceFuture = Future.value();
  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> init() async {
    try {
      final saved = await _repository.load();
      _states.addAll(saved.states);
      _protocol = registry.byId(saved.protocolId ?? '') ?? registry.fallback;
      if (saved.protocolId != null &&
          registry.byId(saved.protocolId!) == null) {
        LogService.warning('Unknown protocol: ${saved.protocolId}');
      }
      _state = capabilities.normalize(
        _states[protocol.id] ?? protocol.defaultState,
      );
    } catch (e) {
      LogService.warning('State load failed', e);
    }
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

  Future<void> _persist(Future<void> Function() action) {
    return _persistenceFuture = _persistenceFuture.then((_) async {
      try {
        await action();
      } catch (e) {
        LogService.warning('Persistence failed', e);
      }
    });
  }

  Future<void> update(AcState Function(AcState s) mutate) async {
    if (_disposed || _availability == IrAvailability.unavailable) {
      return;
    }
    final next = capabilities.normalize(mutate(state));
    if (next == state) {
      return;
    }
    _state = next;
    _states[protocol.id] = next;
    _notify();
    final id = protocol.id;
    unawaited(_persist(() => _repository.saveState(id, next)));
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
      while (_pending != null && !_disposed) {
        final next = _pending!;
        final encoder = _pendingProtocol!;
        _pending = null;
        try {
          final frame = encoder.encode(next);
          LogService.info(
            '${encoder.id} | ${frame.debugHex} | ${frame.patternMicros.length} | ${frame.totalMicros / 1000}ms',
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

  Future<void> setProtocol(String protocolId) async {
    final next = registry.byId(protocolId);
    if (next == null || next.id == protocol.id || _disposed) {
      return;
    }
    _pending = null;
    _states[protocol.id] = state;
    _protocol = next;
    _state = capabilities.normalize(_states[next.id] ?? next.defaultState);
    _notify();
    LogService.info('Protocol: ${next.id}');
    await _persist(() => _repository.saveProtocolId(next.id));
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
  List<String> logSnapshot([int n = 200]) => LogService.getRecentLogs(n);
  String logFilePath() => LogService.getLogFilePath();
  @override
  void dispose() {
    _disposed = true;
    _pending = null;
    unawaited(_events.close());
    super.dispose();
  }
}
