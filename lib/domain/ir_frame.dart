final class IrFrame {
  const IrFrame({
    required this.carrierHz,
    required this.patternMicros,
    this.debugHex = '',
  });
  final int carrierHz;
  final List<int> patternMicros;
  final String debugHex;
  int get totalMicros => patternMicros.fold(0, (a, b) => a + b);
  void validate({int maxMicros = 2000000, int maxEntries = 1000}) {
    if (carrierHz <= 0 ||
        patternMicros.isEmpty ||
        patternMicros.any((v) => v <= 0)) {
      throw ArgumentError('Invalid IR frame');
    }
    if (patternMicros.length > maxEntries || totalMicros >= maxMicros) {
      throw ArgumentError('Pattern too long');
    }
  }
}
