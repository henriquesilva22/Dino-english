import 'package:dino_english/core/single_navigation_guard.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(SingleNavigationGuard.resetForTest);

  test('a second call while the cooldown is active is ignored', () {
    fakeAsync((async) {
      var calls = 0;
      SingleNavigationGuard.run(() => calls++);
      SingleNavigationGuard.run(() => calls++);

      expect(calls, 1);

      async.elapse(const Duration(milliseconds: 500));
    });
  });

  test('a call after the cooldown elapses runs normally', () {
    fakeAsync((async) {
      var calls = 0;
      SingleNavigationGuard.run(() => calls++);
      async.elapse(const Duration(milliseconds: 500));
      SingleNavigationGuard.run(() => calls++);

      expect(calls, 2);
    });
  });

  test('a call right before the cooldown elapses is still ignored', () {
    fakeAsync((async) {
      var calls = 0;
      SingleNavigationGuard.run(() => calls++);
      async.elapse(const Duration(milliseconds: 499));
      SingleNavigationGuard.run(() => calls++);

      expect(calls, 1);

      async.elapse(const Duration(milliseconds: 1));
    });
  });

  test(
    'an async navigate function is awaited to completion before the cooldown is armed -- '
    'the guard must not silently stop debouncing just because "JOGAR NOVAMENTE" needs to '
    'await endSession() before pushReplacement',
    () {
      fakeAsync((async) {
        var calls = 0;
        var firstNavigateFinished = false;
        SingleNavigationGuard.run(() async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          calls++;
          firstNavigateFinished = true;
        });

        // Still mid-flight (the delay inside navigate() hasn't fired yet)
        // -- a second call here must be a complete no-op, not just a
        // "will run later" queue.
        async.elapse(const Duration(milliseconds: 100));
        SingleNavigationGuard.run(() => calls++);
        expect(firstNavigateFinished, isFalse);
        expect(calls, 0);

        // Let navigate()'s own delay finish.
        async.elapse(const Duration(milliseconds: 100));
        expect(firstNavigateFinished, isTrue);
        expect(calls, 1);

        // The cooldown only starts counting once navigate() itself
        // finished (i.e. now), not from when run() was first called --
        // so a call right after navigate() completes, but before a full
        // 500ms cooldown has elapsed since then, must still be blocked.
        SingleNavigationGuard.run(() => calls++);
        expect(calls, 1);

        async.elapse(const Duration(milliseconds: 500));
        SingleNavigationGuard.run(() => calls++);
        expect(calls, 2);
      });
    },
  );
}
