import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/model/add_account_modal.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/repo/payment_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';

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

  final RxString selectedBankAccountType = 'Select Account'.obs;

  /// Mirrors the UPI ID field so the Add screen can render a live QR preview.
  final RxString upiInput = ''.obs;

  /// True once [upiInput] is a syntactically valid UPI ID (drives the QR).
  bool get isUpiInputValid => upiRegex.hasMatch(upiInput.value.trim());


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

  /// Validates the UPI-linked mobile number — required, exactly 10 digits.
  String? validateLinkedMobile(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return AppStrings.mobileIsRequired.tr;
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
      return AppStrings.enterValidPhoneNumber.tr;
    }
    return null;
  }

  /// Validates the account-type dropdown so the form blocks submit until the
  /// user picks a real option (initial value is the 'Select Account' hint).
  String? validateAccountType(String? value) {
    if (value == null ||
        value.trim().isEmpty ||
        value == 'Select Account') {
      return AppStrings.pleaseSelectAccountType.tr;
    }
    return null;
  }

  Future<void> addAccount() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

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
      if (response.isSuccess) {
        commonSnackBar(message: response.message??AppStrings.bankAddedSuccessfully.tr);
        isLoading.value = false;
        clearForm();
        Get.back();
      }else{
        commonSnackBar(message: response.message??AppStrings.somethingWentWrong);
        isLoading.value = false;
        clearForm();

      }
    } catch (e) {
      commonSnackBar(message: AppStrings.failedToAddAccount.tr);
      isLoading.value = false;
      clearForm();
    }
  }
  void clearForm(){
    bankNameController.clear();
    accountNumberController.clear();
    ifscCodeController.clear();
    bankHolderNameController.clear();
    upiIdController.clear();
    linkedMobileController.clear();
  }

  Future<void> AddUpiApi() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    isLoading.value = true;
    try {
      ResponseModel response = await PaymentRepo().postAddAccount(params:
      {
        ApiKeys.userId: "${userId}",
        ApiKeys.methodType: "UPI",
        ApiKeys.upiDetails: {
          ApiKeys.upiId: upiIdController.text,
          ApiKeys.mobileNumber: linkedMobileController.text.trim(),
        },
        ApiKeys.isDefault:  false
      }
      );
      if (response.isSuccess) {
        commonSnackBar(message: response.message??AppStrings.bankAddedSuccessfully.tr);
        isLoading.value = false;
        clearForm();
        Get.back();
      }else{
        commonSnackBar(message: response.message??AppStrings.somethingWentWrong);
        isLoading.value = false;
        clearForm();
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      isLoading.value = false;
      clearForm();
    } finally {
      isLoading.value = false;
      isLoading.value = false;
      clearForm();
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
