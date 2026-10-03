import 'package:dino_english/core/brain/context/conversation_context.dart';
import 'package:dino_english/core/brain/model/dino_enums.dart';
import 'package:dino_english/core/companion/companion_response.dart';
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

  @override
  Future<SpeechResult> speak(String text) async {
    spoken.add(text);
    return SpeechResult.spoken;
  }

  @override
  Future<void> stop() async {}

  @override
  ValueListenable<Object?> get activeUtterance => ValueNotifier(null);
}

/// Push-to-talk without a microphone: returns [nextText] on release.
class _FakeRecognizer implements SpeechRecognitionService {
  bool available = true;
  bool permission = true;
  String? nextText;
  SpeechLanguageHint? lastHint;
  int prepared = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> prepare() async => prepared++;

  @override
  Future<bool> startListening() async => permission;

  @override
  Future<String?> stopListening({
    SpeechLanguageHint hint = SpeechLanguageHint.auto,
  }) async {
    lastHint = hint;
    return nextText;
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
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
    expect(speech.spoken.last, 'Water means água.');
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

  group('voice (push-to-talk)', () {
    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        if (container.read(dinoChatProvider).voiceAvailable) return;
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }

    test(
      'with the model bundled the mic shows and the model warms up',
      () async {
        await ready();
        await settle();
        expect(container.read(dinoChatProvider).voiceAvailable, isTrue);
        expect(recognizer.prepared, 1);
      },
    );

    test(
      'what the child says is sent like typed text, marked as voice',
      () async {
        await ready();
        final notifier = container.read(dinoChatProvider.notifier);
        recognizer.nextText = 'Você está com fome?';

        await notifier.startListening();
        final listening = container.read(dinoChatProvider);
        expect(listening.isListening, isTrue);
        expect(listening.animation, CompanionAnimation.listening);

        await notifier.stopListening();
        final state = container.read(dinoChatProvider);
        expect(state.isListening, isFalse);
        expect(state.isTranscribing, isFalse);
        final child = state.messages.lastWhere(
          (m) => m.speaker == Speaker.child,
        );
        expect(child.text, 'Você está com fome?');
        expect(child.viaVoice, isTrue);
        expect(state.lastResponse!.text, 'A little hungry!');
        expect(recognizer.lastHint, SpeechLanguageHint.auto);
      },
    );

    test(
      'while the Dino waits for an English word, English is expected',
      () async {
        await ready();
        final notifier = container.read(dinoChatProvider.notifier);
        await notifier.send('Me dá água');
        recognizer.nextText = 'Water!';
        await notifier.startListening();
        await notifier.stopListening();
        expect(recognizer.lastHint, SpeechLanguageHint.english);
        expect(container.read(dinoChatProvider).lastResponse!.xpReward, 10);
      },
    );

    test('nothing heard -> the Dino asks to try again', () async {
      await ready();
      final notifier = container.read(dinoChatProvider.notifier);
      recognizer.nextText = null;
      await notifier.startListening();
      await notifier.stopListening();
      final r = container.read(dinoChatProvider).lastResponse!;
      expect(r.translation, anyOf(contains('Não ouvi'), contains('de novo')));
    });

    test('no microphone permission -> the Dino suggests typing', () async {
      await ready();
      recognizer.permission = false;
      await container.read(dinoChatProvider.notifier).startListening();
      final state = container.read(dinoChatProvider);
      expect(state.isListening, isFalse);
      expect(state.lastResponse!.translation, contains('escrever'));
    });

    test('without the model there is no mic', () async {
      recognizer.available = false;
      subscription.close();
      container.invalidate(dinoChatProvider);
      subscription = container.listen(dinoChatProvider, (_, _) {});
      await ready();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(container.read(dinoChatProvider).voiceAvailable, isFalse);
    });
  });
}
