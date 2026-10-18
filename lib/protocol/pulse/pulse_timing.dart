final class PulseTimings {
  const PulseTimings({
    required this.headerMark,
    required this.headerSpace,
    required this.bitMark,
    required this.oneSpace,
    required this.zeroSpace,
    required this.gapSpace,
  });
  final int headerMark, headerSpace, bitMark, oneSpace, zeroSpace, gapSpace;
}

void appendBitsLsbFirst(
  List<int> out,
  int value,
  int bitCount,
  PulseTimings t,
) {
  for (var i = 0; i < bitCount; i++) {
    out.addAll([t.bitMark, value & (1 << i) != 0 ? t.oneSpace : t.zeroSpace]);
  }
}
