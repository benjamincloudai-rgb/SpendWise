/// The inferred direction of a statement row.
///
/// Mirrors the app's transaction income/expense split and adds [unknown] for
/// rows whose amounts cannot be determined. This is a preview-stage type only
/// and is never persisted.
enum TransactionType {
  income,
  expense,
  unknown,
}
