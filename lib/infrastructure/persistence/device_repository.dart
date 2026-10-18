import '../../domain/ac_device.dart';
import '../../domain/ac_state.dart';

abstract interface class DeviceRepository {
  Future<List<AcDevice>> load();
  Future<void> saveDevices(List<AcDevice> devices);
  Future<void> saveState(String deviceId, AcState state);
  Future<void> deleteState(String deviceId);
}
