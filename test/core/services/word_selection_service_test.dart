import 'package:dino_english/core/models/session_kind.dart';
import 'package:dino_english/core/models/word_candidate.dart';
import 'package:dino_english/core/services/word_selection_service.dart';
import 'package:flutter_test/flutter_test.dart';

WordCandidate _newWord(String id, {int recommendedLevel = 1}) => WordCandidate(
  wordId: id,
  category: 'animals',
  recommendedLevel: recommendedLevel,
  masteryLevel: 0,
  hasBeenIntroduced: false,
);

WordCandidate _overdueWord(String id, DateTime dueAt) => WordCandidate(
  wordId: id,
  category: 'animals',
  recommendedLevel: 1,
  masteryLevel: 2,
  hasBeenIntroduced: true,
  nextReviewAt: dueAt,
  lastResultCorrect: true,
);

WordCandidate _weakWord(String id) => WordCandidate(
  wordId: id,
  category: 'animals',
  recommendedLevel: 1,
  masteryLevel: 1,
  hasBeenIntroduced: true,
  nextReviewAt: DateTime(2020),
  lastResultCorrect: false,
);

WordCandidate _maintenanceWord(String id, DateTime dueAt) => WordCandidate(
  wordId: id,
  category: 'animals',
  recommendedLevel: 1,
  masteryLevel: 5,
  hasBeenIntroduced: true,
  nextReviewAt: dueAt,
  lastResultCorrect: true,
);

WordCandidate _notYetDueWord(String id) => WordCandidate(
  wordId: id,
  category: 'animals',
  recommendedLevel: 1,
  masteryLevel: 2,
  hasBeenIntroduced: true,
  nextReviewAt: DateTime(2100),
  lastResultCorrect: true,
);

List<WordCandidate> _many(int n, WordCandidate Function(String id) build) =>
    List.generate(n, (i) => build('w$i'));

void main() {
  final service = WordSelectionService();
  final now = DateTime(2026, 1, 10);
  final overdueAt = DateTime(2026, 1, 1);

  test('study mix respects the 40/30/20/10 target when every bucket is abundant', () {
    final pool = [
      ..._many(10, (id) => _newWord('new_$id')),
      ..._many(10, (id) => _overdueWord('overdue_$id', overdueAt)),
      ..._many(10, (id) => _weakWord('weak_$id')),
      ..._many(10, (id) => _maintenanceWord('maint_$id', overdueAt)),
    ];

    final session = service.buildSession(
      pool: pool,
      kind: SessionKind.study,
      userLevel: 5,
      now: now,
      count: 10,
    );

    expect(session, hasLength(10));
    expect(session.where((c) => c.wordId.startsWith('new_')).length, 4);
    expect(session.where((c) => c.wordId.startsWith('overdue_')).length, 3);
    expect(session.where((c) => c.wordId.startsWith('weak_')).length, 2);
    expect(session.where((c) => c.wordId.startsWith('maint_')).length, 1);
  });

  test('review mix never includes new words and favors overdue/weak', () {
    final pool = [
      ..._many(10, (id) => _newWord('new_$id')),
      ..._many(10, (id) => _overdueWord('overdue_$id', overdueAt)),
      ..._many(10, (id) => _weakWord('weak_$id')),
      ..._many(10, (id) => _maintenanceWord('maint_$id', overdueAt)),
    ];

    final session = service.buildSession(
      pool: pool,
      kind: SessionKind.review,
      userLevel: 5,
      now: now,
      count: 10,
    );

    expect(session, hasLength(10));
    expect(session.where((c) => c.wordId.startsWith('new_')).length, 0);
    expect(session.where((c) => c.wordId.startsWith('overdue_')).length, 5);
    expect(session.where((c) => c.wordId.startsWith('weak_')).length, 3);
    expect(session.where((c) => c.wordId.startsWith('maint_')).length, 2);
  });

  test('backfills from overdue/weak/maintenance when there are no new words at all', () {
    final pool = [
      ..._many(10, (id) => _overdueWord('overdue_$id', overdueAt)),
      ..._many(10, (id) => _weakWord('weak_$id')),
      ..._many(10, (id) => _maintenanceWord('maint_$id', overdueAt)),
    ];

    final session = service.buildSession(
      pool: pool,
      kind: SessionKind.study,
      userLevel: 5,
      now: now,
      count: 10,
    );

    expect(session, hasLength(10), reason: 'missing new words should be backfilled, not leave gaps');
  });

  test('returns fewer than requested rather than duplicating when the whole pool is small', () {
    final pool = [
      _overdueWord('only_overdue', overdueAt),
      _weakWord('only_weak'),
    ];

    final session = service.buildSession(
      pool: pool,
      kind: SessionKind.study,
      userLevel: 5,
      now: now,
      count: 10,
    );

    expect(session, hasLength(2));
    expect(session.map((c) => c.wordId).toSet(), hasLength(2));
  });

  test('never selects the same word twice in one session', () {
    final pool = [
      ..._many(10, (id) => _newWord('new_$id')),
      ..._many(10, (id) => _overdueWord('overdue_$id', overdueAt)),
      ..._many(10, (id) => _weakWord('weak_$id')),
      ..._many(10, (id) => _maintenanceWord('maint_$id', overdueAt)),
    ];

    final session = service.buildSession(
      pool: pool,
      kind: SessionKind.study,
      userLevel: 5,
      now: now,
      count: 25,
    );

    expect(session.map((c) => c.wordId).toSet(), hasLength(session.length));
  });

  test('a word not yet due and never introduced-wrong is excluded entirely', () {
    final pool = [_notYetDueWord('sleeping')];

    final session = service.buildSession(
      pool: pool,
      kind: SessionKind.study,
      userLevel: 5,
      now: now,
      count: 10,
    );

    expect(session, isEmpty);
  });

  test('a new word above the recommended-level buffer is not offered yet', () {
    final pool = [
      _newWord('too_advanced', recommendedLevel: 50),
      _newWord('in_range', recommendedLevel: 6),
    ];

    final session = service.buildSession(
      pool: pool,
      kind: SessionKind.study,
      userLevel: 5, // buffer defaults to 3, so eligible up to level 8
      now: now,
      count: 10,
    );

    expect(session.map((c) => c.wordId), contains('in_range'));
    expect(session.map((c) => c.wordId), isNot(contains('too_advanced')));
  });
}
