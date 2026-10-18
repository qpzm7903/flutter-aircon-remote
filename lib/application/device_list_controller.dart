import 'package:flutter/foundation.dart';

import '../domain/ac_device.dart';
import '../domain/ac_state.dart';
import '../protocol/protocol_registry.dart';
import '../infrastructure/persistence/device_repository.dart';
import '../infrastructure/logging/log_service.dart';

typedef DeviceIdGenerator = String Function();

class DeviceListController extends ChangeNotifier {
  DeviceListController({
    required this.registry,
    required this._repository,
    DeviceIdGenerator? idGenerator,
  }) : _idGenerator =
           idGenerator ?? (() => 'd${DateTime.now().microsecondsSinceEpoch}');
  final AcProtocolRegistry registry;
  final DeviceRepository _repository;
  final DeviceIdGenerator _idGenerator;
  static const maxDevices = 20;
  bool loaded = false;
  final List<String> warnings = [];
  List<AcDevice> _devices = [];
  List<AcDevice> get devices => List.unmodifiable(_devices);
  bool get isFull => _devices.length >= maxDevices;
  AcDevice? byId(String id) => _devices.where((d) => d.id == id).firstOrNull;
  Future<void> _queue = Future.value();
  Future<void> _write(Future<void> Function() action) =>
      _queue = _queue.then((_) async {
        try {
          await action();
        } catch (e) {
          warnings.add(e.toString());
          LogService.warning('Device persistence failed', e);
        }
      });
  AcDevice _normalize(AcDevice d) {
    final p = registry.byId(d.protocolId) ?? registry.fallback;
    if (p.id != d.protocolId) {
      warnings.add('Unknown protocol: ${d.protocolId}');
      LogService.warning(warnings.last);
    }
    return d.copyWith(
      protocolId: p.id,
      state: p.capabilities.restrictedBy(d.overrides).normalize(d.state),
    );
  }

  Future<void> init() async {
    try {
      final saved = await _repository.load();
      _devices = saved.map(_normalize).toList();
      for (var i = 0; i < saved.length; i++) {
        if (saved[i].state != _devices[i].state) {
          await _write(
            () => _repository.saveState(_devices[i].id, _devices[i].state),
          );
        }
      }
    } catch (e) {
      warnings.add(e.toString());
      LogService.warning('Device load failed', e);
    }
    loaded = true;
    notifyListeners();
  }

  Future<AcDevice?> add({
    required String name,
    String? room,
    AcIcon icon = AcIcon.generic,
    required String protocolId,
    required AcState initialState,
    bool pairingConfirmed = false,
  }) async {
    if (isFull ||
        AcDevice.validateName(name) != null ||
        (room?.trim().runes.length ?? 0) > 20) {
      return null;
    }
    final d = _normalize(
      AcDevice(
        id: _idGenerator(),
        name: name.trim(),
        room: room == null || room.trim().isEmpty ? null : room.trim(),
        icon: icon,
        protocolId: protocolId,
        state: initialState,
        pairingConfirmed: pairingConfirmed,
        sortOrder: _devices.length,
      ),
    );
    if (byId(d.id) != null) throw StateError('Duplicate device id');
    _devices.add(d);
    notifyListeners();
    final snapshot = devices;
    await _write(() async {
      await _repository.saveState(d.id, d.state);
      await _repository.saveDevices(snapshot);
    });
    return d;
  }

  Future<void> update(AcDevice updated) async {
    final old = byId(updated.id);
    if (old == null ||
        AcDevice.validateName(updated.name) != null ||
        (updated.room?.trim().runes.length ?? 0) > 20) {
      return;
    }
    final d = _normalize(
      updated.copyWith(name: updated.name.trim(), state: old.state),
    );
    _devices[_devices.indexOf(old)] = d;
    notifyListeners();
    final snapshot = devices;
    await _write(() async {
      await _repository.saveState(d.id, d.state);
      await _repository.saveDevices(snapshot);
    });
  }

  Future<void> remove(String id) async {
    _devices.removeWhere((d) => d.id == id);
    _renumber();
    notifyListeners();
    final snapshot = devices;
    await _write(() async {
      await _repository.saveDevices(snapshot);
      await _repository.deleteState(id);
    });
  }

  void _renumber() {
    _devices = [
      for (var i = 0; i < _devices.length; i++)
        _devices[i].copyWith(sortOrder: i),
    ];
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final d = _devices.removeAt(oldIndex);
    _devices.insert(newIndex, d);
    _renumber();
    notifyListeners();
    final snapshot = devices;
    await _write(() => _repository.saveDevices(snapshot));
  }

  void saveState(String id, AcState state) {
    final d = byId(id);
    if (d == null) return;
    _devices[_devices.indexOf(d)] = d.copyWith(state: state);
    _write(() => _repository.saveState(id, state));
  }
}
