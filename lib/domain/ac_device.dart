import 'ac_state.dart';
import 'capability_overrides.dart';

enum AcIcon { generic, bedroom, living, study, kitchen, kids, office }

final class AcDevice {
  const AcDevice({
    required this.id,
    required this.name,
    this.room,
    this.icon = AcIcon.generic,
    required this.protocolId,
    this.overrides = CapabilityOverrides.none,
    required this.state,
    this.sortOrder = 0,
    this.pairingConfirmed = false,
  });
  final String id, name, protocolId;
  final String? room;
  final AcIcon icon;
  final CapabilityOverrides overrides;
  final AcState state;
  final int sortOrder;
  final bool pairingConfirmed;
  static const maxNameLength = 20, maxRoomLength = 20;
  static String? validateName(String raw) => raw.trim().isEmpty
      ? 'empty'
      : raw.trim().runes.length > maxNameLength
      ? 'tooLong'
      : null;
  static const _unset = Object();
  AcDevice copyWith({
    String? name,
    Object? room = _unset,
    AcIcon? icon,
    String? protocolId,
    CapabilityOverrides? overrides,
    AcState? state,
    int? sortOrder,
    bool? pairingConfirmed,
  }) => AcDevice(
    id: id,
    name: name ?? this.name,
    room: identical(room, _unset)
        ? this.room
        : room == null || (room as String).trim().isEmpty
        ? null
        : room.trim(),
    icon: icon ?? this.icon,
    protocolId: protocolId ?? this.protocolId,
    overrides: overrides ?? this.overrides,
    state: state ?? this.state,
    sortOrder: sortOrder ?? this.sortOrder,
    pairingConfirmed: pairingConfirmed ?? this.pairingConfirmed,
  );
  Map<String, Object?> toMetaJson() => {
    'id': id,
    'name': name,
    'room': room,
    'icon': icon.name,
    'protocolId': protocolId,
    'overrides': overrides.toJson(),
    'sortOrder': sortOrder,
    'pairingConfirmed': pairingConfirmed,
  };
  factory AcDevice.fromMetaJson(
    Map<String, Object?> j, {
    required AcState state,
  }) => AcDevice(
    id: j['id'] is String ? j['id'] as String : '',
    name: j['name'] is String && (j['name'] as String).trim().isNotEmpty
        ? (j['name'] as String).trim()
        : '我的空调',
    room: j['room'] is String && (j['room'] as String).trim().isNotEmpty
        ? (j['room'] as String).trim()
        : null,
    icon:
        AcIcon.values.where((v) => v.name == j['icon']).firstOrNull ??
        AcIcon.generic,
    protocolId: j['protocolId'] is String ? j['protocolId'] as String : '',
    overrides: CapabilityOverrides.fromJson(j['overrides']),
    state: state,
    sortOrder: j['sortOrder'] is int ? j['sortOrder'] as int : 0,
    pairingConfirmed: j['pairingConfirmed'] == true,
  );
  @override
  bool operator ==(Object other) =>
      other is AcDevice &&
      id == other.id &&
      name == other.name &&
      room == other.room &&
      icon == other.icon &&
      protocolId == other.protocolId &&
      overrides == other.overrides &&
      state == other.state &&
      sortOrder == other.sortOrder &&
      pairingConfirmed == other.pairingConfirmed;
  @override
  int get hashCode => Object.hash(
    id,
    name,
    room,
    icon,
    protocolId,
    overrides,
    state,
    sortOrder,
    pairingConfirmed,
  );
}
