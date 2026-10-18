import '../domain/ac_device.dart';
import '../domain/ir_error_code.dart';
import '../protocol/protocol_registry.dart';
export '../domain/ir_error_code.dart';

enum WizardMode { create, repair }

enum WizardStep { intro, info, brand, pairing }

enum PairingPhase { idle, sending, awaitingAnswer, sendFailed, exhausted }

final class WizardOutcome {
  const WizardOutcome({
    required this.protocolId,
    required this.pairingConfirmed,
    this.name = '',
    this.room = '',
    this.icon = AcIcon.generic,
  });
  final String protocolId, name, room;
  final bool pairingConfirmed;
  final AcIcon icon;
  @override
  bool operator ==(Object other) =>
      other is WizardOutcome &&
      protocolId == other.protocolId &&
      pairingConfirmed == other.pairingConfirmed &&
      name == other.name &&
      room == other.room &&
      icon == other.icon;
  @override
  int get hashCode =>
      Object.hash(protocolId, pairingConfirmed, name, room, icon);
}

final class WizardState {
  const WizardState({
    this.mode = WizardMode.create,
    this.step = WizardStep.intro,
    this.name = '',
    this.room = '',
    this.icon = AcIcon.generic,
    this.nameInvalid = false,
    this.brandId,
    this.candidateIds = const [],
    this.candidateIndex = 0,
    this.phase = PairingPhase.idle,
    this.probeSeq = 0,
    this.resendCount = 0,
    this.sendError,
    this.selectedFallbackId,
    this.irAvailable = false,
    this.outcome,
    this.originalProtocolId,
  });
  final WizardMode mode;
  final WizardStep step;
  final String name, room;
  final AcIcon icon;
  final bool nameInvalid, irAvailable;
  final String? brandId, selectedFallbackId, originalProtocolId;
  final List<String> candidateIds;
  final int candidateIndex, probeSeq, resendCount;
  final PairingPhase phase;
  final IrErrorCode? sendError;
  final WizardOutcome? outcome;
  WizardState copyWith({
    WizardStep? step,
    String? name,
    String? room,
    AcIcon? icon,
    bool? nameInvalid,
    String? brandId,
    List<String>? candidateIds,
    int? candidateIndex,
    PairingPhase? phase,
    int? probeSeq,
    int? resendCount,
    IrErrorCode? sendError,
    String? selectedFallbackId,
    WizardOutcome? outcome,
  }) => WizardState(
    mode: mode,
    step: step ?? this.step,
    name: name ?? this.name,
    room: room ?? this.room,
    icon: icon ?? this.icon,
    nameInvalid: nameInvalid ?? this.nameInvalid,
    brandId: brandId ?? this.brandId,
    candidateIds: List.unmodifiable(candidateIds ?? this.candidateIds),
    candidateIndex: candidateIndex ?? this.candidateIndex,
    phase: phase ?? this.phase,
    probeSeq: probeSeq ?? this.probeSeq,
    resendCount: resendCount ?? this.resendCount,
    sendError: sendError,
    selectedFallbackId: selectedFallbackId ?? this.selectedFallbackId,
    irAvailable: irAvailable,
    outcome: outcome ?? this.outcome,
    originalProtocolId: originalProtocolId,
  );
  @override
  bool operator ==(Object other) =>
      other is WizardState &&
      mode == other.mode &&
      step == other.step &&
      name == other.name &&
      room == other.room &&
      icon == other.icon &&
      nameInvalid == other.nameInvalid &&
      brandId == other.brandId &&
      candidateIds.join('|') == other.candidateIds.join('|') &&
      candidateIndex == other.candidateIndex &&
      phase == other.phase &&
      probeSeq == other.probeSeq &&
      resendCount == other.resendCount &&
      sendError == other.sendError &&
      selectedFallbackId == other.selectedFallbackId &&
      irAvailable == other.irAvailable &&
      outcome == other.outcome &&
      originalProtocolId == other.originalProtocolId;
  @override
  int get hashCode => Object.hash(
    mode,
    step,
    name,
    room,
    icon,
    nameInvalid,
    brandId,
    Object.hashAll(candidateIds),
    candidateIndex,
    phase,
    probeSeq,
    resendCount,
    sendError,
    selectedFallbackId,
    irAvailable,
    outcome,
    originalProtocolId,
  );
}

sealed class WizardEvent {
  const WizardEvent();
}

final class Next extends WizardEvent {
  const Next();
}

final class Back extends WizardEvent {
  const Back();
}

final class SetName extends WizardEvent {
  const SetName(this.value);
  final String value;
}

final class SetRoom extends WizardEvent {
  const SetRoom(this.value);
  final String value;
}

final class SetIcon extends WizardEvent {
  const SetIcon(this.value);
  final AcIcon value;
}

final class SetBrand extends WizardEvent {
  const SetBrand(this.value);
  final String value;
}

final class StartPairing extends WizardEvent {
  const StartPairing();
}

final class ProbeResult extends WizardEvent {
  const ProbeResult(this.seq, this.error);
  final int seq;
  final IrErrorCode? error;
}

final class AnswerYes extends WizardEvent {
  const AnswerYes();
}

final class AnswerNo extends WizardEvent {
  const AnswerNo();
}

final class Resend extends WizardEvent {
  const Resend();
}

final class SelectFallback extends WizardEvent {
  const SelectFallback(this.protocolId);
  final String protocolId;
}

final class SaveFallback extends WizardEvent {
  const SaveFallback();
}

final class Skip extends WizardEvent {
  const Skip();
}

sealed class WizardEffect {}

final class SendProbe extends WizardEffect {
  SendProbe(this.seq, this.protocolId);
  final int seq;
  final String protocolId;
}

final class Complete extends WizardEffect {
  Complete(this.outcome);
  final WizardOutcome outcome;
}

final class WizardTransition {
  const WizardTransition(this.state, [this.effects = const []]);
  final WizardState state;
  final List<WizardEffect> effects;
}

class AddDeviceWizard {
  AddDeviceWizard({required this.registry});
  final AcProtocolRegistry registry;
  WizardState initial({required bool irAvailable, AcDevice? repairing}) {
    if (repairing == null) return WizardState(irAvailable: irAvailable);
    final p = registry.byId(repairing.protocolId) ?? registry.fallback;
    return WizardState(
      mode: WizardMode.repair,
      step: WizardStep.pairing,
      irAvailable: irAvailable,
      brandId: p.brandId,
      candidateIds: List.unmodifiable(
        registry.modelsOf(p.brandId).map((p) => p.id),
      ),
      selectedFallbackId: p.id,
      originalProtocolId: p.id,
    );
  }

  WizardTransition handle(WizardState s, WizardEvent e) {
    WizardTransition change(WizardState n) => WizardTransition(n);
    WizardTransition finish(String id, bool confirmed) {
      final o = WizardOutcome(
        protocolId: id,
        pairingConfirmed: confirmed,
        name: s.name.trim(),
        room: s.room.trim(),
        icon: s.icon,
      );
      return WizardTransition(s.copyWith(outcome: o), [Complete(o)]);
    }

    WizardTransition send(int index, int resends) {
      if (!s.irAvailable) {
        return change(
          s.copyWith(
            phase: PairingPhase.sendFailed,
            sendError: IrErrorCode.noIrEmitter,
          ),
        );
      }
      final n = s.copyWith(
        candidateIndex: index,
        phase: PairingPhase.sending,
        probeSeq: s.probeSeq + 1,
        resendCount: resends,
      );
      return WizardTransition(n, [
        SendProbe(n.probeSeq, n.candidateIds[index]),
      ]);
    }

    if (s.outcome != null) return change(s);
    if (s.step == WizardStep.intro && e is Next) {
      return change(s.copyWith(step: WizardStep.info));
    }
    if (s.step == WizardStep.info) {
      if (e is SetName) {
        return change(s.copyWith(name: e.value, nameInvalid: false));
      }
      if (e is SetRoom) return change(s.copyWith(room: e.value));
      if (e is SetIcon) return change(s.copyWith(icon: e.value));
      if (e is Back) return change(s.copyWith(step: WizardStep.intro));
      if (e is Next) {
        return AcDevice.validateName(s.name) != null ||
                s.room.trim().runes.length > 20
            ? change(s.copyWith(nameInvalid: true))
            : change(
                s.copyWith(
                  step: WizardStep.brand,
                  brandId: s.brandId ?? registry.brandIds.first,
                ),
              );
      }
    }
    if (s.step == WizardStep.brand) {
      if (e is SetBrand && registry.brandIds.contains(e.value)) {
        return change(s.copyWith(brandId: e.value));
      }
      if (e is Back) return change(s.copyWith(step: WizardStep.info));
      if ((e is Next || e is StartPairing) && s.brandId != null) {
        return change(
          s.copyWith(
            step: WizardStep.pairing,
            phase: PairingPhase.idle,
            candidateIndex: 0,
            candidateIds: registry
                .modelsOf(s.brandId!)
                .map((p) => p.id)
                .toList(),
          ),
        );
      }
    }
    if (s.step != WizardStep.pairing || s.candidateIds.isEmpty) {
      return change(s);
    }
    if (e is Back && s.mode == WizardMode.create) {
      return change(
        s.copyWith(
          step: WizardStep.brand,
          phase: PairingPhase.idle,
          probeSeq: s.probeSeq + 1,
        ),
      );
    }
    if (e is Skip) {
      return finish(
        s.mode == WizardMode.repair
            ? s.originalProtocolId!
            : s.candidateIds.first,
        false,
      );
    }
    if (e is StartPairing && s.phase != PairingPhase.sending) return send(0, 0);
    if (e is ProbeResult &&
        s.phase == PairingPhase.sending &&
        e.seq == s.probeSeq) {
      return change(
        s.copyWith(
          phase: e.error == null
              ? PairingPhase.awaitingAnswer
              : PairingPhase.sendFailed,
          sendError: e.error,
        ),
      );
    }
    if (s.phase == PairingPhase.awaitingAnswer) {
      if (e is AnswerYes) return finish(s.candidateIds[s.candidateIndex], true);
      if (e is AnswerNo) {
        return s.candidateIndex + 1 < s.candidateIds.length
            ? send(s.candidateIndex + 1, 0)
            : change(
                s.copyWith(
                  phase: PairingPhase.exhausted,
                  selectedFallbackId:
                      s.selectedFallbackId ?? s.candidateIds.first,
                ),
              );
      }
    }
    if (e is Resend &&
        s.irAvailable &&
        (s.phase == PairingPhase.awaitingAnswer ||
            s.phase == PairingPhase.sendFailed)) {
      return send(s.candidateIndex, s.resendCount + 1);
    }
    if (s.phase == PairingPhase.exhausted) {
      if (e is SelectFallback && s.candidateIds.contains(e.protocolId)) {
        return change(s.copyWith(selectedFallbackId: e.protocolId));
      }
      if (e is SaveFallback) {
        return finish(s.selectedFallbackId ?? s.candidateIds.first, false);
      }
    }
    return change(s);
  }
}
