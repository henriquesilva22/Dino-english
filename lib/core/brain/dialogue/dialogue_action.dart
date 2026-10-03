import '../model/dino_enums.dart';

enum DialogueActionType {
  speak,
  ask,
  waitForAnswer,
  playAnimation,
  startActivity,
  giveReward,
  updateNeed,
  goToObject,
  sleep,
  wakeUp,
  care,
}

/// What the brain wants to happen, in order. The brain only decides; the
/// UI/game layer executes (TTS, 3D animation, navigation, XP...). New
/// systems (needs, room objects) plug in by handling more action types --
/// the brain doesn't change.
sealed class DialogueAction {
  const DialogueAction();

  DialogueActionType get type;
}

/// A line the Dino says (and the TTS reads). [translation] is an optional
/// Portuguese subtitle for the child, never spoken.
class SpeakAction extends DialogueAction {
  const SpeakAction(this.text, {this.translation});

  final String text;
  final String? translation;

  @override
  DialogueActionType get type => DialogueActionType.speak;
}

/// Like [SpeakAction], but a question: the UI may highlight it and offer
/// [suggestions] as quick-reply chips.
class AskAction extends DialogueAction {
  const AskAction(this.text, {this.translation, this.suggestions = const []});

  final String text;
  final String? translation;
  final List<String> suggestions;

  @override
  DialogueActionType get type => DialogueActionType.ask;
}

/// The Dino waits for the child's answer (future: idle "thinking" pose,
/// reminder after [timeout]).
class WaitForAnswerAction extends DialogueAction {
  const WaitForAnswerAction({this.timeout});

  final Duration? timeout;

  @override
  DialogueActionType get type => DialogueActionType.waitForAnswer;
}

class PlayAnimationAction extends DialogueAction {
  const PlayAnimationAction(this.animation);

  final DinoAnimation animation;

  @override
  DialogueActionType get type => DialogueActionType.playAnimation;
}

class StartActivityAction extends DialogueAction {
  const StartActivityAction(this.activity);

  final DinoActivity activity;

  @override
  DialogueActionType get type => DialogueActionType.startActivity;
}

/// Grants XP through the existing progress pipeline. [wordId] (when set)
/// also moves that word's SRS progress as a correct answer.
class GiveRewardAction extends DialogueAction {
  const GiveRewardAction({
    required this.xp,
    this.wordId,
    required this.reason,
    this.countsAsExercise = true,
  });

  final int xp;
  final String? wordId;
  final String reason;

  /// False for "bonus" XP (learning a word, caring for the Dino) that
  /// must not count towards the daily active-day/streak threshold.
  final bool countsAsExercise;

  @override
  DialogueActionType get type => DialogueActionType.giveReward;
}

class UpdateNeedAction extends DialogueAction {
  const UpdateNeedAction(this.need, this.delta);

  final DinoNeed need;

  /// Change in the 0..1 satisfied level (+ = better).
  final double delta;

  @override
  DialogueActionType get type => DialogueActionType.updateNeed;
}

class GoToObjectAction extends DialogueAction {
  const GoToObjectAction(this.target);

  final DinoObject target;

  @override
  DialogueActionType get type => DialogueActionType.goToObject;
}

class SleepAction extends DialogueAction {
  const SleepAction();

  @override
  DialogueActionType get type => DialogueActionType.sleep;
}

class WakeUpAction extends DialogueAction {
  const WakeUpAction();

  @override
  DialogueActionType get type => DialogueActionType.wakeUp;
}

/// The child asked the Dino to eat, drink, play or sleep. The companion
/// layer applies it to the persisted needs (and decides the XP); the
/// brain has already said its line.
class CareAction extends DialogueAction {
  const CareAction(this.care);

  final DinoCare care;

  @override
  DialogueActionType get type => DialogueActionType.care;
}
