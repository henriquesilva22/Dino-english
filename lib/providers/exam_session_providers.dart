import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../core/models/session_kind.dart';
import '../core/repositories/progress_repository.dart';
import '../core/services/distractor_picker.dart';
import '../core/services/word_selection_service.dart';
import 'home_providers.dart';
import 'repository_providers.dart';

class ExamQuestion {
  const ExamQuestion({required this.word, required this.options});

  final Word word;
  final List<DistractorCandidate> options;
}

class ExamSessionState {
  const ExamSessionState({
    this.items = const [],
    this.currentIndex = 0,
    this.selectedWordId,
    this.isAnswered = false,
    this.sessionCorrectCount = 0,
    this.sessionXpEarned = 0,
    this.lastResult,
    this.isLoading = true,
  });

  final List<ExamQuestion> items;
  final int currentIndex;
  final String? selectedWordId;
  final bool isAnswered;
  final int sessionCorrectCount;
  final int sessionXpEarned;
  final AnswerResult? lastResult;
  final bool isLoading;

  bool get isComplete => !isLoading && currentIndex >= items.length;
  ExamQuestion get currentQuestion => items[currentIndex];

  ExamSessionState copyWith({
    List<ExamQuestion>? items,
    int? currentIndex,
    String? selectedWordId,
    bool clearSelectedWordId = false,
    bool? isAnswered,
    int? sessionCorrectCount,
    int? sessionXpEarned,
    AnswerResult? lastResult,
    bool? isLoading,
  }) {
    return ExamSessionState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedWordId: clearSelectedWordId
          ? null
          : (selectedWordId ?? this.selectedWordId),
      isAnswered: isAnswered ?? this.isAnswered,
      sessionCorrectCount: sessionCorrectCount ?? this.sessionCorrectCount,
      sessionXpEarned: sessionXpEarned ?? this.sessionXpEarned,
      lastResult: lastResult ?? this.lastResult,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Drives one "Provas" session -- deliberately a separate controller from
/// [StudySessionController] (not a parametrized reuse of it), matching
/// this project's established pattern of one dedicated `Notifier` per
/// mode. The only real difference from Estudar is the word mix: selection
/// uses [SessionKind.review] (0% new / 50% overdue / 30% weak / 20%
/// maintenance -- "test what's already been seen"), while `recordAnswer`
/// labels every attempt with [SessionKind.exam]. Multiple-choice mechanic
/// and [DistractorPicker] are reused as-is; only the word mix and the
/// stored label change.
class ExamSessionController extends Notifier<ExamSessionState> {
  final String _sessionId = const Uuid().v4();

  @override
  ExamSessionState build() {
    _loadSession();
    return const ExamSessionState();
  }

  Future<void> _loadSession() async {
    final wordRepository = ref.read(wordRepositoryProvider);
    final progressRepository = ref.read(progressRepositoryProvider);

    final pool = await wordRepository.fetchCandidatePool();
    final profile = await progressRepository.fetchUserProfile();
    final activeWords = await wordRepository.fetchActiveWords();
    final distractorPool = await wordRepository.fetchDistractorPool();

    final selected = const WordSelectionService().buildSession(
      pool: pool,
      kind: SessionKind.review,
      userLevel: profile.currentLevel,
      now: DateTime.now(),
    );

    final wordsById = {for (final w in activeWords) w.id: w};
    final items = selected
        .map((candidate) {
          final word = wordsById[candidate.wordId];
          if (word == null) return null;
          final correct = DistractorCandidate(
            wordId: word.id,
            answerText: word.portugueseTranslation,
            category: word.category,
            difficulty: word.difficulty,
          );
          final distractors = const DistractorPicker().pickDistractors(
            correct: correct,
            pool: distractorPool,
          );
          final options = [...distractors, correct]..shuffle();
          return ExamQuestion(word: word, options: options);
        })
        .whereType<ExamQuestion>()
        .toList();

    state = state.copyWith(items: items, isLoading: false);
  }

  void selectOption(String wordId) {
    if (state.isAnswered || state.isLoading || state.isComplete) return;
    state = state.copyWith(selectedWordId: wordId);
  }

  Future<void> submitAnswer() async {
    if (state.isAnswered || state.isLoading || state.isComplete) return;
    final selectedWordId = state.selectedWordId;
    if (selectedWordId == null) return;

    final question = state.currentQuestion;
    final wasCorrect = selectedWordId == question.word.id;

    final result = await ref
        .read(progressRepositoryProvider)
        .recordAnswer(
          wordId: question.word.id,
          wasCorrect: wasCorrect,
          exerciseType: 'exam_multiple_choice',
          sessionKind: SessionKind.exam,
          sessionId: _sessionId,
          userAnswer: selectedWordId,
        );

    ref.invalidate(masteryStatsProvider);
    ref.invalidate(eggProgressProvider);

    state = state.copyWith(
      isAnswered: true,
      sessionCorrectCount: state.sessionCorrectCount + (wasCorrect ? 1 : 0),
      sessionXpEarned: state.sessionXpEarned + result.xpAwarded,
      lastResult: result,
    );
  }

  void nextQuestion() {
    if (!state.isAnswered) return;
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      isAnswered: false,
      clearSelectedWordId: true,
    );
  }
}

final examSessionProvider =
    NotifierProvider.autoDispose<ExamSessionController, ExamSessionState>(
      ExamSessionController.new,
    );
