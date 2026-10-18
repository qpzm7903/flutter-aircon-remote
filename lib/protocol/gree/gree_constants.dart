import '../pulse/pulse_timing.dart';

abstract final class GreeConstants {
  static const carrierHz = 38000;
  static const blockFooter = 2;
  static const timings = PulseTimings(
    headerMark: 9000,
    headerSpace: 4500,
    bitMark: 620,
    oneSpace: 1600,
    zeroSpace: 540,
    gapSpace: 19980,
  );
}
