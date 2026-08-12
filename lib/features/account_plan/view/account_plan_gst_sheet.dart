import 'package:BlueEra/core/api/model/gst_verify_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/auth/repo/auth_repo.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../model/account_plan_models.dart';
import 'account_plan_catalog_view.dart' show AccountPlanPalette;

/// Asks for a GSTIN when the plan the user picked can't be sold without one.
///
/// The larger radius tiers are `gst_track: "GST"`; `initiate` refuses them
/// with a 400 unless `buyer_gstin` is present (guide §2.3). Rather than let the
/// user tap Contribute and be told no, this collects and VERIFIES the number
/// first, then hands it back so the purchase continues uninterrupted.
///
/// Same field rules and same verification API as [GstNumberScreen] — 15 chars,
/// forced uppercase, `RegularExpressionUtils.validateGSTIN`, then
/// `AuthRepo().getUserVerifyGstRepo`. What it deliberately does NOT reuse is
/// `AuthController.getGstVerify`: that one belongs to signup and, on success,
/// rewrites the business name from the GST trade name and navigates to the
/// create-account step. Firing that from a payment sheet would throw an
/// established business back into onboarding.
///
/// Returns the verified GSTIN, or null if the user dismissed it.
Future<String?> showAccountPlanGstSheet(
  BuildContext context, {
  required PlanCard card,
  String? initialGstin,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AccountPlanGstSheet(card: card, initialGstin: initialGstin),
  );
}

class _AccountPlanGstSheet extends StatefulWidget {
  const _AccountPlanGstSheet({required this.card, this.initialGstin});

  final PlanCard card;
  final String? initialGstin;

  @override
  State<_AccountPlanGstSheet> createState() => _AccountPlanGstSheetState();
}

class _AccountPlanGstSheetState extends State<_AccountPlanGstSheet> {
  final _formKey = GlobalKey<FormState>();
  final _gstController = TextEditingController();

  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _gstController.text = widget.initialGstin?.toUpperCase() ?? '';
  }

  @override
  void dispose() {
    _gstController.dispose();
    super.dispose();
  }

  /// Verifies the typed GSTIN and, only if the government check passes, returns
  /// it to the caller.
  ///
  /// An unverified number is not handed back: `initiate` would reject it and
  /// the user would read the failure as the payment breaking rather than as
  /// their GST being wrong.
  Future<void> _verify() async {
    if (_verifying) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final gstin = _gstController.text.trim().toUpperCase();
    setState(() => _verifying = true);
    try {
      final res = await AuthRepo().getUserVerifyGstRepo(gstNumber: gstin);
      if (!mounted) return;

      if (!res.isSuccess) {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong.tr);
        return;
      }
      final model = GstVerifyModel.fromJson(res.response?.data);
      if (model.isVerified != true) {
        commonSnackBar(
          message: res.message ?? AppStrings.pleaseEnterValidGstNumber.tr,
        );
        return;
      }
      // Prefer the GSTIN the verifier echoed back over the typed one — same
      // number, but normalised by whoever actually holds the record.
      Navigator.of(context).pop(model.data?.gstin?.trim().isNotEmpty == true
          ? model.data!.gstin!.trim().toUpperCase()
          : gstin);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size20,
            SizeConfig.size12,
            SizeConfig.size20,
            SizeConfig.size24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AccountPlanPalette.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size16),
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: SizeConfig.size20,
                      color: AccountPlanPalette.gstWarning,
                    ),
                    SizedBox(width: SizeConfig.size8),
                    Expanded(
                      child: CustomText(
                        AppStrings.gstRequired.tr,
                        fontSize: SizeConfig.size16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.size6),
                // Names the plan, and names the way out. A buyer who doesn't
                // have a GST registration is not stuck — the smaller tiers are
                // sold without one, and saying so here beats leaving them to
                // work it out from a rejection.
                CustomText(
                  '${widget.card.label} · ${AppStrings.gstRequiredForPlan.tr}',
                  fontSize: SizeConfig.size13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                  height: 1.4,
                  maxLines: 4,
                ),
                SizedBox(height: SizeConfig.size16),
                CommonTextField(
                  textEditController: _gstController,
                  title: AppStrings.enterGstNumberLabel.tr,
                  hintText: AppStrings.enterGstNumberLabel.tr,
                  maxLength: 15,
                  isValidate: false,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  // A GSTIN is written in capitals, so the soft keyboard opens
                  // shifted. The formatter below still uppercases whatever
                  // arrives — this is about not making the user hold shift for
                  // ten of the fifteen characters.
                  isCapitalize: true,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(15),
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    TextInputFormatter.withFunction(
                      (oldValue, newValue) =>
                          newValue.copyWith(text: newValue.text.toUpperCase()),
                    ),
                  ],
                  onChange: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.pleaseEnterGstNumber.tr;
                    }
                    if (!_gstRegExp.hasMatch(value.trim())) {
                      return AppStrings.pleaseEnterValidGstNumber.tr;
                    }
                    return null;
                  },
                ),
                SizedBox(height: SizeConfig.size16),
                // The button IS the progress indicator — [CustomBtn] swaps its
                // label for the wave loader and refuses taps while loading, and
                // the repo call runs with showProgress: false so nothing else
                // covers the sheet.
                CustomBtn(
                  title: AppStrings.submit.tr,
                  bgColor: AppColors.primaryColor,
                  radius: SizeConfig.size10,
                  isLoading: _verifying,
                  onTap: _verify,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // GSTIN format (15 chars): state code, PAN, entity number, 'Z', checksum.
  // Same expression the signup screen validates against.
  static final RegExp _gstRegExp = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}[A-Z]{1}[0-9A-Z]{1}$',
  );
}
