import 'ac_protocol.dart';

class AcProtocolRegistry {
  AcProtocolRegistry(List<AcProtocol> protocols)
    : all = List.unmodifiable(protocols) {
    if (all.isEmpty || all.map((p) => p.id).toSet().length != all.length) {
      throw StateError('Empty or duplicate protocols');
    }
  }
  final List<AcProtocol> all;
  List<String> get brandIds => all.map((p) => p.brandId).toSet().toList();
  List<AcProtocol> modelsOf(String brandId) =>
      all.where((p) => p.brandId == brandId).toList();
  AcProtocol? byId(String id) => all.where((p) => p.id == id).firstOrNull;
  String brandNameOf(String id) => modelsOf(id).firstOrNull?.brandName ?? id;
  AcProtocol get fallback => all.first;
}
