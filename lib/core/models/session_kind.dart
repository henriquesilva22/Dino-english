/// What kind of session a batch of exercise attempts belongs to.
/// An open string vocabulary at the DB layer (`exam` can join later
/// without a migration); this enum is the typed MVP subset.
enum SessionKind { study, review }

extension SessionKindStorage on SessionKind {
  String toStorageKey() => name;
}
