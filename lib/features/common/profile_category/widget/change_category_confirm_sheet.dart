import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/profile_category/controller/profile_category_controller.dart';
import 'package:BlueEra/features/common/profile_category/model/category_option.dart';
import 'package:BlueEra/features/common/profile_category/model/profile_category_models.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Last stop before the one change is spent (§6's confirmation, §7's submit,
/// §8's error handling).
///
/// It is a sheet rather than a dialog because it sometimes has to collect
/// something — a sub-category, a drug licence number — and because the warning
/// it carries deserves more room than a dialog gives:
///
/// > You can only do this once. Some details tied to your current category
/// > will be cleared and you'll need to fill them in again.
///
/// That warning is not boilerplate. The backend deliberately wipes the fields
/// that described the old category (designation, specialization, department,
/// skills, sector…) and DELETES the individual's working hours, because they
/// described a job the user no longer has.
///
/// Returns true only when the change actually went through.
Future<bool?> showChangeCategoryConfirmSheet({
  required BuildContext context,
  required ProfileCategoryController controller,
  required CategoryOption option,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    // Not dismissible by scrim tap while a submit is in flight — see the
    // PopScope in the body. A tap-out mid-request would leave the user with no
    // idea whether their single allowance had just been spent.
    builder: (_) => _ConfirmSheet(controller: controller, option: option),
  );
}

class _ConfirmSheet extends StatefulWidget {
  const _ConfirmSheet({required this.controller, required this.option});

  final ProfileCategoryController controller;
  final CategoryOption option;

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  final TextEditingController _license = TextEditingController();
  CategorySubOption? _subCategory;

  /// Inline error under the licence field, from `400 license_required`.
  String? _licenseError;

  bool _submitting = false;

  CategoryOption get _option => widget.option;

  @override
  void initState() {
    super.initState();
    // A category with exactly one sub-category has no choice to offer.
    if (_option.subCategories.length == 1) {
      _subCategory = _option.subCategories.first;
    }
  }

  @override
  void dispose() {
    _license.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The request is in flight and the allowance may already be claimed;
      // backing out here would leave the user guessing.
      canPop: !_submitting,
      child: Padding(
        padding: EdgeInsets.only(
          left: SizeConfig.size16,
          right: SizeConfig.size16,
          top: SizeConfig.size12,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              SizeConfig.size16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: SizeConfig.size16),
                  decoration: BoxDecoration(
                    color: AppColors.greyE5,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              CustomText(
                AppStrings.changeCategoryConfirmTitle.tr
                    .replaceFirst('{category}', _option.name),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
              SizedBox(height: SizeConfig.size8),
              CustomText(
                AppStrings.changeCategoryConfirmBody.tr,
                fontSize: SizeConfig.medium,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center,
                maxLines: 5,
              ),
              if (_option.hasSubCategories) ...[
                SizedBox(height: SizeConfig.size16),
                _subCategoryPicker(),
              ],
              if (_option.requiresLicense) ...[
                SizedBox(height: SizeConfig.size16),
                _licenseField(),
              ],
              SizedBox(height: SizeConfig.size20),
              _submitButton(),
              SizedBox(height: SizeConfig.size4),
              TextButton(
                onPressed:
                    _submitting ? null : () => Navigator.of(context).pop(false),
                child: CustomText(
                  AppStrings.cancel.tr,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subCategoryPicker() {
    return DropdownButtonFormField<CategorySubOption>(
      initialValue: _subCategory,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: AppStrings.changeCategorySubCategory.tr,
        isDense: true,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _option.subCategories
          .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
          .toList(),
      onChanged:
          _submitting ? null : (v) => setState(() => _subCategory = v),
    );
  }

  Widget _licenseField() {
    return TextField(
      controller: _license,
      enabled: !_submitting,
      decoration: InputDecoration(
        labelText: AppStrings.changeCategoryLicense.tr,
        // Populated from the 400's `errors[]`, so the message is the
        // backend's own rather than a guess at what it wanted.
        errorText: _licenseError,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (_) {
        if (_licenseError != null) setState(() => _licenseError = null);
      },
    );
  }

  Widget _submitButton() {
    return GestureDetector(
      onTap: _submitting ? null : _submit,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _submitting
              ? AppColors.primaryColor.withValues(alpha: 0.6)
              : AppColors.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _submitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : CustomText(
                AppStrings.changeCategoryConfirmCta.tr,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _licenseError = null;
    });

    final result = await widget.controller.changeCategory(
      tagId: _option.tagId,
      subCategoryId: _subCategory?.id,
      licenseNumber:
          _license.text.trim().isEmpty ? null : _license.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result != null) {
      Navigator.of(context).pop(true);
      commonSnackBar(message: AppStrings.changeCategorySuccess.tr);
      return;
    }

    _handleFailure(widget.controller.lastErrorCode.value);
  }

  /// §8 — switch on the CODE, never the message.
  void _handleFailure(String code) {
    switch (code) {
      case ProfileCategoryErrorCode.licenseRequired:
        // Stays open with an inline field error: the user is one field away
        // from succeeding, and the allowance was not spent.
        setState(() =>
            _licenseError = AppStrings.changeCategoryLicenseRequired.tr);
        return;

      case ProfileCategoryErrorCode.sameCategory:
        // Shouldn't happen — the picker disables the current row — but if the
        // account changed underneath us there is nothing to fix, so close.
        Navigator.of(context).pop(false);
        commonSnackBar(message: AppStrings.changeCategorySameCategory.tr);
        return;

      case ProfileCategoryErrorCode.changeLimitReached:
        // The controller already re-read the state, so the row behind this
        // sheet is disabled by the time it closes.
        Navigator.of(context).pop(false);
        commonSnackBar(message: AppStrings.changeCategoryLimitReached.tr);
        return;

      case ProfileCategoryErrorCode.unknownCategory:
        // That option was retired or deleted between the catalog being cached
        // and the submit. Send them back to a fresh list.
        Navigator.of(context).pop(false);
        commonSnackBar(message: AppStrings.changeCategoryOptionGone.tr);
        return;

      case ProfileCategoryErrorCode.unsupportedAccountType:
        Navigator.of(context).pop(false);
        return;

      case ProfileCategoryErrorCode.businessNotFound:
        Navigator.of(context).pop(false);
        commonSnackBar(message: AppStrings.changeCategoryCompleteProfile.tr);
        return;

      default:
        if (widget.controller.isRetryable) {
          // Nothing was spent — the allowance is claimed before the backend
          // does any work and handed back if that work fails — so the sheet
          // stays open and the button is simply live again.
          commonSnackBar(message: AppStrings.changeCategoryRetry.tr);
          return;
        }
        Navigator.of(context).pop(false);
        commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    }
  }
}
