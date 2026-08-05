/// A single statement row preserved exactly as parsed from the source file.
///
/// All five values are kept as raw strings — no conversion, formatting, or
/// calculation is performed at this stage. This is a lightweight preview
/// model only; it is never persisted and never turned into a
/// [TransactionModel] during Phase 6B.
class StatementRow {
  final String date;
  final String description;
  final String debit;
  final String credit;
  final String balance;

  const StatementRow({
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
  });
}
