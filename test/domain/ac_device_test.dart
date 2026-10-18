import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/domain/ac_device.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';

import '../support/pump_app.dart';

void main() {
  test('meta roundtrip excludes state and has value equality', () {
    final d = testDevice();
    expect(d.toMetaJson().containsKey('state'), false);
    expect(AcDevice.fromMetaJson(d.toMetaJson(), state: d.state), d);
    expect(d.copyWith(name: '客厅', room: '').room, null);
    expect(d.copyWith(room: null).room, null);
    expect(d.copyWith(), d);
    expect(d.hashCode, d.copyWith().hashCode);
  });
  test('meta tolerates missing and unknown fields', () {
    final d = AcDevice.fromMetaJson({
      'name': ' ',
      'icon': 'bad',
      'room': ' ',
    }, state: const AcState.initial());
    expect(d.name, '我的空调');
    expect(d.room, null);
    expect(d.icon, AcIcon.generic);
  });
  test('name validation bounds and trim', () {
    expect(AcDevice.validateName('  '), 'empty');
    expect(AcDevice.validateName('字' * 21), 'tooLong');
    expect(AcDevice.validateName('字' * 20), null);
    expect(AcDevice.validateName(' 主卧 '), null);
  });
}
