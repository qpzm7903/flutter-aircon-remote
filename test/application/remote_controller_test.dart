import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aircon_remote/application/remote_controller.dart';
import 'package:flutter_aircon_remote/application/remote_event.dart';
import 'package:flutter_aircon_remote/application/theme_controller.dart';
import 'package:flutter_aircon_remote/domain/ac_state.dart';
import 'package:flutter_aircon_remote/domain/ac_enums.dart';
import 'package:flutter_aircon_remote/infrastructure/ir/fake_ir_transmitter.dart';
import 'package:flutter_aircon_remote/infrastructure/ir/ir_transmitter.dart';
import 'package:flutter_aircon_remote/protocol/protocol_registry.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_protocol.dart';
import 'package:flutter_aircon_remote/protocol/gree/gree_state_codec.dart';

import '../support/in_memory_remote_repository.dart';
import '../support/gree_vectors.dart';

void main() {
  late InMemoryRemoteRepository repo;
  late FakeIrTransmitter ir;
  late RemoteController c;
  setUp(() {
    repo = InMemoryRemoteRepository();
    ir = FakeIrTransmitter();
    c = RemoteController(
      registry: AcProtocolRegistry([
        GreeProtocol(GreeModel.yaw1f),
        GreeProtocol(GreeModel.ybofb),
      ]),
      transmitter: ir,
      repository: repo,
    );
  });
  tearDown(() => c.dispose());
  test('init restores normalized state and never sends', () async {
    repo.id = 'gree.ybofb';
    repo.states[repo.id!] = const AcState.initial().copyWith(
      mode: AcMode.auto,
      targetTempC: 50,
    );
    await c.init();
    expect(c.protocol.id, repo.id);
    expect(c.state.targetTempC, 25);
    expect(ir.sent, isEmpty);
    expect(c.irAvailability, IrAvailability.available);
  });
  test('button sends known real-cool reference frame and persists', () async {
    await c.init();
    await c.update((_) => greeVectors[1].state);
    expect(ir.sent.single.debugHex, '19 0A 60 50 02 23 00 F0');
    expect(repo.states[c.protocol.id], c.state);
  });
  test('burst coalesces latest state without concurrent transmit', () async {
    await c.init();
    ir.delay = const Duration(milliseconds: 10);
    final futures = [
      c.stepTemp(1),
      c.stepTemp(1),
      c.stepTemp(1),
      c.stepTemp(1),
    ];
    expect(c.isSending, true);
    await Future.wait(futures);
    expect(ir.maxActive, 1);
    expect(ir.sent.length, 2);
    expect(ir.sent.last.debugHex, c.protocol.encode(c.state).debugHex);
    expect(c.state.targetTempC, 30);
    expect(c.isSending, false);
  });
  test('burst persists states serially so the latest state wins', () async {
    final delayedRepo = _DelayedRemoteRepository();
    final controller = RemoteController(
      registry: c.registry,
      transmitter: ir,
      repository: delayedRepo,
    );
    addTearDown(controller.dispose);
    await controller.init();
    await Future.wait([
      controller.stepTemp(1),
      controller.stepTemp(1),
      controller.stepTemp(1),
    ]);
    expect(delayedRepo.started, hasLength(1));
    final latest = controller.state;
    for (var i = 0; i < 3; i++) {
      expect(delayedRepo.started, hasLength(i + 1));
      delayedRepo.started[i].complete();
      await Future<void>.delayed(Duration.zero);
    }
    expect(delayedRepo.states[controller.protocol.id], latest);
    expect(delayedRepo.started, hasLength(3));
  });
  test('failure emits event and retains optimistic state', () async {
    await c.init();
    ir.failure = const IrTransmitException(
      IrErrorCode.permissionDenied,
      'denied',
    );
    final event = c.events.first;
    await c.togglePower();
    expect(
      await event,
      isA<TransmitFailed>().having(
        (e) => e.code,
        'code',
        IrErrorCode.permissionDenied,
      ),
    );
    expect(c.state.power, true);
  });
  test(
    'success event and unchanged or unavailable states do not send',
    () async {
      await c.init();
      final event = c.events.first;
      await c.togglePower();
      expect(await event, isA<TransmitSucceeded>());
      await c.update((s) => s);
      expect(ir.sent.length, 1);
      ir.hasEmitter = false;
      await c.recheckIr();
      final before = c.state;
      await c.togglePower();
      expect(c.state, before);
      expect(ir.sent.length, 1);
    },
  );
  test(
    'protocols retain independent state without sending on switch',
    () async {
      await c.init();
      await c.stepTemp(1);
      final old = c.state;
      await c.setProtocol('gree.ybofb');
      expect(c.state, const AcState.initial());
      expect(ir.sent.length, 1);
      await c.stepTemp(-1);
      await c.setProtocol('gree.yaw1f');
      expect(c.state, old);
      expect(repo.id, 'gree.yaw1f');
      expect(ir.sent.length, 2);
      await c.setProtocol('unknown');
      expect(c.protocol.id, 'gree.yaw1f');
    },
  );
  test(
    'switch during send discards old pending frame and preserves new protocol',
    () async {
      await c.init();
      ir.delay = const Duration(milliseconds: 10);
      final first = c.stepTemp(1);
      final pending = c.stepTemp(1);
      await c.setProtocol('gree.ybofb');
      final next = c.togglePower();
      await Future.wait([first, pending, next]);
      expect(ir.sent.length, 2);
      expect(ir.sent.last.debugHex, '09 0A 20 50 00 20 00 F0');
      expect(ir.maxActive, 1);
    },
  );
  test('corrupt storage and write failures are nonfatal', () async {
    repo.fail = true;
    await c.init();
    expect(c.state, const AcState.initial());
    await c.togglePower();
    expect(ir.sent.length, 1);
  });
  test('unknown saved protocol falls back', () async {
    repo.id = 'unknown';
    await c.init();
    expect(c.protocol.id, 'gree.yaw1f');
  });
  test('theme restores and cycles system light dark', () async {
    final theme = ThemeController(repo);
    addTearDown(theme.dispose);
    await theme.init();
    expect(theme.modeName, 'system');
    await theme.cycle();
    expect(repo.theme, 'light');
    await theme.cycle();
    expect(repo.theme, 'dark');
    await theme.cycle();
    expect(repo.theme, 'system');
  });
}

class _DelayedRemoteRepository extends InMemoryRemoteRepository {
  final started = <Completer<void>>[];

  @override
  Future<void> saveState(String protocolId, AcState state) async {
    final gate = Completer<void>();
    started.add(gate);
    await gate.future;
    await super.saveState(protocolId, state);
  }
}
