import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:get/get.dart';

/// Client-side rules for the loan form.
///
/// These are the SAME regexes the backend schema uses (see
/// docs/backend/FLUTTER_LOAN_APPLICATION_GUIDE.md §8), mirrored here so the
/// applicant is corrected in place instead of by a round-trip that arrives
/// after they have moved on. The server still validates everything — this is a
/// courtesy, not the enforcement.
class LoanValidators {
  const LoanValidators._();

  static final RegExp _pan = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

  /// Indian mobile: ten digits opening 6–9.
  static final RegExp _mobile = RegExp(r'^[6-9]\d{9}$');

  /// Six digits, never opening with 0.
  static final RegExp _pincode = RegExp(r'^[1-9][0-9]{5}$');

  static String? Function(String?) required(String label) => (v) =>
      (v ?? '').trim().isEmpty
          ? AppStrings.loanFieldRequiredFmt.trParams({'field': label})
          : null;

  static String? pan(String? v) {
    final s = (v ?? '').trim().toUpperCase();
    if (s.isEmpty) return AppStrings.loanPanRequired.tr;
    if (!_pan.hasMatch(s)) return AppStrings.loanPanInvalid.tr;
    return null;
  }

  static String? mobile(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return AppStrings.loanMobileRequired.tr;
    if (!_mobile.hasMatch(s)) return AppStrings.loanMobileInvalid.tr;
    return null;
  }

  static String? pincode(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return AppStrings.loanPincodeRequired.tr;
    if (!_pincode.hasMatch(s)) return AppStrings.loanPincodeInvalid.tr;
    return null;
  }

  /// A date of birth that exists and is in the past.
  ///
  /// The three DD/MM/YYYY dropdowns can compose a day that never happened —
  /// 31 February — so the caller builds the [DateTime] with
  /// [composeDob], which returns null for exactly that case, and this reports
  /// it as "not a real date" rather than as a missing one.
  static String? dob(DateTime? d, {required bool anyPartChosen}) {
    if (d == null) {
      return anyPartChosen
          ? AppStrings.loanDobInvalid.tr
          : AppStrings.loanDobRequired.tr;
    }
    if (d.isAfter(DateTime.now())) return AppStrings.loanDobFuture.tr;
    return null;
  }

  static String? Function(String?) positiveAmount(String label) => (v) {
        final n = num.tryParse((v ?? '').trim());
        if (n == null) {
          return AppStrings.loanFieldRequiredFmt.trParams({'field': label});
        }
        if (n <= 0) {
          return AppStrings.loanMustBePositiveFmt.trParams({'field': label});
        }
        return null;
      };

  static String? Function(String?) nonNegativeAmount(String label) => (v) {
        final n = num.tryParse((v ?? '').trim());
        if (n == null) {
          return AppStrings.loanFieldRequiredFmt.trParams({'field': label});
        }
        if (n < 0) {
          return AppStrings.loanMustBePositiveFmt.trParams({'field': label});
        }
        return null;
      };
}

/// Builds a [DateTime] from the three DD / MM / YYYY dropdowns.
///
/// Returns null when any part is unset OR when the parts don't name a real
/// day. Dart's `DateTime(1992, 2, 31)` silently rolls forward to 2 March, so
/// the round-trip check below is what catches an impossible date instead of
/// quietly submitting a different one than the user picked.
DateTime? composeDob({int? day, int? month, int? year}) {
  if (day == null || month == null || year == null) return null;
  final d = DateTime(year, month, day);
  if (d.year != year || d.month != month || d.day != day) return null;
  return d;
}
