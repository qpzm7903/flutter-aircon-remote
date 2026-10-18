import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/protocol/pulse/pulse_timing.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_constants.dart';

void main() {
  test('bits are LSB first', () {
    final out = <int>[];
    appendBitsLsbFirst(out, 3, 4, GreeConstants.timings);
    expect(out, [620, 1600, 620, 1600, 620, 540, 620, 540]);
  });
}
