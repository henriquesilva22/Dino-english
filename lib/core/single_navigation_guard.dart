import 'dart:async';

import 'package:flutter/foundation.dart';

/// Debounces the app's push/replace navigation calls so a fast double-tap
/// on a button can't push the same route twice.
///
/// Flutter keeps a covered-but-not-yet-popped route's widget subtree fully
/// mounted and attached, and Flame's `GameLoop` starts on render-tree
/// attach rather than route visibility -- so for Pet Adventure specifically,
/// a duplicate push isn't just a cosmetic double-navigation: it means two
/// concurrent, independently-ticking `PetAdventureGame` instances.
///
/// The reset is a **fixed cooldown**, not gated on the pushed route being
/// popped: gating on that would deadlock "JOGAR NOVAMENTE", whose
/// `pushReplacement` call runs *inside* an `onTap` on a screen that is
/// itself still "in flight" from its own original push (pushReplacement
/// completes the old route's popped-future synchronously as part of the
/// same call that would be waiting on it).
///
/// One global flag (not per-button) is deliberate: several call sites are
/// `StatelessWidget`/`ConsumerWidget`s with no `State` to hold a local
/// flag, and a single flag also correctly debounces a double-tap across
/// two different buttons (e.g. "COMEÇAR AVENTURA" then "DESAFIAR O CHEFE"
/// in quick succession) -- this app has exactly one Navigator and never a
/// legitimate reason to push a second route while one is already in
/// flight.
class SingleNavigationGuard {
  SingleNavigationGuard._();

  static const _cooldown = Duration(milliseconds: 500);
  static bool _inFlight = false;

  /// Runs [navigate] unless another guarded navigation is already in
  /// flight (within [_cooldown] of its own call). `navigate` may be
  /// synchronous or `async` -- if it's `async` (e.g. it needs to await
  /// `PetAdventureGame.endSession()` before a "JOGAR NOVAMENTE"
  /// `pushReplacement`), the cooldown is only armed once it *finishes*,
  /// not once the call merely returns. Getting this wrong is a real,
  /// silent trap: `void Function()` happily accepts an `async` closure
  /// too (its returned Future is just discarded), so a version of this
  /// that didn't await would arm the cooldown while the async body was
  /// still mid-flight -- reopening the exact double-push race this guard
  /// exists to prevent, just via a slower trigger than a fast double-tap.
  static Future<void> run(FutureOr<void> Function() navigate) async {
    if (_inFlight) return;
    _inFlight = true;
    await navigate();
    Timer(_cooldown, () => _inFlight = false);
  }

  /// Test-only escape hatch so one test's guarded tap doesn't leave
  /// `_inFlight` true for a later test in the same file.
  @visibleForTesting
  static void resetForTest() => _inFlight = false;
}
