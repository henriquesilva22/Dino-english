import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../core/models/sentence_challenge.dart';
import '../core/models/session_kind.dart';
import '../core/repositories/progress_repository.dart';
import '../core/services/sentence_builder_service.dart';
import '../core/services/word_selection_service.dart';
import 'home_providers.dart';
import 'repository_providers.dart';

class SentenceBuilderState {
  const SentenceBuilderState({
    this.challenges = const [],
    this.currentIndex = 0,
    this.placedTokenIds = const [],
    this.selectedBlankAnswers = const {},
    this.isSubmitted = false,
    this.isCorrect = false,
    this.sessionCorrectCount = 0,
    this.sessionXpEarned = 0,
    this.streakThisSession = 0,
    this.lastResult,
    this.isLoading = true,
  });

  final List<SentenceChallenge> challenges;
  final int currentIndex;

  /// Assemble mechanism: [BankToken.id]s, in the order the learner tapped
  /// them into the answer strip.
  final List<String> placedTokenIds;

  /// Fill-blank mechanism: [SentenceBlank.tokenIndex] -> chosen option.
  final Map<int, String> selectedBlankAnswers;

  final bool isSubmitted;
  final bool isCorrect;
  final int sessionCorrectCount;
  final int sessionXpEarned;

  /// Consecutive correct answers so far this session -- drives the
  /// Dino's "you're getting better!" reaction; resets on a miss.
  final int streakThisSession;

  final AnswerResult? lastResult;
  final bool isLoading;

  bool get isComplete => !isLoading && currentIndex >= challenges.length;
  SentenceChallenge get currentChallenge => challenges[currentIndex];

  SentenceBuilderState copyWith({
    List<SentenceChallenge>? challenges,
    int? currentIndex,
    List<String>? placedTokenIds,
    Map<int, String>? selectedBlankAnswers,
    bool? isSubmitted,
    bool? isCorrect,
    int? sessionCorrectCount,
    int? sessionXpEarned,
    int? streakThisSession,
    AnswerResult? lastResult,
    bool? isLoading,
  }) {
    return SentenceBuilderState(
      challenges: challenges ?? this.challenges,
      currentIndex: currentIndex ?? this.currentIndex,
      placedTokenIds: placedTokenIds ?? this.placedTokenIds,
      selectedBlankAnswers: selectedBlankAnswers ?? this.selectedBlankAnswers,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isCorrect: isCorrect ?? this.isCorrect,
      sessionCorrectCount: sessionCorrectCount ?? this.sessionCorrectCount,
      sessionXpEarned: sessionXpEarned ?? this.sessionXpEarned,
      streakThisSession: streakThisSession ?? this.streakThisSession,
      lastResult: lastResult ?? this.lastResult,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Drives one "Montar Frase" session: builds challenges from
/// [WordSelectionService] + [SentenceBuilderService] (same pure-service
/// reuse pattern as `StudySessionController`), then records each answer
/// through [ProgressRepository.recordAnswer] -- no separate XP/SRS/streak
/// system, same orchestration path every other exercise uses.
class SentenceBuilderController extends Notifier<SentenceBuilderState> {
  final String _sessionId = const Uuid().v4();

  @override
  SentenceBuilderState build() {
    _loadSession();
    return const SentenceBuilderState();
  }

  Future<void> _loadSession() async {
    final wordRepository = ref.read(wordRepositoryProvider);
    final progressRepository = ref.read(progressRepositoryProvider);

    final pool = await wordRepository.fetchCandidatePool();
    final profile = await progressRepository.fetchUserProfile();
    final activeWords = await wordRepository.fetchActiveWords();

    final selected = const WordSelectionService().buildSession(
      pool: pool,
      kind: SessionKind.study,
      userLevel: profile.currentLevel,
      now: DateTime.now(),
      count: 8, // fewer than Estudar's 10 -- each sentence takes longer
    );

    final wordsById = {for (final w in activeWords) w.id: w};
    const service = SentenceBuilderService();

    final challenges = selected
        .map((candidate) => wordsById[candidate.wordId])
        .whereType<Word>()
        .map(
          (word) => service.buildChallenge(
            targetWord: word,
            otherEnglishTerms: activeWords
                .where((w) => w.id != word.id)
                .map((w) => w.englishTerm)
                .toList(),
          ),
        )
        .toList();

    state = state.copyWith(challenges: challenges, isLoading: false);
  }

  void tapBankToken(String id) {
    if (state.isSubmitted || state.isLoading || state.isComplete) return;
    if (state.placedTokenIds.contains(id)) return;
    state = state.copyWith(placedTokenIds: [...state.placedTokenIds, id]);
  }

  void tapPlacedToken(String id) {
    if (state.isSubmitted || state.isLoading || state.isComplete) return;
    state = state.copyWith(
      placedTokenIds: state.placedTokenIds.where((t) => t != id).toList(),
    );
  }

  void clearPlaced() {
    if (state.isSubmitted || state.isLoading || state.isComplete) return;
    state = state.copyWith(placedTokenIds: const []);
  }

  void selectBlankOption(int tokenIndex, String option) {
    if (state.isSubmitted || state.isLoading || state.isComplete) return;
    state = state.copyWith(
      selectedBlankAnswers: {
        ...state.selectedBlankAnswers,
        tokenIndex: option,
      },
    );
  }

  Future<void> submit() async {
    if (state.isSubmitted || state.isLoading || state.isComplete) return;
    final challenge = state.currentChallenge;
    const service = SentenceBuilderService();

    final bool isCorrect;
    final String userAnswer;
    if (challenge.style.isAssemble) {
      final bankById = {for (final t in challenge.wordBank) t.id: t.text};
      final submittedTexts = state.placedTokenIds
          .map((id) => bankById[id]!)
          .toList();
      isCorrect = service.isAssembleCorrect(challenge, submittedTexts);
      userAnswer = submittedTexts.join(' ');
    } else {
      isCorrect = challenge.blanks.every(
        (b) => service.isBlankCorrect(
          b,
          state.selectedBlankAnswers[b.tokenIndex] ?? '',
        ),
      );
      userAnswer = challenge.blanks
          .map((b) => state.selectedBlankAnswers[b.tokenIndex] ?? '')
          .join(' ');
    }

    final result = await ref
        .read(progressRepositoryProvider)
        .recordAnswer(
          wordId: challenge.word.id,
          wasCorrect: isCorrect,
          exerciseType: 'sentence_builder',
          sessionKind: SessionKind.study,
          sessionId: _sessionId,
          userAnswer: userAnswer,
        );

    ref.invalidate(masteryStatsProvider);
    ref.invalidate(eggProgressProvider);

    state = state.copyWith(
      isSubmitted: true,
      isCorrect: isCorrect,
      sessionCorrectCount: state.sessionCorrectCount + (isCorrect ? 1 : 0),
      sessionXpEarned: state.sessionXpEarned + result.xpAwarded,
      streakThisSession: isCorrect ? state.streakThisSession + 1 : 0,
      lastResult: result,
    );
  }

  void next() {
    if (!state.isSubmitted) return;
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      isSubmitted: false,
      isCorrect: false,
      placedTokenIds: const [],
      selectedBlankAnswers: const {},
    );
  }
}

final sentenceBuilderProvider =
    NotifierProvider.autoDispose<SentenceBuilderController, SentenceBuilderState>(
      SentenceBuilderController.new,
    );
