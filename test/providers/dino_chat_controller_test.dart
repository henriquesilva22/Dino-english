import 'dart:async';

import 'package:dino_english/core/brain/context/conversation_context.dart';
import 'package:dino_english/core/brain/model/dino_enums.dart';
import 'package:dino_english/core/companion/companion_response.dart';
import 'package:dino_english/core/companion/companion_engine.dart';
import 'package:dino_english/core/companion/food/food_item.dart';
import 'package:dino_english/core/companion/voice/portuguese_voice.dart';
import 'package:dino_english/core/companion/engine/companion_intent.dart';
import 'package:dino_english/core/companion/voice/companion_voice_service.dart';
import 'package:dino_english/core/companion/voice/speech_recognition_service.dart';
import 'package:dino_english/core/database/app_bootstrap.dart';
import 'package:dino_english/core/database/app_database.dart';
import 'package:dino_english/core/database/seed/word_seed_loader.dart';
import 'package:dino_english/core/speech/speech_service.dart';
import 'package:dino_english/providers/database_providers.dart';
import 'package:dino_english/providers/dino_chat_providers.dart';
import 'package:dino_english/providers/speech_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSpeechService implements SpeechService {
  final List<String> spoken = [];
  final List<String> locales = [];
  final ValueNotifier<Object?> utterance = ValueNotifier(null);

  /// When set, every utterance "plays" until it completes.
  Completer<void>? hold;

  /// Locales without a voice on this fake device.
  final Set<String> missing = {};

  @override
  Future<SpeechResult> speak(
    String text, {
    String locale = kEnglishLocale,
    double? rate,
    double? pitch,
  }) async {
    if (missing.contains(locale)) return SpeechResult.noVoice;
    spoken.add(text);
    locales.add(locale);
    await hold?.future;
    return SpeechResult.spoken;
  }

  @override
  Future<void> stop() async {}

  @override
  ValueListenable<Object?> get activeUtterance => utterance;
}

/// Always-on recognizer without a microphone: tests push [SpeechEvent]s.
class _FakeRecognizer implements SpeechRecognitionService {
  bool available = true;
  MicPermission permission = MicPermission.granted;

  /// What the system dialog answers when asked.
  MicPermission dialogAnswer = MicPermission.granted;
  int permissionRequests = 0;
  int settingsOpened = 0;
  int starts = 0;
  bool running = false;
  bool muted = false;
  SpeechLanguageHint hint = SpeechLanguageHint.auto;
  final StreamController<SpeechEvent> controller =
      StreamController<SpeechEvent>.broadcast();

  void emit(SpeechEvent event) => controller.add(event);

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<MicPermission> checkPermission() async => permission;

  @override
  Future<MicPermission> requestPermission() async {
    permissionRequests++;
    return permission = dialogAnswer;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<bool> start() async {
    if (permission != MicPermission.granted) return false;
    if (!running) starts++;
    running = true;
    return true;
  }

  @override
  Future<void> stop() async => running = false;

  @override
  bool get isRunning => running;

  @override
  void setMuted(bool value) => muted = value;

  @override
  set languageHint(SpeechLanguageHint value) => hint = value;

  @override
  Stream<SpeechEvent> get events => controller.stream;

  @override
  Future<void> dispose() async => running = false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late ProviderContainer container;
  late _FakeSpeechService speech;
  late _FakeRecognizer recognizer;
  late ProviderSubscription<DinoChatState> subscription;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await WordSeedLoader(database).seedIfNeeded();
    await AppBootstrapper(database).ensureSingletonRows();
    speech = _FakeSpeechService();
    recognizer = _FakeRecognizer();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        speechServiceProvider.overrideWithValue(speech),
        portugueseVoiceProvider.overrideWithValue(
          SystemPortugueseVoice(speech),
        ),
        speechRecognitionServiceProvider.overrideWithValue(recognizer),
      ],
    );
    subscription = container.listen(dinoChatProvider, (_, _) {});
  });

  tearDown(() async {
    subscription.close();
    container.dispose();
    await database.close();
  });

  Future<DinoChatState> ready() async {
    for (var i = 0; i < 200 && !container.read(dinoChatProvider).isReady; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    return container.read(dinoChatProvider);
  }

  test('the Dino greets first and the greeting is spoken', () async {
    final state = await ready();
    expect(state.messages.first.speaker, Speaker.dino);
    expect(speech.spoken, isNotEmpty);
  });

  test('a question gets the official meaning, spoken by TTS', () async {
    await ready();
    await container
        .read(dinoChatProvider.notifier)
        .send('What does water mean?');

    final state = container.read(dinoChatProvider);
    expect(state.messages.last.text, 'Water means água.');
    // A word lesson: English, then the meaning in the Portuguese voice.
    expect(speech.spoken, contains('Water means água.'));
    expect(speech.spoken.last, 'Water significa água.');
  });

  test(
    'a correct conversation quiz answer grants XP via ProgressRepository',
    () async {
      await ready();
      final notifier = container.read(dinoChatProvider.notifier);
      await notifier.send('Can I get a reward?');
      await notifier.send('yes');

      // Answer whatever the Dino asked, using the official word bank.
      final question = container.read(dinoChatProvider).messages.last.text;
      final quoted = RegExp('"(.+?)"').firstMatch(question)!.group(1)!;
      final words = await database.select(database.words).get();
      final answer = question.contains('in Portuguese')
          ? words
                .firstWhere((w) => w.englishTerm == quoted)
                .portugueseTranslation
          : words
                .firstWhere((w) => w.portugueseTranslation == quoted)
                .englishTerm;
      await notifier.send(answer);

      expect(container.read(dinoChatProvider).xpEarned, greaterThan(0));
      final profile = await database.select(database.userProfile).getSingle();
      expect(profile.totalXp, greaterThan(0));
      final attempt = await database
          .select(database.exerciseAttempts)
          .getSingle();
      expect(attempt.sessionKind, 'conversation');
    },
  );

  test(
    'a care button changes the needs and persists them in the database',
    () async {
      final before = (await ready()).companion!;
      await container.read(dinoChatProvider.notifier).care(DinoCare.feed);

      final state = container.read(dinoChatProvider);
      expect(state.companion!.hunger, before.hunger + 20);
      expect(state.lastResponse!.care, DinoCare.feed);
      expect(speech.spoken.last, isNot(contains('🍎')));

      final row = await database.select(database.companionStates).getSingle();
      expect(row.hunger, state.companion!.hunger);
    },
  );

  test(
    'care XP reaches the profile but does not count as an exercise',
    () async {
      await ready();
      await container.read(dinoChatProvider.notifier).care(DinoCare.feed);

      expect(container.read(dinoChatProvider).xpEarned, 5);
      final profile = await database.select(database.userProfile).getSingle();
      expect(profile.totalXp, 5);
      final attempt = await database
          .select(database.exerciseAttempts)
          .getSingle();
      expect(attempt.sessionKind, 'companion');
      final day = await database.select(database.dailyActivityLog).getSingle();
      expect(day.exercisesCompleted, 0);
      expect(day.xpEarned, 5);
    },
  );

  test(
    'the companion state survives closing and reopening the screen',
    () async {
      await ready();
      await container.read(dinoChatProvider.notifier).care(DinoCare.sleep);
      expect(container.read(dinoChatProvider).companion!.isSleeping, isTrue);

      subscription.close();
      container.invalidate(dinoChatProvider);
      subscription = container.listen(dinoChatProvider, (_, _) {});
      final reopened = await ready();
      expect(reopened.companion!.isSleeping, isTrue);
      expect(reopened.lastResponse!.text, contains('Z z z'));
    },
  );

  group('end to end (Part 5)', () {
    Future<void> settle() async {
      for (var i = 0; i < 50; i++) {
        if (container.read(dinoChatProvider).voiceState ==
            VoiceState.listening) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    test(
      'voice -> text -> intent -> answer -> EN+PT voice -> listening',
      () async {
        await ready();
        await settle();
        speech.hold = Completer<void>();

        recognizer.emit(const SpeechStarted());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(
          container.read(dinoChatProvider).animation,
          CompanionAnimation.listening,
        );
        recognizer.emit(const SpeechRecognized('Dino, você gosta de maçã?'));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final talking = container.read(dinoChatProvider);
        final r = talking.lastResponse!;
        expect(r.intent, CompanionIntent.askLike);
        expect(r.detectedEntity?.id, 'APPLE');
        expect(talking.heardText, 'Dino, você gosta de maçã?');
        expect(talking.dinoSpeaking, isTrue);
        expect(recognizer.running, isFalse, reason: 'never hears itself');
        expect(speech.locales.last, 'en-US');

        speech.hold!.complete();
        speech.hold = null;
        await Future<void>.delayed(
          DinoChatController.resumeDelay + const Duration(milliseconds: 100),
        );
        final after = container.read(dinoChatProvider);
        // Asked in Portuguese, answered in English: English voice only.
        expect(speech.locales.last, 'en-US');
        expect(after.dinoSpeaking, isFalse);
        expect(after.voiceState, VoiceState.listening);
        expect(recognizer.running, isTrue);
      },
    );

    test(
      'memory: "Eu gosto de azul" -> "Qual é minha cor favorita?"',
      () async {
        await ready();
        final notifier = container.read(dinoChatProvider.notifier);
        await notifier.send('Eu gosto de azul');
        await notifier.send('Qual é minha cor favorita?');
        final r = container.read(dinoChatProvider).lastResponse!;
        // (A Portuguese sentence with an English word may follow.)
        expect(r.lines.first.text, 'Your favorite color is blue!');
        expect(r.portugueseText, 'Sua cor favorita é azul!');
      },
    );

    test('history and memory survive closing the screen', () async {
      await ready();
      final notifier = container.read(dinoChatProvider.notifier);
      await notifier.send('My name is Ana');
      await notifier.send('Você gosta de maçã?');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final rows = await database.select(database.companionHistory).get();
      final like = rows.lastWhere((r) => r.childText == 'Você gosta de maçã?');
      expect(like.intent, 'askLike');
      expect(like.word, 'apple');
      expect(like.portugueseText, isNotNull);

      subscription.close();
      container.invalidate(dinoChatProvider);
      subscription = container.listen(dinoChatProvider, (_, _) {});
      final reopened = await ready();
      expect(
        reopened.messages.map((m) => m.text),
        contains('Você gosta de maçã?'),
      );
      await container
          .read(dinoChatProvider.notifier)
          .send('Qual é o meu nome?');
      expect(
        container.read(dinoChatProvider).lastResponse!.englishText,
        'Your name is Ana!',
      );
    });

    test('unknown: honest answer, pensive, and the talk goes on', () async {
      await ready();
      final notifier = container.read(dinoChatProvider.notifier);
      await notifier.send('blorg zuzu xpto');
      final r = container.read(dinoChatProvider).lastResponse!;
      expect(r.intent, CompanionIntent.unknown);
      expect(r.animation, CompanionAnimation.thinking);
      await notifier.send('Você está com sede?');
      expect(
        container.read(dinoChatProvider).lastResponse!.intent,
        CompanionIntent.askThirsty,
      );
    });
  });

  group('pet activities', () {
    test(
      'Comer: food appears, is dragged, Dino chews, then eats + XP',
      () async {
        final before = (await ready()).companion!;
        final notifier = container.read(dinoChatProvider.notifier);
        await notifier.startActivity(DinoCare.feed);
        final offered = container.read(dinoChatProvider);
        expect(offered.offered, DinoCare.feed);
        expect(offered.companion!.hunger, before.hunger);

        final eating = notifier.deliverOffered();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final chewing = container.read(dinoChatProvider);
        expect(chewing.offered, isNull);
        expect(chewing.chewToken, offered.chewToken + 1);
        expect(chewing.animation, CompanionAnimation.eating);
        await eating;

        final after = container.read(dinoChatProvider);
        expect(after.companion!.hunger, closeTo(before.hunger + 20, 0.1));
        expect(after.xpEarned, 5);
        expect(after.xpBurst, greaterThan(offered.xpBurst));
      },
    );

    test('bread from the panel: its own numbers, hearts, hint once', () async {
      final before = (await ready()).companion!;
      final notifier = container.read(dinoChatProvider.notifier);
      await notifier.selectFood(FoodCatalog.bread);
      final offered = container.read(dinoChatProvider);
      expect(offered.offered, DinoCare.feed);
      expect(offered.offeredFood, FoodCatalog.bread);
      expect(offered.foodHint, isTrue);
      expect(offered.lastResponse!.englishText, contains('bread'));
      expect(offered.lastResponse!.portugueseText, contains('pão'));

      final eating = notifier.deliverOffered();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        container.read(dinoChatProvider).animation,
        CompanionAnimation.eating,
      );
      await eating;

      final after = container.read(dinoChatProvider);
      expect(after.offeredFood, isNull);
      expect(after.companion!.hunger, closeTo(before.hunger + 10, 0.1));
      expect(after.companion!.happiness, closeTo(before.happiness + 5, 0.1));
      expect(after.xpEarned, 5);
      expect(after.heartsToken, offered.heartsToken + 1);
      expect(after.animation, CompanionAnimation.happy);
      expect(after.lastResponse!.englishText, contains('Yummy! Bread!'));
      expect(after.lastResponse!.portugueseText, contains('Delícia! Pão!'));

      // The hint was learned; feeding never pays coins.
      await notifier.selectFood(FoodCatalog.apple);
      expect(container.read(dinoChatProvider).foodHint, isFalse);
      final profile = await database.select(database.userProfile).getSingle();
      expect(profile.coins, 30);
    });

    test('Dormir: the bedroom, tap the bed, walk there, sleep', () async {
      await ready();
      final notifier = container.read(dinoChatProvider.notifier);
      await notifier.startActivity(DinoCare.sleep);
      final bedroom = container.read(dinoChatProvider);
      expect(bedroom.bedroom, isTrue);
      expect(bedroom.companion!.isSleeping, isFalse);
      expect(bedroom.lastResponse!.englishText.toLowerCase(), contains('bed'));

      final going = notifier.goToBed();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(dinoChatProvider).walkingToBed, isTrue);
      expect(
        container.read(dinoChatProvider).animation,
        CompanionAnimation.walking,
      );
      await going;
      final asleep = container.read(dinoChatProvider);
      expect(asleep.walkingToBed, isFalse);
      expect(asleep.companion!.isSleeping, isTrue);

      await notifier.wakeUp();
      final awake = container.read(dinoChatProvider);
      expect(awake.bedroom, isFalse);
      expect(awake.lastResponse!.englishText, contains('Good morning'));
      expect(awake.lastResponse!.portugueseText, contains('Bom dia'));
    });

    test('Brincar: the ball game -- first hit plays, combos cheer, '
        'coins every 10, summary at the end', () async {
      await ready();
      final notifier = container.read(dinoChatProvider.notifier);
      await notifier.startActivity(DinoCare.play);
      expect(container.read(dinoChatProvider).ballGame, isTrue);
      final before = container.read(dinoChatProvider).companion!.happiness;
      final coinsBefore =
          (await database.select(database.userProfile).getSingle()).coins;

      for (var combo = 1; combo <= 10; combo++) {
        await notifier.ballHit(combo);
      }
      final playing = container.read(dinoChatProvider);
      expect(playing.companion!.happiness, greaterThan(before));
      expect(playing.xpEarned, greaterThan(10));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final coins =
          (await database.select(database.userProfile).getSingle()).coins;
      expect(coins, coinsBefore + CompanionEngine.ballCoinsPerTen);

      await notifier.stopBallGame(
        hits: 10,
        bestCombo: 10,
        played: const Duration(seconds: 45),
      );
      final over = container.read(dinoChatProvider);
      expect(over.ballGame, isFalse);
      expect(over.lastResponse!.englishText, contains('10 hits'));
    });

    test('back closes one thing at a time: ball game, then nothing', () async {
      await ready();
      final notifier = container.read(dinoChatProvider.notifier);
      expect(notifier.hasOpenActivity, isFalse);
      expect(notifier.back(), isFalse);

      await notifier.startActivity(DinoCare.play);
      for (var combo = 1; combo <= 3; combo++) {
        await notifier.ballHit(combo);
      }
      expect(notifier.hasOpenActivity, isTrue);
      expect(notifier.back(), isTrue); // Bola -> Brincar
      expect(container.read(dinoChatProvider).ballGame, isFalse);
      // The game's summary still counts the hits made before leaving.
      for (
        var i = 0;
        i < 50 &&
            !(container
                    .read(dinoChatProvider)
                    .lastResponse
                    ?.englishText
                    .contains('3 hits') ??
                false);
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(
        container.read(dinoChatProvider).lastResponse!.englishText,
        contains('3 hits'),
      );
      expect(notifier.hasOpenActivity, isFalse);
      expect(notifier.back(), isFalse); // now the screen may close
    });

    test('back closes the bedroom (before the Dino lies down)', () async {
      await ready();
      final notifier = container.read(dinoChatProvider.notifier);
      await notifier.startActivity(DinoCare.sleep);
      expect(container.read(dinoChatProvider).bedroom, isTrue);
      expect(notifier.back(), isTrue);
      expect(container.read(dinoChatProvider).bedroom, isFalse);
      expect(notifier.back(), isFalse);
    });

    test('Brincar + 3 kicks: play, cheer, GOAL (+20 XP)', () async {
      await ready();
      final notifier = container.read(dinoChatProvider.notifier);
      await notifier.startActivity(DinoCare.play);
      for (var i = 0; i < 3; i++) {
        await notifier.kickBall();
      }
      final state = container.read(dinoChatProvider);
      expect(state.lastResponse!.xpReward, 20);
      expect(state.lastResponse!.animation, CompanionAnimation.celebrating);
    });
  });

  group('hands-free voice', () {
    Future<void> pump() =>
        Future<void>.delayed(const Duration(milliseconds: 20));

    Future<DinoChatState> voiceSettled() async {
      await ready();
      for (var i = 0; i < 50; i++) {
        final s = container.read(dinoChatProvider).voiceState;
        if (s != VoiceState.idle && s != VoiceState.processing) break;
        await pump();
      }
      return container.read(dinoChatProvider);
    }

    test('opening the screen asks for the mic and starts listening', () async {
      recognizer.permission = MicPermission.denied;
      final state = await voiceSettled();
      expect(recognizer.permissionRequests, 1);
      expect(recognizer.starts, 1);
      expect(state.voiceState, VoiceState.listening);
    });

    test('already allowed: no dialog, listens right away', () async {
      final state = await voiceSettled();
      expect(recognizer.permissionRequests, 0);
      expect(state.voiceState, VoiceState.listening);
    });

    test('denied: text keeps working, the mic button asks again', () async {
      recognizer
        ..permission = MicPermission.denied
        ..dialogAnswer = MicPermission.denied;
      final denied = await voiceSettled();
      expect(denied.voiceState, VoiceState.disabled);
      expect(denied.voiceMessage, contains('precisa do microfone'));
      expect(recognizer.starts, 0);

      final notifier = container.read(dinoChatProvider.notifier);
      await notifier.send('What does water mean?');
      expect(
        container.read(dinoChatProvider).lastResponse!.text,
        'Water means água.',
      );

      recognizer.dialogAnswer = MicPermission.granted;
      await notifier.toggleMicrophone();
      expect(recognizer.permissionRequests, 2);
      expect(container.read(dinoChatProvider).voiceState, VoiceState.listening);
    });

    test('blocked for good: the mic button opens the settings', () async {
      recognizer.permission = MicPermission.permanentlyDenied;
      final state = await voiceSettled();
      expect(state.micBlocked, isTrue);
      expect(state.voiceMessage, contains('configurações'));
      final notifier = container.read(dinoChatProvider.notifier);
      await notifier.toggleMicrophone();
      expect(recognizer.settingsOpened, 1);

      // The child allows it in the settings and comes back.
      recognizer.permission = MicPermission.granted;
      await notifier.setForeground(false);
      await notifier.setForeground(true);
      expect(container.read(dinoChatProvider).voiceState, VoiceState.listening);
    });

    test('a sentence becomes text on screen and goes to the Dino', () async {
      await voiceSettled();
      recognizer.emit(const SpeechStarted());
      await pump();
      recognizer.emit(const SpeechProcessing());
      await pump();
      expect(
        container.read(dinoChatProvider).voiceState,
        VoiceState.processing,
      );

      recognizer.emit(const SpeechRecognized('Você está com fome?'));
      await pump();
      final state = container.read(dinoChatProvider);
      expect(state.heardText, 'Você está com fome?');
      final child = state.messages.lastWhere((m) => m.speaker == Speaker.child);
      expect(child.text, 'Você está com fome?');
      expect(child.viaVoice, isTrue);
      expect(state.lastResponse!.intent, CompanionIntent.askHungry);
      expect(state.lastResponse!.portugueseText, isNotNull);
      // Listening again once the Dino has finished talking.
      await Future<void>.delayed(
        DinoChatController.resumeDelay + const Duration(milliseconds: 80),
      );
      expect(container.read(dinoChatProvider).voiceState, VoiceState.listening);
    });

    test('noise is ignored silently', () async {
      await voiceSettled();
      final before = container.read(dinoChatProvider).messages.length;
      recognizer.emit(const SpeechNothingHeard());
      await pump();
      final state = container.read(dinoChatProvider);
      expect(state.messages.length, before);
      expect(state.voiceState, VoiceState.listening);
    });

    test('the mic is closed while the Dino talks and reopens after', () async {
      await voiceSettled();
      speech.hold = Completer<void>();
      final reply = container
          .read(dinoChatProvider.notifier)
          .send('Você gosta de maçã?');
      await pump();
      final talking = container.read(dinoChatProvider);
      expect(talking.dinoSpeaking, isTrue);
      expect(recognizer.running, isFalse);
      expect(recognizer.muted, isTrue);

      speech.hold!.complete();
      speech.hold = null;
      await reply;
      await Future<void>.delayed(
        DinoChatController.resumeDelay + const Duration(milliseconds: 80),
      );
      final after = container.read(dinoChatProvider);
      expect(after.dinoSpeaking, isFalse);
      expect(recognizer.running, isTrue);
      expect(recognizer.muted, isFalse);
      expect(after.voiceState, VoiceState.listening);
    });

    test(
      'asked in Portuguese: English voice; "não entendi": Portuguese',
      () async {
        await voiceSettled();
        final notifier = container.read(dinoChatProvider.notifier);
        await notifier.send('Você gosta de maçã?');
        await pump();
        final response = container.read(dinoChatProvider).lastResponse!;
        expect(
          speech.spoken.last,
          TtsCompanionVoiceService.speakable(response.lines.single.text),
        );
        expect(speech.locales.last, 'en-US');

        await notifier.send('Não entendi.');
        await pump();
        expect(
          speech.spoken.last,
          TtsCompanionVoiceService.speakable(
            response.lines.single.translation!,
          ),
        );
        expect(speech.locales.last, 'pt-BR');
      },
    );

    test('without a Portuguese voice it still speaks English', () async {
      speech.missing.add('pt-BR');
      await voiceSettled();
      final start = speech.spoken.length;
      await container.read(dinoChatProvider.notifier).send('Oi');
      await pump();
      expect(speech.locales.sublist(start), everyElement('en-US'));
      expect(
        container.read(dinoChatProvider).lastResponse!.portugueseText,
        isNotNull,
      );
    });

    test('when the child talks the Dino turns to listen', () async {
      final before = (await voiceSettled()).lookToken;
      recognizer.emit(const SpeechStarted());
      await pump();
      final state = container.read(dinoChatProvider);
      expect(state.animation, CompanionAnimation.listening);
      expect(state.lookToken, greaterThan(before));
      recognizer.emit(const SpeechProcessing());
      await pump();
      expect(
        container.read(dinoChatProvider).animation,
        CompanionAnimation.thinking,
      );
    });

    test(
      'leaving / background closes the mic; coming back reopens it',
      () async {
        await voiceSettled();
        final notifier = container.read(dinoChatProvider.notifier);
        await notifier.setForeground(false);
        expect(recognizer.running, isFalse);
        expect(container.read(dinoChatProvider).voiceState, VoiceState.idle);

        await notifier.setForeground(true);
        expect(recognizer.running, isTrue);
        expect(recognizer.starts, 2);
        expect(
          container.read(dinoChatProvider).voiceState,
          VoiceState.listening,
        );
      },
    );

    test('the mic button pauses and resumes', () async {
      await voiceSettled();
      final notifier = container.read(dinoChatProvider.notifier);
      await notifier.toggleMicrophone();
      expect(recognizer.running, isFalse);
      expect(container.read(dinoChatProvider).voiceState, VoiceState.idle);
      // Paused by the child: coming back from background keeps it paused.
      await notifier.setForeground(false);
      await notifier.setForeground(true);
      expect(recognizer.running, isFalse);
      await notifier.toggleMicrophone();
      expect(recognizer.running, isTrue);
    });

    test('English is expected while a word should be repeated', () async {
      await voiceSettled();
      await container.read(dinoChatProvider.notifier).send('Me dá água');
      expect(recognizer.hint, SpeechLanguageHint.english);
    });

    test('without the models the screen stays text-only', () async {
      recognizer.available = false;
      subscription.close();
      container.invalidate(dinoChatProvider);
      subscription = container.listen(dinoChatProvider, (_, _) {});
      final state = await voiceSettled();
      expect(state.voiceState, VoiceState.disabled);
      expect(recognizer.permissionRequests, 0);
    });
  });
}
