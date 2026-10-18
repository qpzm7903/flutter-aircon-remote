import 'package:flutter_aircon_remote/domain/ac_device.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';
import 'package:flutter_aircon_remote/infrastructure/persistence/device_repository.dart';

class InMemoryDeviceRepository implements DeviceRepository {
  List<AcDevice> devices = [];
  final Map<String, AcState> states = {};
  bool fail = false;
  int writes = 0;
  void check() {
    if (fail) throw StateError('Storage failed');
  }

  @override
  Future<List<AcDevice>> load() async {
    check();
    return devices
        .map((d) => d.copyWith(state: states[d.id] ?? d.state))
        .toList();
  }

  @override
  Future<void> saveDevices(List<AcDevice> value) async {
    writes++;
    check();
    devices = List.of(value);
  }

  @override
  Future<void> saveState(String id, AcState state) async {
    writes++;
    check();
    states[id] = state;
  }

  @override
  Future<void> deleteState(String id) async {
    writes++;
    check();
    states.remove(id);
  }
}
