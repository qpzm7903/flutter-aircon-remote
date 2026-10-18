import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_aircon_remote/infrastructure/persistence/shared_prefs_remote_repository.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';
import 'package:flutter_aircon_remote/core/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('round trip isolated model state protocol and theme', () async {
    SharedPreferences.setMockInitialValues({});
    final r = SharedPrefsRemoteRepository(
      await SharedPreferences.getInstance(),
    );
    await r.saveProtocolId('gree.ybofb');
    await r.saveState('gree.yaw1f', const AcState.initial());
    await r.saveState(
      'gree.ybofb',
      const AcState.initial().copyWith(power: true),
    );
    await r.saveThemeModeName('dark');
    final saved = await r.load();
    expect(saved.protocolId, 'gree.ybofb');
    expect(saved.states.length, 2);
    expect(saved.states['gree.ybofb']!.power, true);
    expect(saved.themeModeName, 'dark');
  });
  test('corrupt JSON types and fields recover independently', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.protocolKey: 3,
      AppConstants.themeKey: 'bad',
      '${AppConstants.statePrefix}one': '{',
      '${AppConstants.statePrefix}two': '[1]',
      '${AppConstants.statePrefix}three': '{"power":true,"mode":"unknown"}',
      '${AppConstants.statePrefix}four': false,
    });
    final saved = await SharedPrefsRemoteRepository(
      await SharedPreferences.getInstance(),
    ).load();
    expect(saved.protocolId, null);
    expect(saved.themeModeName, null);
    expect(saved.states.keys, ['three']);
    expect(
      saved.states['three'],
      const AcState.initial().copyWith(power: true),
    );
  });
}
