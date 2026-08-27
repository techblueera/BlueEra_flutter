/// Wire enums for the loan application.
///
/// See docs/backend/FLUTTER_LOAN_APPLICATION_GUIDE.md §4.1.
///
/// **Casing is the contract.** Profession and residence values are Title Case
/// on the wire, statuses are lowercase, and they go back exactly as they came.
/// Every `fromWire` here falls back rather than throwing: a value the backend
/// adds before the app ships must not crash a form the user is part-way
/// through, and `values.firstWhere` with no `orElse` does exactly that.
library;

enum ProfessionType {
  /// Self-employed — shop owners and anyone running their own business. The
  /// mockup's right-hand card.
  business('Business'),

  /// Private, government and PSU employees. The mockup's left-hand card.
  salaried('Salaried');

  const ProfessionType(this.wire);

  final String wire;

  static ProfessionType fromWire(String? v) => values.firstWhere(
        (e) => e.wire == v,
        // Salaried is the form's default selection, so an unrecognised value
        // lands the user where the form already starts rather than silently
        // flipping the branch under them.
        orElse: () => salaried,
      );
}

enum ResidenceType {
  owned('Owned'),
  rental('Rental'),
  parental('Parental'),
  companyProvided('Company Provided'),
  other('Other');

  const ResidenceType(this.wire);

  final String wire;

  static ResidenceType fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => other);
}

/// Where an application sits. Only an admin moves it — the app renders it and
/// gates its buttons off [isEditable].
enum LoanStatus {
  pending('pending'),
  reviewed('reviewed'),
  approved('approved'),
  rejected('rejected');

  const LoanStatus(this.wire);

  final String wire;

  /// The backend permits an edit or a withdrawal only in these two states, and
  /// answers 403 otherwise. Mirror it in the UI so the controls disappear
  /// before the error does.
  bool get isEditable => this == pending || this == reviewed;

  static LoanStatus fromWire(String? v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => pending);
}
