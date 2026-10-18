import 'package:flutter_test/flutter_test.dart' hide Skip;
import 'package:flutter_aircon_remote/application/add_device_wizard.dart';
import 'package:flutter_aircon_remote/domain/ac_device.dart';

import '../support/pump_app.dart';

void main() {
  late AddDeviceWizard m;
  setUp(() => m = AddDeviceWizard(registry: testRegistry()));
  WizardState advance({bool ir = true}) {
    var s = m.initial(irAvailable: ir);
    for (final e in [
      const Next(),
      const SetName(' 主卧 '),
      const SetRoom('二楼'),
      const SetIcon(AcIcon.bedroom),
      const Next(),
      const SetBrand('gree'),
      const Next(),
    ]) {
      s = m.handle(s, e).state;
    }
    return s;
  }

  test('intro info brand transitions, name validation and back', () {
    var s = m.initial(irAvailable: true);
    expect(m.handle(s, const Back()).state, s);
    s = m.handle(s, const Next()).state;
    expect(s.step, WizardStep.info);
    expect(m.handle(s, const Next()).state.nameInvalid, true);
    s = m.handle(s, SetName('字' * 21)).state;
    expect(s.nameInvalid, false);
    expect(m.handle(s, const Next()).state.step, WizardStep.info);
    s = m.handle(s, const SetName('主卧')).state;
    s = m.handle(s, const Next()).state;
    expect(s.brandId, 'gree');
    expect(m.handle(s, const SetBrand('unknown')).state, s);
    expect(m.handle(s, const Back()).state.step, WizardStep.info);
    expect(
      m.handle(m.handle(s, const Back()).state, const Back()).state.step,
      WizardStep.intro,
    );
  });
  test('successful first candidate and determinism', () {
    var s = advance();
    expect(s.candidateIds, ['gree.yaw1f', 'gree.ybofb', 'gree.yx1fsf']);
    final t = m.handle(s, const StartPairing());
    expect(t.effects.single, isA<SendProbe>());
    s = t.state;
    expect(s.phase, PairingPhase.sending);
    expect(m.handle(s, const Resend()).state, s);
    expect(m.handle(s, const AnswerYes()).state, s);
    s = m.handle(s, ProbeResult(s.probeSeq, null)).state;
    expect(s.phase, PairingPhase.awaitingAnswer);
    final a = m.handle(s, const AnswerYes());
    final b = m.handle(s, const AnswerYes());
    expect(a.state, b.state);
    expect(a.state.outcome!.name, '主卧');
    expect(a.state.outcome!.pairingConfirmed, true);
    expect(a.effects.single, isA<Complete>());
    expect(m.handle(a.state, const Next()).state, a.state);
  });
  test('No tries every candidate then fallback and restart', () {
    var s = m.handle(advance(), const StartPairing()).state;
    for (var i = 0; i < 3; i++) {
      s = m.handle(s, ProbeResult(s.probeSeq, null)).state;
      final t = m.handle(s, const AnswerNo());
      s = t.state;
      if (i < 2) {
        expect(s.candidateIndex, i + 1);
        expect(t.effects.single, isA<SendProbe>());
      } else {
        expect(t.effects, isEmpty);
      }
    }
    expect(s.phase, PairingPhase.exhausted);
    expect(s.selectedFallbackId, 'gree.yaw1f');
    expect(m.handle(s, const SelectFallback('bad')).state, s);
    s = m.handle(s, const SelectFallback('gree.yx1fsf')).state;
    expect(
      m.handle(s, const SaveFallback()).state.outcome!.protocolId,
      'gree.yx1fsf',
    );
    expect(
      m.handle(s, const SaveFallback()).state.outcome!.pairingConfirmed,
      false,
    );
    final restart = m.handle(s, const StartPairing());
    expect(restart.state.candidateIndex, 0);
    expect(restart.effects.single, isA<SendProbe>());
  });
  test('send errors, resend sequence, stale result and Back', () {
    var s = m.handle(advance(), const StartPairing()).state;
    expect(m.handle(s, ProbeResult(s.probeSeq - 1, null)).state, s);
    s = m.handle(s, ProbeResult(s.probeSeq, IrErrorCode.transmitFailed)).state;
    expect(s.phase, PairingPhase.sendFailed);
    expect(s.sendError, IrErrorCode.transmitFailed);
    s = m.handle(s, const Resend()).state;
    expect(s.resendCount, 1);
    expect(s.probeSeq, 2);
    final old = s.probeSeq;
    s = m.handle(s, const Back()).state;
    expect(s.step, WizardStep.brand);
    expect(s.probeSeq, old + 1);
    expect(m.handle(s, ProbeResult(old, null)).state, s);
  });
  test('awaiting answer resend and invalid events', () {
    var s = m.handle(advance(), const StartPairing()).state;
    s = m.handle(s, ProbeResult(s.probeSeq, null)).state;
    final t = m.handle(s, const Resend());
    expect(t.state.resendCount, 1);
    expect(t.effects.single, isA<SendProbe>());
    expect(m.handle(s, const SaveFallback()).state, s);
  });
  test('no IR only skip and back', () {
    final s = advance(ir: false);
    final t = m.handle(s, const StartPairing());
    expect(t.effects, isEmpty);
    expect(t.state.sendError, IrErrorCode.noIrEmitter);
    expect(m.handle(t.state, const Resend()).state, t.state);
    final done = m.handle(t.state, const Skip());
    expect(done.state.outcome!.protocolId, 'gree.yaw1f');
    expect(done.state.outcome!.pairingConfirmed, false);
  });
  test('repair starts at pairing and skip preserves original', () {
    final s = m.initial(
      irAvailable: true,
      repairing: testDevice(protocolId: 'gree.yx1fsf'),
    );
    expect(s.mode, WizardMode.repair);
    expect(s.step, WizardStep.pairing);
    expect(m.handle(s, const Back()).state, s);
    expect(m.handle(s, const Skip()).state.outcome!.protocolId, 'gree.yx1fsf');
  });
}
