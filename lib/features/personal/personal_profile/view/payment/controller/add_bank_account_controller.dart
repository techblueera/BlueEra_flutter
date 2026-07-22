import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/image_upload_response_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/repo/my_document_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/model/add_account_modal.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/repo/payment_repo.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';

/// The payout method being added. Replaces the old free-string
/// 'Bank Account' / 'UPI' / 'Select Account' triple — "nothing chosen yet" is
/// now simply a null [AddBankAccountController.payoutMethod].
enum PayoutMethod { bank, upi }

/// How the user supplies their UPI ID: type it, or upload the QR and let the
/// app read it. Both end up in the same `upiIdController`, so the submitted
/// payload is identical either way.
enum UpiEntryMode { typeId, uploadQr }

class AddBankAccountController extends GetxController {
  final TextEditingController bankHolderNameController = TextEditingController();
  final TextEditingController upiIdController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();

  /// Mobile number linked to a UPI — shown in place of the bank-name field on
  /// the UPI form and sent as `upiDetails.mobileNumber`.
  final TextEditingController linkedMobileController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController ifscCodeController = TextEditingController();
  AddAccountResponseModalClass? addAccountResponseModalClass;
  RxBool isUpiValidate = true.obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  RxBool isLoading = false.obs;
  RxBool isupdate = false.obs;
  String accountId = "";
  RxBool isDefault = false.obs;

  /// Null until the user picks one — the radio group starts unselected.
  final Rxn<PayoutMethod> payoutMethod = Rxn<PayoutMethod>();

  /// Only meaningful while [payoutMethod] is [PayoutMethod.upi].
  final Rx<UpiEntryMode> upiEntryMode = UpiEntryMode.typeId.obs;

  /// Mirrors the UPI ID field so the Add screen can render a live QR preview.
  final RxString upiInput = ''.obs;

  /// True once [upiInput] is a syntactically valid UPI ID (drives the QR).
  bool get isUpiInputValid => upiRegex.hasMatch(upiInput.value.trim());

  /// The picked UPI QR photo. Held locally and only uploaded on submit, where
  /// it becomes `upiDetails.qrImage` and the backend reads the UPI details off
  /// it — this is the whole payload in QR mode, so it is required there.
  final Rxn<File> upiQrImage = Rxn<File>();

  @override
  void onInit() {
    args();
    super.onInit();
  }

  @override
  void onClose() {
    bankNameController.dispose();
    accountNumberController.dispose();
    ifscCodeController.dispose();
    linkedMobileController.dispose();
    super.onClose();
  }

  void args() {
    var data = Get.arguments;
    if (data != null && (data as Map).keys.isNotEmpty) {
      isupdate.value = true;
      // Update only ever edits a bank account (updateAccount posts
      // `type: "BANK"`), so preselect it — otherwise the screen opens on an
      // empty form and the prefilled fields stay hidden until the user picks
      // the radio.
      payoutMethod.value = PayoutMethod.bank;
      bankNameController.text = data["BankName"];
      accountId = data["AccountId"];
      accountNumberController.text = data["Account"];
      ifscCodeController.text = data["IfscCode"];
      isDefault = data['isDefault'];
      bankHolderNameController.text = data['accountHolderName'] ?? "";
      update();
    }
  }
  // UPI VPA: <handle>@<psp> e.g. john.doe-1@oksbi, 9876543210@ybl
  // - handle (before @): 2-256 of letters/digits/._-
  // - psp (after @): 2-64 letters only (oksbi, ybl, paytm, apl …)
  final upiRegex = RegExp(r'^[a-zA-Z0-9._\-]{2,256}@[a-zA-Z]{2,64}$');
  String? upiValidate(String? value) {
    if (value == null || value.trim().isEmpty) {
      isUpiValidate.value = false;
      return AppStrings.upiIdRequired.tr;
    }
    if (!upiRegex.hasMatch(value.trim())) {
      isUpiValidate.value = false;
      return AppStrings.invalidUpiId.tr;
    }
    isUpiValidate.value = true;
    return null;
  }

  /// Alternative to typing the UPI ID: pick a photo of the UPI QR.
  ///
  /// Nothing is read out of the image here — the QR is uploaded on submit and
  /// `/withdrawal-methods` derives the UPI details from it server-side. This
  /// only holds the file until then.
  Future<void> pickUpiQrImage(BuildContext context) async {
    final path = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.uploadUpiQrTitle,
    );
    if (path == null || path.isEmpty) return;
    upiQrImage.value = File(path);
  }

  /// Validates the UPI-linked mobile number — required, exactly 10 digits.
  String? validateLinkedMobile(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return AppStrings.mobileIsRequired.tr;
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
      return AppStrings.enterValidPhoneNumber.tr;
    }
    return null;
  }

  /// Single entry point for the Add/Update button — the screen no longer needs
  /// to know which API belongs to which method.
  Future<void> submit() async {
    switch (payoutMethod.value) {
      case PayoutMethod.bank:
        return isupdate.value ? updateAccount() : addAccount();
      case PayoutMethod.upi:
        return AddUpiApi();
      case null:
        commonSnackBar(message: AppStrings.pleaseSelectAccountType.tr);
    }
  }

  /// Switching method wipes the other side's input so a half-filled bank form
  /// can never ride along with a UPI submission (and vice versa).
  void selectPayoutMethod(PayoutMethod method) {
    if (payoutMethod.value == method) return;
    payoutMethod.value = method;
    if (method == PayoutMethod.bank) {
      _clearUpiFields();
    } else {
      bankNameController.clear();
      bankHolderNameController.clear();
      accountNumberController.clear();
      ifscCodeController.clear();
    }
  }

  /// Switching between typing and QR clears whatever the previous mode put in
  /// the field, so the badge and the value can't disagree.
  void selectUpiEntryMode(UpiEntryMode mode) {
    if (upiEntryMode.value == mode) return;
    upiEntryMode.value = mode;
    _clearUpiFields(keepMobile: true);
  }

  void _clearUpiFields({bool keepMobile = false}) {
    upiIdController.clear();
    upiInput.value = '';
    upiQrImage.value = null;
    isUpiValidate.value = true;
    if (!keepMobile) linkedMobileController.clear();
  }

  /// Uploads [file] via the shared pre-signed-URL flow and returns its public
  /// URL, or null if any step fails. Mirrors the document/KYC upload path.
  Future<String?> _uploadToS3(File file) async {
    try {
      final mimeType = getFileInfo(file)['mimeType'];
      if (mimeType == null) return null;

      final initResponse =
          await MyDocumentRepo().initDocumentFileUploadRepo(fileType: mimeType);
      if (!initResponse.isSuccess) return null;
      final initModel =
          ImageUploadResponseModel.fromJson(initResponse.response?.data);

      final uploadResponse = await ChannelRepo().uploadVideoToS3(
        file: file,
        fileType: mimeType,
        preSignedUrl: initModel.uploadUrl ?? '',
        onProgress: (_) {},
      );
      if (!(uploadResponse?.isSuccess ?? false)) return null;

      return initModel.fileUrl;
    } catch (e) {
      debugPrint('❌ UPI QR upload failed: $e');
      return null;
    }
  }

  Future<void> addAccount() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;
    AppLoader.show(message: "Adding bank account…");

    try {
      ResponseModel response = await PaymentRepo().postAddAccount(params:
        {
          ApiKeys.userId: "${userId}",
          ApiKeys.methodType: "BANK",
          ApiKeys.bankDetails: {
          ApiKeys.bankName: bankNameController.text,
          ApiKeys.accountNo:  accountNumberController.text,
          ApiKeys.ifscCode: ifscCodeController.text,
          ApiKeys.holderName: bankHolderNameController.text
          },
          ApiKeys.isDefault:  isDefault.value
        }
      );
      AppLoader.hide();
      isLoading.value = false;
      if (response.isSuccess) {
        commonSnackBar(message: response.message??AppStrings.bankAddedSuccessfully.tr);
        clearForm();
        // Return `true` so the caller knows something was actually added and
        // only then re-fetches the list (not on every back-press).
        Get.back(result: true);
      }else{
        // Keep the entered details so the user can fix + retry.
        commonSnackBar(message: response.message??AppStrings.somethingWentWrong);
      }
    } catch (e) {
      AppLoader.hide();
      isLoading.value = false;
      commonSnackBar(message: AppStrings.failedToAddAccount.tr);
    }
  }

  void clearForm(){
    bankNameController.clear();
    accountNumberController.clear();
    ifscCodeController.clear();
    bankHolderNameController.clear();
    upiIdController.clear();
    linkedMobileController.clear();
    // Reset the selection + live-QR state so re-opening the screen starts at
    // the initial level (no UPI/Bank section pre-expanded, no QR pre-shown).
    payoutMethod.value = null;
    upiEntryMode.value = UpiEntryMode.typeId;
    upiInput.value = '';
    upiQrImage.value = null;
    isUpiValidate.value = true;
    isupdate.value = false;
  }

  Future<void> AddUpiApi() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    final isQrMode = upiEntryMode.value == UpiEntryMode.uploadQr;
    final qrFile = upiQrImage.value;
    // In QR mode the UPI ID field isn't on screen, so the form has nothing to
    // validate for it — the image is the required input instead.
    if (isQrMode && qrFile == null) {
      commonSnackBar(message: AppStrings.uploadUpiQrRequired);
      return;
    }

    isLoading.value = true;
    AppLoader.show(message: "Adding UPI…");
    try {
      // Uploaded only now (not at pick time) so an abandoned form never leaves
      // an orphan file on S3.
      String? qrImageUrl;
      if (isQrMode) {
        qrImageUrl = await _uploadToS3(qrFile!);
        if ((qrImageUrl ?? '').isEmpty) {
          // The QR is the only UPI identifier being sent in this mode — without
          // it there is nothing to save, so stop rather than post a blank UPI.
          AppLoader.hide();
          isLoading.value = false;
          commonSnackBar(message: AppStrings.upiQrUploadFailed);
          return;
        }
      }

      ResponseModel response = await PaymentRepo().postAddAccount(params:
      {
        ApiKeys.userId: "${userId}",
        ApiKeys.methodType: "UPI",
        // Exactly one UPI identifier goes up: the typed ID, or the QR the
        // backend reads it off. Never both.
        ApiKeys.upiDetails: {
          if (isQrMode)
            ApiKeys.qrImage: qrImageUrl
          else
            ApiKeys.upiId: upiIdController.text,
          ApiKeys.mobileNumber: linkedMobileController.text.trim(),
        },
        ApiKeys.isDefault:  false
      }
      );
      AppLoader.hide();
      isLoading.value = false;
      if (response.isSuccess) {
        commonSnackBar(message: response.message??AppStrings.bankAddedSuccessfully.tr);
        clearForm();
        Get.back(result: true);
      }else{
        commonSnackBar(message: response.message??AppStrings.somethingWentWrong);
      }
    } catch (e) {
      AppLoader.hide();
      isLoading.value = false;
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }


// Api calling for update Add BankAccount
  Future<void> updateAccount() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try{
      isLoading.value = true;
      var body = {
        // "type": "BANK",
        // "bank_name": bankNameController.text,
        // "account_number": accountNumberController.text,
        // "ifsc_code": ifscCodeController.text,
        // "upi_id": "",
        // "AccountId": accountId

        "type": "BANK",
        "bank_name": bankNameController.text,
        "account_holder_name": bankHolderNameController.text,
        "account_number": accountNumberController.text,
        "ifsc_code": ifscCodeController.text,
        // "account_type": selectedBankAccountType.value?.displayName,
        "upi_id": "",
        "isDefault": isDefault,
        "AccountId": accountId
      };
      print(body);
      print("TEEEESSSTTT");

      ResponseModel response =
      await PaymentRepo().updateAccount(Id: accountId, params: body);
      if (response.isSuccess) {
        addAccountResponseModalClass =
            AddAccountResponseModalClass.fromJson(response.response!.data);

        Get.back(result: {
          'bankName': bankNameController.text.trim(),
          'accountNumber': accountNumberController.text.trim(),
          'ifscCode': ifscCodeController.text.trim().toUpperCase(),
        });
        Get.snackbar(
          AppStrings.success.tr,
          addAccountResponseModalClass!.message ?? "",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }

    } catch (e) {
      Get.snackbar(
        AppStrings.error.tr,
        AppStrings.failedToUpdateAccount.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }

  }

}
