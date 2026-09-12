import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../core/models/session_kind.dart';
import '../core/repositories/progress_repository.dart';
import '../core/services/distractor_picker.dart';
import '../core/services/word_selection_service.dart';
import 'home_providers.dart';
import 'immersion_mode_providers.dart';
import 'repository_providers.dart';

class StudyQuestion {
  const StudyQuestion({
    required this.word,
    required this.options,
    required this.isNewWord,
  });

  final Word word;
  final List<DistractorCandidate> options;

  /// True when there was no `word_progress` row for this word at the
  /// moment the session was built -- i.e. the learner has never been
  /// shown it before. Drives whether the "Aprender" step precedes the
  /// multiple-choice question for it.
  final bool isNewWord;
}

class StudySessionState {
  const StudySessionState({
    this.items = const [],
    this.currentIndex = 0,
    this.selectedWordId,
    this.isAnswered = false,
    this.sessionCorrectCount = 0,
    this.sessionXpEarned = 0,
    this.lastResult,
    this.isLoading = true,
    this.isLearningStep = false,
    this.immersionModeEnabled = false,
    this.isWordTranslationRevealed = false,
    this.isSentenceTranslationRevealed = false,
  });

  final List<StudyQuestion> items;
  final int currentIndex;
  final String? selectedWordId;
  final bool isAnswered;
  final int sessionCorrectCount;
  final int sessionXpEarned;
  final AnswerResult? lastResult;
  final bool isLoading;

  /// True while showing the "Aprender" step (word/translation/example,
  /// each with a listen button) for the current question, before the
  /// multiple-choice "Testar" step. True for a question whose
  /// [StudyQuestion.isNewWord] is true, or for any question at all when
  /// [immersionModeEnabled] is on.
  final bool isLearningStep;

  /// Captured once when the session loads, from `immersionModeEnabledProvider`
  /// -- fixed for the whole session even if the (currently unreachable
  /// mid-session) setting were changed elsewhere, matching "it's just a
  /// setting for the current session".
  final bool immersionModeEnabled;

  /// Whether the current question's translation/sentence-translation are
  /// shown yet. Both start true for a brand-new word (nothing to "try to
  /// recall" first) and false for an already-known word shown via Modo
  /// Imersão, revealed on demand via [StudySessionController
  /// .revealWordTranslation]/[StudySessionController
  /// .revealSentenceTranslation]. Only meaningful while [isLearningStep] is
  /// true -- stale in between, since nothing else reads them.
  final bool isWordTranslationRevealed;
  final bool isSentenceTranslationRevealed;

  /// Only ever true if the word bank itself is empty/unreachable -- see
  /// `StudySessionController.nextQuestion`, which always extends [items]
  /// with another batch before letting [currentIndex] cross its end. A
  /// real study session never runs out of words on its own; this is a
  /// defensive fallback, not the normal way a session ends.
  bool get isComplete => !isLoading && currentIndex >= items.length;
  StudyQuestion get currentQuestion => items[currentIndex];

  StudySessionState copyWith({
    List<StudyQuestion>? items,
    int? currentIndex,
    String? selectedWordId,
    bool clearSelectedWordId = false,
    bool? isAnswered,
    int? sessionCorrectCount,
    int? sessionXpEarned,
    AnswerResult? lastResult,
    bool? isLoading,
    bool? isLearningStep,
    bool? immersionModeEnabled,
    bool? isWordTranslationRevealed,
    bool? isSentenceTranslationRevealed,
  }) {
    return StudySessionState(
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
      isLearningStep: isLearningStep ?? this.isLearningStep,
      immersionModeEnabled: immersionModeEnabled ?? this.immersionModeEnabled,
      isWordTranslationRevealed:
          isWordTranslationRevealed ?? this.isWordTranslationRevealed,
      isSentenceTranslationRevealed:
          isSentenceTranslationRevealed ?? this.isSentenceTranslationRevealed,
    );
  }
}

/// Drives one study session: builds it from [WordSelectionService] +
/// [DistractorPicker], then records each answer through
/// [ProgressRepository.recordAnswer] -- the same orchestration path the
/// minigame uses.
///
/// The session is infinite by design: [items] is a growing list, fetched
/// in batches of [_kBatchSize]. [nextQuestion] extends it with another
/// batch whenever the learner is about to reach the end, instead of ever
/// treating "this batch is done" as "there is nothing left to study" --
/// [WordSelectionService.buildSession] guarantees a batch is always full
/// as long as the word bank has any active words at all, falling back to
/// maintenance repetition once nothing is strictly due/new/weak.
class StudySessionController extends Notifier<StudySessionState> {
  final String _sessionId = const Uuid().v4();

  static const int _kBatchSize = 10;

  /// True while a batch fetch is in flight -- guards [nextQuestion]
  /// against a double-tap right at a batch boundary appending two batches
  /// instead of one (the await inside it yields control back to the event
  /// loop, unlike the old fully-synchronous version).
  bool _isExtending = false;

  @override
  StudySessionState build() {
    _loadSession();
    return const StudySessionState();
  }

  Future<void> _loadSession() async {
    final immersionModeEnabled = ref.read(immersionModeEnabledProvider);
    final items = await _fetchNextBatch(recentlyShownWordIds: const []);

    final firstIsNew = items.isNotEmpty && items.first.isNewWord;
    state = state.copyWith(
      items: items,
      isLoading: false,
      immersionModeEnabled: immersionModeEnabled,
      isLearningStep: items.isNotEmpty && (firstIsNew || immersionModeEnabled),
      isWordTranslationRevealed: firstIsNew,
      isSentenceTranslationRevealed: firstIsNew,
    );
  }

  /// Fetches and shapes one batch of [_kBatchSize] questions. Returns an
  /// empty list only in the genuinely exceptional case the whole word bank
  /// is empty -- [WordSelectionService.buildSession] otherwise always
  /// returns a full batch (with repetition once nothing new/due remains).
  Future<List<StudyQuestion>> _fetchNextBatch({
    required List<String> recentlyShownWordIds,
  }) async {
    final wordRepository = ref.read(wordRepositoryProvider);
    final progressRepository = ref.read(progressRepositoryProvider);

    final pool = await wordRepository.fetchCandidatePool();
    if (pool.isEmpty) return const [];

    final profile = await progressRepository.fetchUserProfile();
    final activeWords = await wordRepository.fetchActiveWords();
    final distractorPool = await wordRepository.fetchDistractorPool();

    final selected = const WordSelectionService().buildSession(
      pool: pool,
      kind: SessionKind.study,
      userLevel: profile.currentLevel,
      now: DateTime.now(),
      count: _kBatchSize,
      recentlyShownWordIds: recentlyShownWordIds,
    );

    final wordsById = {for (final w in activeWords) w.id: w};
    return selected
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
          return StudyQuestion(
            word: word,
            options: options,
            isNewWord: !candidate.hasBeenIntroduced,
          );
        })
        .whereType<StudyQuestion>()
        .toList();
  }

  /// Advances past the "Aprender" step into "Testar" for the current
  /// question -- called by the Learn step's CONTINUAR button.
  void finishLearningStep() {
    if (!state.isLearningStep) return;
    state = state.copyWith(isLearningStep: false);
  }

  /// Reveals the current question's word translation on demand. Purely
  /// local UI state -- never touches `ProgressRepository`, so looking up a
  /// translation is never counted as a correct answer.
  void revealWordTranslation() {
    if (state.isWordTranslationRevealed) return;
    state = state.copyWith(isWordTranslationRevealed: true);
  }

  /// Same as [revealWordTranslation], for the example sentence's
  /// translation.
  void revealSentenceTranslation() {
    if (state.isSentenceTranslationRevealed) return;
    state = state.copyWith(isSentenceTranslationRevealed: true);
  }

  void selectOption(String wordId) {
    if (state.isLearningStep || state.isAnswered || state.isLoading || state.isComplete) {
      return;
    }
    state = state.copyWith(selectedWordId: wordId);
  }

  Future<void> submitAnswer() async {
    if (state.isLearningStep || state.isAnswered || state.isLoading || state.isComplete) {
      return;
    }
    final selectedWordId = state.selectedWordId;
    if (selectedWordId == null) return;

    final question = state.currentQuestion;
    final wasCorrect = selectedWordId == question.word.id;

    final result = await ref
        .read(progressRepositoryProvider)
        .recordAnswer(
          wordId: question.word.id,
          wasCorrect: wasCorrect,
          exerciseType: 'multiple_choice',
          sessionKind: SessionKind.study,
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

  /// Advances to the next question, extending [items] with another batch
  /// first if the learner has reached its end -- the mechanism that keeps
  /// "Estudar" from ever dead-ending into "Sessão concluída"/"Nenhuma
  /// palavra disponível" just because one batch ran out.
  Future<void> nextQuestion() async {
    if (!state.isAnswered || _isExtending) return;
    final newIndex = state.currentIndex + 1;

    if (newIndex >= state.items.length) {
      _isExtending = true;
      try {
        final recentlyShown = state.items
            .skip((state.items.length - 5).clamp(0, state.items.length))
            .map((q) => q.word.id)
            .toList();
        final nextBatch = await _fetchNextBatch(
          recentlyShownWordIds: recentlyShown,
        );
        if (nextBatch.isNotEmpty) {
          state = state.copyWith(items: [...state.items, ...nextBatch]);
        }
      } finally {
        _isExtending = false;
      }
    }

    final items = state.items;
    final nextIsNew = newIndex < items.length && items[newIndex].isNewWord;
    final nextIsLearning =
        newIndex < items.length &&
        (nextIsNew || state.immersionModeEnabled);
    state = state.copyWith(
      currentIndex: newIndex,
      isAnswered: false,
      clearSelectedWordId: true,
      isLearningStep: nextIsLearning,
      isWordTranslationRevealed: nextIsNew,
      isSentenceTranslationRevealed: nextIsNew,
    );
  }
}

final studySessionProvider =
    NotifierProvider.autoDispose<StudySessionController, StudySessionState>(
      StudySessionController.new,
    );
