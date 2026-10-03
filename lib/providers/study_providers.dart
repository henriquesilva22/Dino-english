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
    this.blockResults = const [],
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

  /// This block's attempts (oldest first), populated once [isComplete]
  /// becomes true -- see `StudySessionController.nextQuestion`. Empty
  /// while the block is still in progress.
  final List<StudyBlockAttempt> blockResults;

  /// True once the learner has answered the block's last
  /// ([StudySessionController.kWordsPerBlock]) question and tapped
  /// "Continuar" -- [items] never grows past that fixed size, so reaching
  /// its end is the normal, expected way a block finishes, not just a
  /// defensive fallback for an empty word bank.
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
    List<StudyBlockAttempt>? blockResults,
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
      blockResults: blockResults ?? this.blockResults,
    );
  }
}

/// Drives one study block of exactly [kWordsPerBlock] words: builds it
/// from [WordSelectionService] + [DistractorPicker], then records each
/// answer through [ProgressRepository.recordAnswer] -- the same
/// orchestration path the minigame uses.
///
/// A block is a fixed size, not an infinite stream: [items] is loaded once
/// (by [_loadSession] on first build, or [startNewBlock] afterwards) and
/// never grows. [nextQuestion] simply advances [currentIndex]; once it
/// would cross [items]'s end, the block is complete (see
/// [StudySessionState.isComplete]) and this fetches that block's own
/// results (see [StudySessionState.blockResults]) for the summary screen,
/// rather than ever fetching more words to keep the session going.
class StudySessionController extends Notifier<StudySessionState> {
  /// One id per block, not per controller instance -- regenerated in
  /// [startNewBlock] so each block's `exercise_attempts` rows (grouped by
  /// this id) never mix with another block's when
  /// `fetchAttemptsForSession` is queried for the results screen.
  String _sessionId = const Uuid().v4();

  /// Fixed number of questions per study block, per spec -- a block never
  /// grows past this, unlike the old (buggy) unbounded-batch design.
  static const int kWordsPerBlock = 10;

  /// True while [nextQuestion] is mid-flight at the block boundary --
  /// guards against a double-tap on "Continuar" firing
  /// `fetchAttemptsForSession` (and the resulting state transition) twice.
  bool _isAdvancing = false;

  @override
  StudySessionState build() {
    _loadSession();
    return const StudySessionState();
  }

  Future<void> _loadSession() async {
    final immersionModeEnabled = ref.read(immersionModeEnabledProvider);
    final items = await _fetchBlockWords(recentlyShownWordIds: const []);

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

  /// Starts a brand-new [kWordsPerBlock]-word block from the results
  /// screen's "Continuar" button -- a fresh [_sessionId] and a fully reset
  /// state (score/combo-equivalent counters, `blockResults`), keeping only
  /// the immersion-mode setting captured at the very first block.
  Future<void> startNewBlock() async {
    final immersionModeEnabled = state.immersionModeEnabled;
    _sessionId = const Uuid().v4();
    state = StudySessionState(immersionModeEnabled: immersionModeEnabled);

    final items = await _fetchBlockWords(recentlyShownWordIds: const []);
    final firstIsNew = items.isNotEmpty && items.first.isNewWord;
    state = StudySessionState(
      items: items,
      isLoading: false,
      immersionModeEnabled: immersionModeEnabled,
      isLearningStep: items.isNotEmpty && (firstIsNew || immersionModeEnabled),
      isWordTranslationRevealed: firstIsNew,
      isSentenceTranslationRevealed: firstIsNew,
    );
  }

  /// Fetches and shapes this block's [kWordsPerBlock] questions in one
  /// shot. Returns an empty list only in the genuinely exceptional case
  /// the whole word bank is empty -- [WordSelectionService.buildSession]
  /// otherwise always returns a full batch (with repetition once nothing
  /// new/due remains).
  Future<List<StudyQuestion>> _fetchBlockWords({
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
      count: kWordsPerBlock,
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
    if (state.isLearningStep ||
        state.isAnswered ||
        state.isLoading ||
        state.isComplete) {
      return;
    }
    state = state.copyWith(selectedWordId: wordId);
  }

  Future<void> submitAnswer() async {
    if (state.isLearningStep ||
        state.isAnswered ||
        state.isLoading ||
        state.isComplete) {
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

  /// Advances to the next question, or -- once the block's fixed
  /// [kWordsPerBlock] questions are all answered -- ends the block: fetches
  /// its own results (via `sessionId`) into [StudySessionState.blockResults]
  /// for the summary screen. No more words are ever fetched past this
  /// point; unlike the old unbounded design, [items] never grows again.
  Future<void> nextQuestion() async {
    if (!state.isAnswered || _isAdvancing) return;
    _isAdvancing = true;
    try {
      final newIndex = state.currentIndex + 1;

      if (newIndex >= state.items.length) {
        final results = await ref
            .read(progressRepositoryProvider)
            .fetchAttemptsForSession(_sessionId);
        state = state.copyWith(
          currentIndex: newIndex,
          isAnswered: false,
          clearSelectedWordId: true,
          blockResults: results,
        );
        return;
      }

      final items = state.items;
      final nextIsNew = items[newIndex].isNewWord;
      final nextIsLearning = nextIsNew || state.immersionModeEnabled;
      state = state.copyWith(
        currentIndex: newIndex,
        isAnswered: false,
        clearSelectedWordId: true,
        isLearningStep: nextIsLearning,
        isWordTranslationRevealed: nextIsNew,
        isSentenceTranslationRevealed: nextIsNew,
      );
    } finally {
      _isAdvancing = false;
    }
  }
}

final studySessionProvider =
    NotifierProvider.autoDispose<StudySessionController, StudySessionState>(
      StudySessionController.new,
    );
