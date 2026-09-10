import 'dart:math';

import 'package:khoirunnasyien/features/management_santri/domain/entities/santri_entity.dart';

/// Menjaga satu sesi pengundian agar santri yang sudah keluar tidak dapat
/// terpilih kembali sebelum hasil di-reset.
class SessionSpin {
  final List<SantriEntity> _participants;
  final List<SantriEntity> _order = [];

  SessionSpin(Iterable<SantriEntity> participants)
    : _participants = _uniqueParticipants(participants);

  List<SantriEntity> get participants => List.unmodifiable(_participants);
  List<SantriEntity> get order => List.unmodifiable(_order);

  List<SantriEntity> get remaining {
    final drawnIds = _order.map((item) => item.id).toSet();
    return _participants
        .where((participant) => !drawnIds.contains(participant.id))
        .toList(growable: false);
  }

  bool get isComplete => _participants.isNotEmpty && remaining.isEmpty;

  SantriEntity drawNext(Random random) {
    final candidates = remaining;
    if (candidates.isEmpty) {
      throw StateError('Semua peserta sudah mendapat urutan.');
    }
    final selected = candidates[random.nextInt(candidates.length)];
    _order.add(selected);
    return selected;
  }

  void resetOrder() => _order.clear();

  static List<SantriEntity> _uniqueParticipants(
    Iterable<SantriEntity> participants,
  ) {
    final byId = <String, SantriEntity>{};
    for (final participant in participants) {
      final id = participant.id.trim();
      if (id.isNotEmpty) byId.putIfAbsent(id, () => participant);
    }
    return byId.values.toList(growable: false);
  }
}
