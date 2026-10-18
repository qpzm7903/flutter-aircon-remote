import '../../domain/ac_enums.dart';
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

const greeVerticalSwingValues = {
  VerticalSwing.off: 0,
  VerticalSwing.auto: 1,
  VerticalSwing.highest: 2,
  VerticalSwing.high: 3,
  VerticalSwing.middle: 4,
  VerticalSwing.low: 5,
  VerticalSwing.lowest: 6,
  VerticalSwing.autoDown: 7,
  VerticalSwing.autoMiddle: 9,
  VerticalSwing.autoUp: 11,
};
const greeHorizontalSwingValues = {
  HorizontalSwing.off: 0,
  HorizontalSwing.auto: 1,
  HorizontalSwing.maxLeft: 2,
  HorizontalSwing.left: 3,
  HorizontalSwing.middle: 4,
  HorizontalSwing.right: 5,
  HorizontalSwing.maxRight: 6,
};
const greeFahrenheitTable = <({int f, int c, int extra})>[
  (f: 61, c: 16, extra: 0),
  (f: 62, c: 17, extra: 0),
  (f: 63, c: 17, extra: 1),
  (f: 64, c: 18, extra: 0),
  (f: 65, c: 18, extra: 1),
  (f: 66, c: 19, extra: 0),
  (f: 67, c: 19, extra: 1),
  (f: 68, c: 20, extra: 0),
  (f: 69, c: 20, extra: 1),
  (f: 70, c: 21, extra: 1),
  (f: 71, c: 22, extra: 0),
  (f: 72, c: 22, extra: 1),
  (f: 73, c: 23, extra: 0),
  (f: 74, c: 23, extra: 1),
  (f: 75, c: 24, extra: 0),
  (f: 76, c: 24, extra: 1),
  (f: 77, c: 25, extra: 0),
  (f: 78, c: 25, extra: 1),
  (f: 79, c: 26, extra: 1),
  (f: 80, c: 27, extra: 0),
  (f: 81, c: 27, extra: 1),
  (f: 82, c: 28, extra: 0),
  (f: 83, c: 28, extra: 1),
  (f: 84, c: 29, extra: 0),
  (f: 85, c: 29, extra: 1),
  (f: 86, c: 30, extra: 0),
];
