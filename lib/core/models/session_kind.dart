/// What kind of session a batch of exercise attempts belongs to.
/// An open string vocabulary at the DB layer; this enum is the typed
/// subset. Additive change, no migration needed (the DB column is plain
/// TEXT, mapped via `.name`).
enum SessionKind {
  study,
  review,
  exam,

  /// Word challenges asked by the Dino in the chat (DinoBrain).
  conversation,

  /// The virtual companion: care actions and words practised with it.
  companion,
}

extension SessionKindStorage on SessionKind {
  String toStorageKey() => name;
}
