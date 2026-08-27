import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../loan_validators.dart';
import '../model/loan_application.dart';
import '../model/loan_enums.dart';
import '../repo/loan_application_repo.dart';

/// Drives the two-step Quick Loan Apply form.
///
/// See docs/backend/FLUTTER_LOAN_APPLICATION_GUIDE.md.
///
/// ## Why the controllers are all created up front
///
/// `professionType` decides which employment block is required, and the
/// backend **clears the other block on every save**. The form therefore shows
/// one branch at a time — but both sets of [TextEditingController] live for the
/// whole session, so a user who taps Salaried → Self-Employed → Salaried gets
/// back what they typed rather than an empty form. Disposing the hidden branch
/// is the obvious optimisation and it is the bug.
class LoanApplicationController extends GetxController {
  final LoanApplicationRepo _repo = LoanApplicationRepo();

  // ─── Step 1: personal ───────────────────────────────────────────
  final nameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final panCtrl = TextEditingController();

  /// DOB as three parts, because the design asks for three dropdowns rather
  /// than a calendar. They are only composed into a date at validation time —
  /// see [dob] and [composeDob].
  final RxnInt dobDay = RxnInt();
  final RxnInt dobMonth = RxnInt();
  final RxnInt dobYear = RxnInt();

  /// The picked date, or null when a part is missing or the three compose a
  /// day that does not exist (31 February).
  DateTime? get dob => composeDob(
        day: dobDay.value,
        month: dobMonth.value,
        year: dobYear.value,
      );

  /// Whether the user has touched the date at all — separates "you haven't
  /// picked one" from "that isn't a real date".
  bool get dobPartiallyChosen =>
      dobDay.value != null || dobMonth.value != null || dobYear.value != null;

  // ─── Step 1: professional ───────────────────────────────────────
  final Rx<ProfessionType> professionType = ProfessionType.salaried.obs;

  final annualIncomeCtrl = TextEditingController();

  // Salaried branch.
  final companyNameCtrl = TextEditingController();
  final jobRoleCtrl = TextEditingController();

  // Self-employed branch. Both branches stay alive — see the class doc.
  final businessNameCtrl = TextEditingController();
  final businessAddressCtrl = TextEditingController();
  final RxnString natureOfBusiness = RxnString();
  final RxnInt businessExperienceYears = RxnInt();

  bool get isSalaried => professionType.value == ProfessionType.salaried;

  // ─── Step 2: loan ───────────────────────────────────────────────
  final loanAmountCtrl = TextEditingController();
  final existingEmiCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();

  final RxnString loanPurpose = RxnString();
  final RxnInt loanTenureMonths = RxnInt();
  final Rxn<ResidenceType> residenceType = Rxn<ResidenceType>();

  /// The design's checkbox is "No Existing EMI" — the INVERSE of the wire's
  /// `isMonthlyEmi`, so it is stored the way it is drawn and flipped once, at
  /// the boundary, in [_buildDraft].
  final RxBool noExistingEmi = false.obs;

  final RxBool termsAccepted = false.obs;

  // ─── Options ────────────────────────────────────────────────────
  /// Residence types offered by the dropdown.
  ///
  /// Seeded from the bundled enum so the form is usable the instant it opens,
  /// and replaced if `/options` answers with a different list. The guide calls
  /// the round-trip optional for exactly this reason.
  final RxList<ResidenceType> residenceOptions =
      ResidenceType.values.toList().obs;

  // ─── Submission ─────────────────────────────────────────────────
  final RxBool isSubmitting = false.obs;

  /// Per-field messages the SERVER rejected on, keyed by the field labels this
  /// form uses. Populated only from a 400, and cleared on the next attempt.
  final RxString submitError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _prefillFromProfile();
    _loadOptions();
  }

  @override
  void onClose() {
    for (final c in [
      nameCtrl,
      mobileCtrl,
      addressCtrl,
      panCtrl,
      annualIncomeCtrl,
      companyNameCtrl,
      jobRoleCtrl,
      businessNameCtrl,
      businessAddressCtrl,
      loanAmountCtrl,
      existingEmiCtrl,
      pincodeCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }

  /// Name and mobile from the signed-in profile — the design shows the name
  /// already filled in.
  ///
  /// Best-effort and non-blocking: the form works untouched if the profile
  /// isn't in memory, the user just types them. Only ever PRE-fills, so a
  /// re-entry that already has edits is left alone.
  void _prefillFromProfile() {
    try {
      final user = Get.isRegistered<ViewPersonalDetailsController>()
          ? Get.find<ViewPersonalDetailsController>()
              .personalProfileDetails
              .value
              .user
          : null;
      if (nameCtrl.text.trim().isEmpty) {
        nameCtrl.text = user?.name ?? userNameGlobal;
      }
      if (mobileCtrl.text.trim().isEmpty) {
        // Ten digits only — the field renders a fixed "+91" prefix, so a
        // stored number carrying the country code would read as "+91 +919…".
        mobileCtrl.text = _localMobile(user?.contactNo ?? userMobileGlobal);
      }
    } catch (e) {
      logs('LoanApplicationController prefill skipped: $e');
    }
  }

  /// Strips a `+91` / `91` prefix and any separators, then keeps the last ten
  /// digits — the form's field is the subscriber number alone.
  String _localMobile(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }

  /// Upgrades the dropdowns from `/options` if it answers.
  ///
  /// Fail-quiet in every direction: the bundled enums are already correct, so
  /// a failure here is invisible rather than an error over a working form.
  Future<void> _loadOptions() async {
    try {
      final res = await _repo.options();
      if (res.statusCode != 200) return;
      final body = res.response?.data;
      if (body is! Map) return;
      final data = body['data'];
      if (data is! Map) return;
      final residences = data['residenceTypes'];
      if (residences is! List || residences.isEmpty) return;
      final parsed = residences
          .map((e) => ResidenceType.fromWire(e?.toString()))
          .toSet()
          .toList();
      if (parsed.isNotEmpty) residenceOptions.assignAll(parsed);
    } catch (e) {
      logs('LoanApplicationController options skipped: $e');
    }
  }

  // ─── Step 2 gating ──────────────────────────────────────────────
  /// Whether the Apply button may fire at all.
  ///
  /// The terms are a hard gate: the checkbox authorises the lender to verify
  /// the applicant's credit, which is not something to infer from a tap on a
  /// button.
  bool get canSubmit => termsAccepted.value && !isSubmitting.value;

  /// Turns the form into the wire payload.
  ///
  /// Returns null when a required piece is missing — the form's own validators
  /// run first and are what tell the user WHICH piece, so this is the backstop
  /// that keeps a malformed draft off the wire rather than the thing that
  /// explains it.
  LoanApplicationDraft? _buildDraft() {
    final birthDate = dob;
    final income = num.tryParse(annualIncomeCtrl.text.trim());
    final amount = num.tryParse(loanAmountCtrl.text.trim());
    final tenure = loanTenureMonths.value;
    final residence = residenceType.value;
    final purpose = loanPurpose.value?.trim() ?? '';

    if (birthDate == null ||
        income == null ||
        amount == null ||
        tenure == null ||
        residence == null ||
        purpose.isEmpty) {
      return null;
    }

    // The checkbox is drawn as "No Existing EMI"; the wire field is its
    // opposite. Flipped here, once.
    final hasEmi = !noExistingEmi.value;
    final emi = hasEmi ? (num.tryParse(existingEmiCtrl.text.trim()) ?? 0) : 0;
    // The backend rejects `isMonthlyEmi: true` with a zero amount, so an
    // unticked checkbox over an empty field is sent as "no EMI" rather than as
    // a contradiction the server has to refuse.
    final declaresEmi = hasEmi && emi > 0;

    return LoanApplicationDraft(
      name: nameCtrl.text,
      address: addressCtrl.text,
      dob: birthDate,
      mobileNumber: mobileCtrl.text,
      panNumber: panCtrl.text,
      professionType: professionType.value,
      annualIncome: income,
      loanAmount: amount,
      loanPurpose: purpose,
      loanTenure: tenure,
      residentialPincode: pincodeCtrl.text,
      residenceType: residence,
      isMonthlyEmi: declaresEmi,
      existingMonthlyEmi: declaresEmi ? emi : 0,
      // Exactly one branch is populated; `toJson` sends only the matching one.
      companyName: companyNameCtrl.text,
      jobRole: jobRoleCtrl.text,
      businessName: businessNameCtrl.text,
      businessExperience: businessExperienceYears.value,
      natureOfBusiness: natureOfBusiness.value,
      businessAddress: businessAddressCtrl.text,
    );
  }

  /// Submits the application. Returns the created record, or null on failure.
  ///
  /// The caller decides what a success looks like on screen; this only reports
  /// failures, because the server's `message` is written to be shown as-is and
  /// is more specific than anything the form could say.
  Future<LoanApplication?> submit() async {
    if (isSubmitting.value) return null;
    submitError.value = '';

    final draft = _buildDraft();
    if (draft == null) {
      commonSnackBar(message: AppStrings.loanFormIncomplete.tr);
      return null;
    }

    isSubmitting.value = true;
    try {
      final res = await _repo.submit(draft);
      final body = res.response?.data;
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = (body is Map) ? body['data'] : null;
        if (data is Map) {
          return LoanApplication.fromJson(Map<String, dynamic>.from(data));
        }
        // Accepted, but the body wasn't the shape we expect. The application
        // exists either way, so this is not reported as a failure — the caller
        // shows its success state and the record is on the server.
        logs('Loan submit: 2xx with unexpected body shape');
        return null;
      }

      // 400 carries `errors[]`; every other status carries a `message` written
      // to be shown to the user. Both are the server's words, not ours.
      submitError.value = _messageOf(res);
      commonSnackBar(message: submitError.value);
      return null;
    } catch (e) {
      logs('Loan submit failed: $e');
      submitError.value = AppStrings.somethingWentWrong.tr;
      commonSnackBar(message: submitError.value);
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// The most specific thing the server said. Prefers the first entry of
  /// `errors[]` (a named field) over the summary `message`, and falls back to
  /// the app's generic line only when the body carried neither.
  String _messageOf(ResponseModel res) {
    try {
      final body = res.response?.data;
      if (body is Map) {
        final errors = body['errors'];
        if (errors is List && errors.isNotEmpty) {
          final first = errors.first?.toString().trim() ?? '';
          if (first.isNotEmpty) return first;
        }
        final message = body['message']?.toString().trim() ?? '';
        if (message.isNotEmpty) return message;
      }
    } catch (_) {
      // Fall through to the generic line.
    }
    return AppStrings.somethingWentWrong.tr;
  }
}
