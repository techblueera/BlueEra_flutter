import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controller/add_bank_account_controller.dart';
import '../widget/upi_qr_widget.dart';

/// Add a payout method. Two levels of choice, both radio groups:
///   1. Bank Account  |  UPI
///   2. (UPI only) Enter UPI ID  |  Upload UPI QR
/// Exactly one input is on screen at a time — the QR is decoded on-device to
/// fill the same UPI ID the typed path uses, so both submit an identical
/// `upiDetails` payload.
class AddBankAccountScreen extends StatefulWidget {
  const AddBankAccountScreen({super.key});

  @override
  State<AddBankAccountScreen> createState() => _AddBankAccountScreenState();
}

class _AddBankAccountScreenState extends State<AddBankAccountScreen> {
  final controller = getOrPut(() => AddBankAccountController());

  @override
  void dispose() {
    // Drop the controller so the next open starts at the initial level — no
    // stale UPI/Bank selection or QR preview carried over from last time.
    deleteIfRegistered<AddBankAccountController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: controller.isupdate.value
            ? AppStrings.updateBankAccount
            : AppStrings.addBankAccount,
        isLeading: true,
      ),
      // Obx, because `isLoading` is read here: without it this AbsorbPointer
      // was evaluated once at build time and never actually blocked input
      // while a submit was in flight.
      body: Obx(
        () => AbsorbPointer(
          absorbing: controller.isLoading.value,
          child: SingleChildScrollView(
            child: Form(
              key: controller.formKey,
              child: CustomFormCard(
                margin: EdgeInsets.symmetric(
                  vertical: SizeConfig.size20,
                  horizontal: SizeConfig.size8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(AppStrings.selectAccountType),
                    SizedBox(height: SizeConfig.size12),
                    _buildMethodSelector(),
                    SizedBox(height: SizeConfig.paddingM),
                    Obx(() {
                      switch (controller.payoutMethod.value) {
                        case PayoutMethod.bank:
                          return _buildBankForm();
                        case PayoutMethod.upi:
                          return _buildUpiForm();
                        case null:
                          return const SizedBox.shrink();
                      }
                    }),
                    SizedBox(height: SizeConfig.paddingL),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared bits ────────────────────────────────────────────────────

  Widget _label(String text) => CustomText(
        text,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w400,
        color: AppColors.mainTextColor,
      );

  /// A radio group laid out as one bounded row.
  ///
  /// Both options are [Flexible] with the default loose fit, so each takes its
  /// intrinsic width and the row packs them at the start — they sit together on
  /// the left instead of being pushed to equal halves — while still being able
  /// to shrink. Nothing here is ever measured unbounded, which is what a `Wrap`
  /// did (its children lay out against the wrap's own main-axis limit) and what
  /// let the label row overflow by an absurd width.
  Widget _radioRow<T>(
    T firstValue,
    String firstLabel,
    T secondValue,
    String secondLabel,
  ) {
    return Row(
      children: [
        Flexible(child: _radio(firstValue, firstLabel)),
        SizedBox(width: _radioGap),
        Flexible(child: _radio(secondValue, secondLabel)),
      ],
    );
  }

  /// One tappable radio option. The whole row is the hit target, not just the
  /// dot. The label is [Flexible] + ellipsised so a long translation shrinks
  /// rather than overflowing.
  Widget _radio<T>(T value, String label) {
    return InkWell(
      onTap: () => _onRadioTap(value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<T>(
            value: value,
            fillColor: WidgetStateProperty.all(AppColors.primaryColor),
            activeColor: AppColors.primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(width: SizeConfig.size8),
          Flexible(
            child: CustomText(
              label,
              fontSize: SizeConfig.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Gap between the two options in a radio group.
  double get _radioGap => SizeConfig.size24;

  /// Routes a row tap to the matching controller setter — [Radio] itself only
  /// reacts to taps on the dot, so the row's InkWell has to do this by hand.
  void _onRadioTap<T>(T value) {
    if (value is PayoutMethod) controller.selectPayoutMethod(value);
    if (value is UpiEntryMode) controller.selectUpiEntryMode(value);
  }

  Widget _buildMethodSelector() {
    return Obx(
      () => RadioGroup<PayoutMethod>(
        groupValue: controller.payoutMethod.value,
        onChanged: (v) => v == null ? null : controller.selectPayoutMethod(v),
        child: _radioRow(
          PayoutMethod.bank,
          AppStrings.bankAccount.tr,
          PayoutMethod.upi,
          AppStrings.upi.tr,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Obx(
      () => CustomBtn(
        onTap: controller.submit,
        title: controller.isupdate.value
            ? AppStrings.update.tr
            : AppStrings.add.tr,
        isLoading: controller.isLoading.value,
        bgColor: AppColors.primaryColor,
        textColor: AppColors.white,
        radius: SizeConfig.size8,
        height: SizeConfig.buttonXL,
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ── Bank form ──────────────────────────────────────────────────────

  Widget _buildBankForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(AppStrings.bankName),
        SizedBox(height: SizeConfig.size8),
        CommonTextField(
          textEditController: controller.bankNameController,
          hintText: AppStrings.bankNameHint.tr,
          keyBoardType: TextInputType.text,
          validator: ValidationMethod.validateBankName,
          maxLength: AppConstants.inputCharterLimit20,
          contentPadding: _fieldPadding,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.&-]')),
          ],
        ),
        SizedBox(height: SizeConfig.paddingM),
        _label(AppStrings.bankHolderName),
        SizedBox(height: SizeConfig.size8),
        CommonTextField(
          textEditController: controller.bankHolderNameController,
          hintText: AppStrings.bankHolderNameHint.tr,
          maxLength: AppConstants.inputCharterLimit20,
          keyBoardType: TextInputType.text,
          validator: ValidationMethod.validateBankHolderName,
          contentPadding: _fieldPadding,
        ),
        SizedBox(height: SizeConfig.paddingM),
        _label(AppStrings.accountNumber),
        SizedBox(height: SizeConfig.size8),
        CommonTextField(
          textEditController: controller.accountNumberController,
          hintText: AppStrings.accountNumberHint.tr,
          keyBoardType: TextInputType.number,
          validator: ValidationMethod.validateAccountNumber,
          contentPadding: _fieldPadding,
          inputLength: 18,
        ),
        SizedBox(height: SizeConfig.paddingM),
        _label(AppStrings.ifscCode),
        SizedBox(height: SizeConfig.size8),
        CommonTextField(
          textEditController: controller.ifscCodeController,
          hintText: AppStrings.ifscCodeHint.tr,
          keyBoardType: TextInputType.text,
          inputLength: 11,
          validator: ValidationMethod.validateIfscCode,
          isCapitalize: true,
          contentPadding: _fieldPadding,
        ),
      ],
    );
  }

  // ── UPI form ───────────────────────────────────────────────────────

  Widget _buildUpiForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(AppStrings.linkMobileNumberToUpi),
        SizedBox(height: SizeConfig.size8),
        _buildLinkedMobileField(),
        SizedBox(height: SizeConfig.paddingM),

        /// Second choice: type the ID, or upload the QR and let the backend
        /// read the details off it.
        Obx(
          () => RadioGroup<UpiEntryMode>(
            groupValue: controller.upiEntryMode.value,
            onChanged: (v) =>
                v == null ? null : controller.selectUpiEntryMode(v),
            child: _radioRow(
              UpiEntryMode.typeId,
              AppStrings.enterUpiIdOption,
              UpiEntryMode.uploadQr,
              AppStrings.uploadUpiQrOption,
            ),
          ),
        ),
        SizedBox(height: SizeConfig.paddingM),

        // Exactly one input per mode: the QR upload, or the UPI ID field. In QR
        // mode there is deliberately no UPI ID box — nothing on the device
        // reads the code, so any value there would be a guess.
        Obx(
          () => controller.upiEntryMode.value == UpiEntryMode.uploadQr
              ? _buildQrUploadSection()
              : _buildUpiIdField(),
        ),
      ],
    );
  }

  Widget _buildLinkedMobileField() {
    return Row(
      children: [
        /// Fixed country code.
        Container(
          height: SizeConfig.size45,
          width: SizeConfig.size57,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.greyE5, width: 1),
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomText("+91", fontSize: SizeConfig.large),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: CommonTextField(
            textEditController: controller.linkedMobileController,
            hintText: AppStrings.linkMobileNumberHint,
            keyBoardType: TextInputType.number,
            validator: controller.validateLinkedMobile,
            inputLength: 10,
            maxLength: 10,
            contentPadding: _fieldPadding,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      ],
    );
  }

  /// The typed-UPI-ID path, with the live QR rendered from what's entered.
  Widget _buildUpiIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(AppStrings.upiId),
        SizedBox(height: SizeConfig.size8),
        CommonTextField(
          textEditController: controller.upiIdController,
          hintText: AppStrings.upiIdHint.tr,
          keyBoardType: TextInputType.text,
          validator: controller.upiValidate,
          onChange: (val) => controller.upiInput.value = val,
          contentPadding: _fieldPadding,
          borderColor: AppColors.greyE5,
          borderWidth: 1,
        ),
        Obx(() {
          if (!controller.isUpiInputValid) return const SizedBox.shrink();
          return Padding(
            padding: EdgeInsets.only(top: SizeConfig.paddingM),
            child: UpiQrPreview(upiId: controller.upiInput.value.trim()),
          );
        }),
      ],
    );
  }

  /// The upload-QR path. The photo IS the submission here — it goes up as
  /// `upiDetails.qrImage` and the backend reads the UPI details off it — so
  /// once picked it's shown back at full width to confirm it's legible.
  Widget _buildQrUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(AppStrings.uploadUpiQrTitle),
        SizedBox(height: SizeConfig.size4),
        CustomText(
          AppStrings.uploadUpiQrSubtitle,
          fontSize: SizeConfig.small,
          color: AppColors.coloGreyText,
          maxLines: 2,
        ),
        SizedBox(height: SizeConfig.size8),
        Obx(() {
          final file = controller.upiQrImage.value;
          return file == null ? _buildQrUploadTile() : _buildQrPreview(file);
        }),
      ],
    );
  }

  Widget _buildQrUploadTile() {
    return InkWell(
      onTap: () => controller.pickUpiQrImage(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16,
          vertical: SizeConfig.size12,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.greyE5, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 18,
              color: AppColors.primaryColor,
            ),
            SizedBox(width: SizeConfig.size8),
            Flexible(
              child: CustomText(
                AppStrings.uploadUpiQrCta,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrPreview(File file) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            height: SizeConfig.size200,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: SizeConfig.size8),
        InkWell(
          onTap: () => controller.pickUpiQrImage(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded,
                    size: 16, color: AppColors.primaryColor),
                SizedBox(width: SizeConfig.size6),
                CustomText(
                  AppStrings.changeUpiQr,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  EdgeInsetsGeometry get _fieldPadding => EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size12,
      );
}
