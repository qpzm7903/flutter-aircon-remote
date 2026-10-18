import '../domain/ac_device.dart';
import '../protocol/protocol_registry.dart';
import '../infrastructure/ir/ir_transmitter.dart';
import 'device_list_controller.dart';
import 'remote_controller.dart';
import 'device_settings_controller.dart';
import 'add_device_wizard_controller.dart';

class RemoteSessionFactory {
  RemoteSessionFactory({
    required this.registry,
    required this.transmitter,
    required this.devices,
  });
  final AcProtocolRegistry registry;
  final IrTransmitter transmitter;
  final DeviceListController devices;
  RemoteController create(String deviceId) => RemoteController(
    deviceId: deviceId,
    registry: registry,
    transmitter: transmitter,
    devices: devices,
  );
  AddDeviceWizardController createWizard({AcDevice? repairing}) =>
      AddDeviceWizardController(
        registry: registry,
        transmitter: transmitter,
        devices: devices,
        repairing: repairing,
      );
  DeviceSettingsController createSettings(String deviceId) =>
      DeviceSettingsController(
        deviceId: deviceId,
        registry: registry,
        devices: devices,
      );
  String subtitle(AcDevice d) {
    final p = registry.byId(d.protocolId) ?? registry.fallback;
    return [
      if (d.room != null) d.room!,
      '${p.brandName} / ${p.modelName}',
      if (!d.pairingConfirmed) '未做配对测试',
    ].join(' · ');
  }
}
