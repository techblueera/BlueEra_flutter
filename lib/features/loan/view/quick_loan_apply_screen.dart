import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controller/loan_application_controller.dart';
import '../loan_validators.dart';
import '../model/loan_enums.dart';
import '../widget/loan_form_widgets.dart';

/// The supported way to open the form — **use this rather than
/// `Get.to(() => const QuickLoanApplyScreen())`.**
///
/// A guest has no account for the application to belong to: the applicant
/// identity comes from the auth token, so a guest's submit would fail at the
/// API with nothing on screen explaining why. They are sent to profile
/// creation instead, which is the step that actually unblocks them.
Future<dynamic> openQuickLoanApply() {
  if (isGuestUser()) return createProfileScreen();
  return Get.to(() => const QuickLoanApplyScreen()) ??
      Future<dynamic>.value();
}

/// "Quick Loan Apply" — the two-step application form.
///
/// Drawn to `assets/loan_first.jpeg`, `assets/loan_second_final.jpeg` (step 1)
/// and `assets/loan_first_below.jpeg` (step 2), and wired to
/// docs/backend/FLUTTER_LOAN_APPLICATION_GUIDE.md.
///
/// ## Why two steps
///
/// The comp splits it that way, and the split falls on a real seam: everything
/// on step 1 is about the applicant and is the same on every application they
/// ever make, while step 2 is about this particular loan. Step 1 is validated
/// on Continue, so nobody reaches the terms checkbox with a broken PAN behind
/// them.
///
/// Validation is split by control type. The text fields are the app's shared
/// [CommonTextField] inside a [Form], so each carries its own validator and
/// reports itself. The comp's other controls — the DOB dropdowns, the selects,
/// the tenure chips — are not `TextFormField`s and cannot join a [Form], so
/// those are checked by hand on Continue / Apply and their messages live in
/// [_errors], keyed by field.
class QuickLoanApplyScreen extends StatefulWidget {
  const QuickLoanApplyScreen({super.key});

  @override
  State<QuickLoanApplyScreen> createState() => _QuickLoanApplyScreenState();
}

class _QuickLoanApplyScreenState extends State<QuickLoanApplyScreen> {
  late final LoanApplicationController _ctrl;

  /// `getOrPut`, so a user who backs out and re-enters keeps a half-filled
  /// form instead of starting over.
  @override
  void initState() {
    super.initState();
    _ctrl = getOrPut(() => LoanApplicationController());
  }

  final _scrollController = ScrollController();

  /// Validates the TEXT fields — the ones that are now [CommonTextField]s and
  /// carry their own validators.
  ///
  /// One key for both steps is correct rather than lazy: the two steps swap in
  /// the same subtree, so only one step's fields are ever mounted, and
  /// `validate()` therefore only ever judges the step the user is looking at.
  final _formKey = GlobalKey<FormState>();

  /// Field key → message, for the controls a [Form] cannot reach: the DOB
  /// dropdowns, the tenure chips and the select fields. Those are not
  /// `TextFormField`s, so they have no validator of their own and are checked
  /// by hand on Continue / Apply.
  final Map<String, String> _errors = {};

  /// Which half of the form is showing.
  bool _onLoanStep = false;

  // Field keys — string constants so a typo in one of the two places a key is
  // used (set here, read by the widget) is a visible mismatch rather than a
  // silently absent error.
  //
  // Only the NON-text controls have one. Every text field moved to
  // [CommonTextField] and now carries its own validator, so the keys for those
  // are gone rather than left behind as two ways to say the same thing.
  static const _kDob = 'dob';
  static const _kNature = 'nature';
  static const _kExperience = 'experience';
  static const _kPurpose = 'purpose';
  static const _kTenure = 'tenure';
  static const _kResidence = 'residence';

  /// Loan purposes offered by the dropdown.
  ///
  /// Bundled, not fetched: `/options` serves profession, residence and status
  /// enums only, and the field is free text on the wire — so this is a
  /// convenience list, and whatever is picked goes across as the string it is.
  static const List<String> _loanPurposes = [
    'Personal Expenses',
    'Home Renovation',
    'Business Expansion',
    'Education',
    'Medical',
    'Wedding',
    'Travel',
    'Vehicle Purchase',
    'Debt Consolidation',
    'Other',
  ];

  /// Same contract as [_loanPurposes] — free text on the wire.
  static const List<String> _businessNatures = [
    'Manufacturing',
    'Trading',
    'Retail',
    'Wholesale',
    'Services',
    'Agriculture',
    'Transport',
    'Construction',
    'Freelancing',
    'Other',
  ];

  /// The comp's five pills. MONTHS — the wire field is months, and the label
  /// says so, because the neighbouring "Business Experience" is years.
  static const List<int> _tenures = [3, 6, 12, 24, 36];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// One text field, in the app's shared [CommonTextField].
  ///
  /// It draws its own `title` above the input, so these do NOT go inside a
  /// [LoanField] — that would print the label twice. [LoanField] is still used
  /// for the dropdowns and the DOB row, which have no label of their own.
  ///
  /// `onUserInteraction`, NOT `always`: a field stays quiet until it has been
  /// touched, then re-checks itself on every keystroke. `always` was tried and
  /// dropped because it greets an untouched form with five red errors — the
  /// applicant is scolded for not having filled in a form they have not started.
  ///
  /// The submit path still catches an untouched-but-empty field: `_continue()`
  /// and `_apply()` call `_formKey.currentState.validate()`, which forces every
  /// mounted field to show its error regardless of this mode.
  ///
  /// This is also [CommonTextField]'s own default; it is passed explicitly so
  /// the choice is visible here rather than inherited silently.
  Widget _text({
    required TextEditingController controller,
    required String title,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    int? maxLength,
    String? prefixText,
    bool upperCase = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size14),
      child: CommonTextField(
        textEditController: controller,
        title: title,
        hintText: hint,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        keyBoardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLine: maxLines,
        minLines: maxLines > 1 ? maxLines : null,
        maxLength: maxLength,
        prefixText: prefixText,
        // The shared field only offers all-caps, no word-caps, so this is the
        // PAN field's switch and nothing else's.
        isCapitalize: upperCase,
      ),
    );
  }

  void _setErrors(Map<String, String?> next) {
    setState(() {
      next.forEach((key, message) {
        if (message == null || message.isEmpty) {
          _errors.remove(key);
        } else {
          _errors[key] = message;
        }
      });
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // Step 1 — personal + professional
  // ─────────────────────────────────────────────────────────────────
  /// Validates step 1 and moves on.
  ///
  /// Two halves, because the step has two kinds of control. The text fields
  /// answer for themselves through the [Form]; only the DOB row and the two
  /// self-employed selects are checked here. The employment branch judged is
  /// the one the user actually chose — and since the other branch's fields are
  /// UNMOUNTED, `validate()` never sees them either, so the two halves agree
  /// without the `salaried ? … : null` bookkeeping this used to carry.
  void _continue() {
    final salaried = _ctrl.isSalaried;
    final textOk = _formKey.currentState?.validate() ?? false;
    _setErrors({
      _kDob: LoanValidators.dob(_ctrl.dob,
          anyPartChosen: _ctrl.dobPartiallyChosen),
      _kNature: salaried
          ? null
          : LoanValidators.required(
              AppStrings.loanNatureOfBusiness.tr)(_ctrl.natureOfBusiness.value),
      _kExperience: salaried
          ? null
          : (_ctrl.businessExperienceYears.value == null
              ? AppStrings.loanFieldRequiredFmt
                  .trParams({'field': AppStrings.loanBusinessExperience.tr})
              : null),
    });

    if (!textOk || _errors.isNotEmpty) {
      _scrollToTop();
      return;
    }
    setState(() => _onLoanStep = true);
    _scrollToTop();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Step 2 — loan details
  // ─────────────────────────────────────────────────────────────────
  Future<void> _apply() async {
    // Amount, EMI and pincode carry their own validators now — including the
    // EMI's conditional one, which the backend cares about: it refuses
    // `isMonthlyEmi: true` with a zero amount. What is left here is the purpose
    // select, the tenure chips and the residence select, none of which are
    // text fields the [Form] can reach.
    final textOk = _formKey.currentState?.validate() ?? false;
    _setErrors({
      _kPurpose: LoanValidators.required(
          AppStrings.loanPurpose.tr)(_ctrl.loanPurpose.value),
      _kTenure: _ctrl.loanTenureMonths.value == null
          ? AppStrings.loanFieldRequiredFmt
              .trParams({'field': AppStrings.loanTenure.tr})
          : null,
      _kResidence: _ctrl.residenceType.value == null
          ? AppStrings.loanFieldRequiredFmt
              .trParams({'field': AppStrings.loanCurrentResidence.tr})
          : null,
    });

    if (!textOk || _errors.isNotEmpty) {
      _scrollToTop();
      return;
    }

    final created = await _ctrl.submit();
    if (!mounted) return;
    // A null with no error message means the server accepted it but answered
    // in a shape we didn't expect — the application exists either way, so it
    // is treated as the success it is.
    if (created == null && _ctrl.submitError.value.isNotEmpty) return;
    await _showSubmitted();
  }

  /// The confirmation. The application lands as `pending` and only an admin
  /// moves it, so the copy promises a review rather than a decision.
  Future<void> _showSubmitted() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SizeConfig.size16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                size: SizeConfig.size48, color: AppColors.green00),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              AppStrings.loanSubmittedTitle.tr,
              fontSize: SizeConfig.size18,
              fontWeight: FontWeight.w800,
              color: LoanPalette.heading,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              AppStrings.loanSubmittedBody.tr,
              fontSize: SizeConfig.size13,
              fontWeight: FontWeight.w500,
              color: LoanPalette.label,
              textAlign: TextAlign.center,
              height: 1.4,
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: CustomText(
                AppStrings.done.tr,
                fontSize: SizeConfig.size15,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
    if (mounted) Get.back();
  }

  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoanPalette.canvas,
      appBar: CommonBackAppBar(
        // `isLeading` puts the back chevron immediately before the title, which
        // is the comp's layout — the title sits next to the arrow, not centred.
        isLeading: true,
        title: AppStrings.quickLoanApply.tr,
        appBarColor: AppColors.white,
        // Flat, as drawn. The shared bar defaults to elevation 4, which would
        // cast a shadow onto the pale page and cut the header off from the
        // cards it belongs with.
        showElevation: 0,
        // Back on step 2 returns to step 1 rather than leaving the form — the
        // applicant has typed a screenful by then, and losing it to a
        // misjudged tap is the one thing this form cannot afford.
        onBackTap: () {
          if (_onLoanStep) {
            setState(() => _onLoanStep = false);
            _scrollToTop();
            return;
          }
          Get.back();
        },
      ),
      bottomNavigationBar: _bottomBar(),
      body: SafeArea(
        child: Obx(() {
          // Read here so both steps rebuild on a profession switch.
          final salaried = _ctrl.isSalaried;
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size14,
                SizeConfig.size14,
                SizeConfig.size14,
                SizeConfig.size24,
              ),
              child: _onLoanStep ? _loanStep() : _personalStep(salaried),
            ),
          );
        }),
      ),
    );
  }

  Widget _personalStep(bool salaried) {
    return Column(
      children: [
        LoanSectionCard(
          iconPath: AppIconAssets.loanPersonalDetailsIcon,
          title: AppStrings.loanPersonalDetails.tr,
          subtitle: AppStrings.loanPersonalDetailsSub.tr,
          children: [
            _text(
              controller: _ctrl.nameCtrl,
              title: AppStrings.loanName.tr,
              hint: AppStrings.loanNameHint.tr,
              validator: LoanValidators.required(AppStrings.loanName.tr),
            ),
            // Not a text field — three dropdowns — so it keeps [LoanField] and
            // the manual error slot.
            LoanField(
              label: AppStrings.loanDob.tr,
              error: _errors[_kDob],
              child: _dobRow(),
            ),
            _text(
              controller: _ctrl.mobileCtrl,
              title: AppStrings.loanMobileNumber.tr,
              hint: AppStrings.loanMobileHint.tr,
              validator: LoanValidators.mobile,
              keyboardType: TextInputType.phone,
              prefixText: '+91 ',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            _text(
              controller: _ctrl.addressCtrl,
              title: AppStrings.loanAddress.tr,
              hint: AppStrings.loanAddressHint.tr,
              validator: LoanValidators.required(AppStrings.loanAddress.tr),
              maxLines: 2,
              maxLength: AppConstants.inputCharterLimit250,
            ),
            _text(
              controller: _ctrl.panCtrl,
              title: AppStrings.loanPanNumber.tr,
              hint: AppStrings.loanPanHint.tr,
              validator: LoanValidators.pan,
              upperCase: true,
              inputFormatters: [
                LengthLimitingTextInputFormatter(10),
                const UpperCaseTextFormatter(),
              ],
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size14),
        LoanSectionCard(
          iconPath: AppIconAssets.loanProfessionalDetailsIcon,
          title: AppStrings.loanProfessionalDetails.tr,
          subtitle: AppStrings.loanProfessionalDetailsSub.tr,
          children: [
            // IntrinsicHeight is what makes `stretch` legal here.
            //
            // The two cards must match heights — the comp draws them level and
            // their subtitles are different lengths — and `stretch` is how a Row
            // does that. But stretch sizes children to the Row's own maxHeight,
            // and this Row sits inside a Column inside a vertical
            // SingleChildScrollView, so that maxHeight is INFINITY: the children
            // got an infinite tight height and layout threw, taking the whole
            // step-1 body down with it (the screen rendered its app bar and CTA
            // over an empty page). IntrinsicHeight measures the taller card
            // first and hands the Row a bounded height to stretch to.
            //
            // Affordable here precisely because it is two fixed cards; do not
            // reach for it over a long or lazily-built list.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: LoanProfessionCard(
                      title: AppStrings.loanSalaried.tr,
                      subtitle: AppStrings.loanSalariedSub.tr,
                      selected: salaried,
                      onTap: () => _ctrl.professionType.value =
                          ProfessionType.salaried,
                    ),
                  ),
                  SizedBox(width: SizeConfig.size10),
                  Expanded(
                    child: LoanProfessionCard(
                      title: AppStrings.loanSelfEmployed.tr,
                      subtitle: AppStrings.loanSelfEmployedSub.tr,
                      selected: !salaried,
                      onTap: () => _ctrl.professionType.value =
                          ProfessionType.business,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size16),
            _text(
              controller: _ctrl.annualIncomeCtrl,
              title: AppStrings.loanAnnualIncome.tr,
              hint: AppStrings.loanAnnualIncomeHint.tr,
              validator: LoanValidators.positiveAmount(
                  AppStrings.loanAnnualIncome.tr),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            // One branch at a time — the backend clears the other on save.
            if (salaried) ..._salariedFields() else ..._selfEmployedFields(),
          ],
        ),
      ],
    );
  }

  List<Widget> _salariedFields() => [
        _text(
          controller: _ctrl.companyNameCtrl,
          title: AppStrings.loanCompanyName.tr,
          hint: AppStrings.loanCompanyHint.tr,
          validator: LoanValidators.required(AppStrings.loanCompanyName.tr),
        ),
        _text(
          controller: _ctrl.jobRoleCtrl,
          title: AppStrings.loanJobRole.tr,
          hint: AppStrings.loanJobRoleHint.tr,
          validator: LoanValidators.required(AppStrings.loanJobRole.tr),
        ),
      ];

  List<Widget> _selfEmployedFields() => [
        _text(
          controller: _ctrl.businessNameCtrl,
          title: AppStrings.loanBusinessName.tr,
          hint: AppStrings.loanBusinessNameHint.tr,
          validator: LoanValidators.required(AppStrings.loanBusinessName.tr),
        ),
        LoanField(
          label: AppStrings.loanNatureOfBusiness.tr,
          error: _errors[_kNature],
          child: Obx(
            () => LoanDropdown<String>(
              value: _ctrl.natureOfBusiness.value,
              items: _businessNatures,
              itemLabel: (v) => v,
              hint: AppStrings.loanNatureHint.tr,
              hasError: _errors.containsKey(_kNature),
              onChanged: (v) => _ctrl.natureOfBusiness.value = v,
            ),
          ),
        ),
        LoanField(
          // YEARS, and labelled so — the tenure field two cards down is months.
          label: AppStrings.loanBusinessExperience.tr,
          error: _errors[_kExperience],
          child: Obx(
            () => LoanDropdown<int>(
              value: _ctrl.businessExperienceYears.value,
              items: const [1, 2, 3, 5, 7, 10, 15, 20, 25],
              itemLabel: (v) =>
                  AppStrings.loanYearsFmt.trParams({'years': '$v'}),
              hint: AppStrings.loanExperienceHint.tr,
              hasError: _errors.containsKey(_kExperience),
              onChanged: (v) => _ctrl.businessExperienceYears.value = v,
            ),
          ),
        ),
        // Not in the comp, but REQUIRED by the API for a Business applicant —
        // without it every self-employed submission would be refused with a
        // validation error the form could not explain.
        _text(
          controller: _ctrl.businessAddressCtrl,
          title: AppStrings.loanBusinessAddress.tr,
          hint: AppStrings.loanBusinessAddressHint.tr,
          validator: LoanValidators.required(AppStrings.loanBusinessAddress.tr),
          maxLines: 2,
          maxLength: AppConstants.inputCharterLimit250,
        ),
      ];

  /// DD / MM / YYYY as three dropdowns, per the comp.
  ///
  /// The day list is a flat 1–31 rather than one trimmed to the chosen month:
  /// trimming would silently drop a day the user had already picked when they
  /// changed the month, and [composeDob] rejects an impossible date anyway.
  Widget _dobRow() {
    final hasError = _errors.containsKey(_kDob);
    final currentYear = DateTime.now().year;
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: LoanDropdown<int>(
              value: _ctrl.dobDay.value,
              items: [for (var d = 1; d <= 31; d++) d],
              itemLabel: (v) => v.toString().padLeft(2, '0'),
              hint: AppStrings.loanDd.tr,
              hasError: hasError,
              onChanged: (v) => _ctrl.dobDay.value = v,
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: LoanDropdown<int>(
              value: _ctrl.dobMonth.value,
              items: [for (var m = 1; m <= 12; m++) m],
              itemLabel: (v) => v.toString().padLeft(2, '0'),
              hint: AppStrings.loanMm.tr,
              hasError: hasError,
              onChanged: (v) => _ctrl.dobMonth.value = v,
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          Expanded(
            child: LoanDropdown<int>(
              value: _ctrl.dobYear.value,
              // 18 is the floor because nobody younger can hold a loan; 100
              // years is simply the far end of a plausible applicant.
              items: [
                for (var y = currentYear - 18; y >= currentYear - 100; y--) y
              ],
              itemLabel: (v) => '$v',
              hint: AppStrings.loanYyyy.tr,
              hasError: hasError,
              onChanged: (v) => _ctrl.dobYear.value = v,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  Widget _loanStep() {
    return LoanSectionCard(
      iconPath: AppIconAssets.loanDetailsIcon,
      title: AppStrings.loanDetails.tr,
      subtitle: AppStrings.loanDetailsSub.tr,
      children: [
        _text(
          controller: _ctrl.loanAmountCtrl,
          title: AppStrings.loanRequiredAmount.tr,
          hint: AppStrings.loanAmountHint.tr,
          validator:
              LoanValidators.positiveAmount(AppStrings.loanRequiredAmount.tr),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        LoanField(
          label: AppStrings.loanPurpose.tr,
          error: _errors[_kPurpose],
          child: Obx(
            () => LoanDropdown<String>(
              value: _ctrl.loanPurpose.value,
              items: _loanPurposes,
              itemLabel: (v) => v,
              hint: AppStrings.loanPurposeHint.tr,
              hasError: _errors.containsKey(_kPurpose),
              onChanged: (v) => _ctrl.loanPurpose.value = v,
            ),
          ),
        ),
        // A heading, not a field label — the comp sets it noticeably bolder
        // and larger than "Loan Purpose" above it, because the pills under it
        // are not a field but a choice.
        CustomText(
          AppStrings.loanPreferredTenure.tr,
          fontSize: SizeConfig.size18,
          fontWeight: FontWeight.w800,
          color: LoanPalette.heading,
        ),
        SizedBox(height: SizeConfig.size10),
        Obx(
          () => Wrap(
            spacing: SizeConfig.size10,
            runSpacing: SizeConfig.size10,
            children: [
              for (final months in _tenures)
                LoanChoiceChip(
                  label: AppStrings.loanMonthsFmt
                      .trParams({'months': '$months'}),
                  selected: _ctrl.loanTenureMonths.value == months,
                  onTap: () => _ctrl.loanTenureMonths.value = months,
                ),
            ],
          ),
        ),
        if (_errors.containsKey(_kTenure)) ...[
          SizedBox(height: SizeConfig.size6),
          CustomText(
            _errors[_kTenure]!,
            fontSize: SizeConfig.size11,
            fontWeight: FontWeight.w600,
            color: LoanPalette.error,
            maxLines: 2,
          ),
        ],
        SizedBox(height: SizeConfig.size16),
        // The EMI row: label on the left, the "No Existing EMI" opt-out on the
        // right, exactly as drawn. Ticking it disables the amount below rather
        // than hiding it, so the row doesn't reflow under the finger that
        // ticked it.
        Obx(() {
          final noEmi = _ctrl.noExistingEmi.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      AppStrings.loanExistingEmi.tr,
                      fontSize: SizeConfig.size13,
                      fontWeight: FontWeight.w500,
                      color: LoanPalette.label,
                    ),
                  ),
                  // Flexible, NOT bare: a non-flex child of a Row is laid out
                  // with an UNBOUNDED max width, and [LoanCheckRow] flexes its
                  // label internally — a flex child under unbounded width is
                  // the assertion that took the whole screen down, since every
                  // ancestor up to the scroll view then reports "was not laid
                  // out". This gives it a bounded slot.
                  Flexible(
                    child: LoanCheckRow(
                      value: noEmi,
                      onChanged: (v) {
                        _ctrl.noExistingEmi.value = v;
                        // Clearing on tick keeps the field and the flag from
                        // disagreeing about what was declared.
                        if (v) _ctrl.existingEmiCtrl.clear();
                      },
                      child: CustomText(
                        AppStrings.loanNoExistingEmi.tr,
                        fontSize: SizeConfig.size12,
                        fontWeight: FontWeight.w600,
                        color: LoanPalette.label,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size6),
              Opacity(
                opacity: noEmi ? 0.5 : 1,
                child: IgnorePointer(
                  ignoring: noEmi,
                  // Title-less: the label is the Row above, shared with the
                  // opt-out. The validator closes over [noEmi] because this is
                  // the one CONDITIONAL field — ticking the box makes an empty
                  // value correct, and the Obx rebuild re-runs it.
                  child: _text(
                    controller: _ctrl.existingEmiCtrl,
                    title: '',
                    hint: AppStrings.loanEmiHint.tr,
                    validator: (v) => noEmi
                        ? null
                        : LoanValidators.positiveAmount(
                            AppStrings.loanExistingEmi.tr)(v),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ),
            ],
          );
        }),
        _text(
          controller: _ctrl.pincodeCtrl,
          title: AppStrings.loanPincode.tr,
          hint: AppStrings.loanPincodeHint.tr,
          validator: LoanValidators.pincode,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
        ),
        LoanField(
          label: AppStrings.loanCurrentResidence.tr,
          error: _errors[_kResidence],
          child: Obx(
            () => LoanDropdown<ResidenceType>(
              value: _ctrl.residenceType.value,
              items: _ctrl.residenceOptions.toList(),
              // The wire value IS the display label — Title Case on purpose,
              // and sent back exactly as received.
              itemLabel: (v) => v.wire,
              hint: AppStrings.loanResidenceHint.tr,
              hasError: _errors.containsKey(_kResidence),
              onChanged: (v) => _ctrl.residenceType.value = v,
            ),
          ),
        ),
        SizedBox(height: SizeConfig.size4),
        Obx(
          () => LoanCheckRow(
            value: _ctrl.termsAccepted.value,
            crossAxisAlignment: CrossAxisAlignment.start,
            onChanged: (v) => _ctrl.termsAccepted.value = v,
            child: _termsText(),
          ),
        ),
      ],
    );
  }

  /// "I agree to the Terms & Conditions and authorize the lender to verify my
  /// information and credit eligibility."
  ///
  /// The "Terms & Conditions" phrase is styled as the comp draws it but is
  /// **not yet tappable**: the app has no terms screen or hosted URL to send
  /// the applicant to, and a link to a guessed destination is worse than one
  /// that is plainly typographic. The sentence authorises a credit check, so
  /// the document behind it should be reachable — attach a recognizer here the
  /// moment there is somewhere for it to go.
  Widget _termsText() {
    final style = TextStyle(
      fontSize: SizeConfig.size12,
      fontWeight: FontWeight.w500,
      color: LoanPalette.label,
      height: 1.4,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: '${AppStrings.loanTermsPrefix.tr} '),
          TextSpan(
            text: AppStrings.termsConditions.tr,
            style: style.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: ' ${AppStrings.loanTermsSuffix.tr}'),
        ],
      ),
      maxLines: 4,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  Widget _bottomBar() {
    return Container(
      // White, as drawn — the CTA sits on its own strip rather than on the
      // pale page, which is what separates it from the card that scrolls
      // behind it.
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size14,
            SizeConfig.size8,
            SizeConfig.size14,
            SizeConfig.size14,
          ),
          child: Obx(() {
            final busy = _ctrl.isSubmitting.value;
            // Step 1's button is always live — it is what REPORTS what is
            // missing. Step 2's is gated on the terms, which is a consent the
            // applicant has to give rather than one a tap can imply.
            final enabled =
                !busy && (!_onLoanStep || _ctrl.termsAccepted.value);
            return GestureDetector(
              onTap: enabled ? (_onLoanStep ? _apply : _continue) : null,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: SizeConfig.size54,
                decoration: BoxDecoration(
                  color:
                      enabled ? AppColors.primaryColor : AppColors.grey9B,
                  borderRadius: BorderRadius.circular(SizeConfig.size12),
                ),
                alignment: Alignment.center,
                child: busy
                    ? SizedBox(
                        height: SizeConfig.size20,
                        width: SizeConfig.size20,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            _onLoanStep
                                ? AppStrings.loanApplyCta.tr
                                : AppStrings.loanContinueCta.tr,
                            fontSize: SizeConfig.size16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                          SizedBox(width: SizeConfig.size8),
                          Icon(Icons.arrow_forward_rounded,
                              size: SizeConfig.size20,
                              color: AppColors.white),
                        ],
                      ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
