import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/add_account_screen/add_account_modal.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/repo/payment_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddAccountController extends GetxController {
  final TextEditingController bankHolderNameController =
      TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController ifscCodeController = TextEditingController();
  AddAccountResponseModalClass? addAccountResponseModalClass;
  final nameRegExp = RegExp(r'^[a-zA-Z\s]+$');

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  RxBool isLoading = false.obs;
  RxBool isupdate = false.obs;
  RxBool isBankNameValid = true.obs;
  RxBool isBankHolderNAme = true.obs;
  RxBool isAccountNumberValid = true.obs;
  RxBool isIfscCodeValid = true.obs;
  String accountId = "";
  bool isDefault = false;

  String? selectedBank = "Select Bank"; // Stores the selected value
  final List<String> bankStatus = [
    "Current",
    "Saving",
  ];

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
      selectedBank = data['accountType'].toString().capitalizeFirst;
      update();
    }
  }

  String? validateBankHolderName(String? value) {
    if (value == null || value.trim().isEmpty) {
      isBankHolderNAme.value = false;
      return 'Enter Bank Holder name';
    }
    if (!nameRegExp.hasMatch(value.trim())) {
      return 'Name should only Alphabetically';
    }
    isBankHolderNAme.value = true;
    return null;
  }

  String? validateBankName(String? value) {
    if (value == null || value.trim().isEmpty) {
      isBankNameValid.value = false;
      return 'Bank name is required';
    }
    if (value.trim().length < 2) {
      isBankNameValid.value = false;
      return 'Bank name must be at least 2 characters';
    }
    isBankNameValid.value = true;
    return null;
  }

  String? validateAccountNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      isAccountNumberValid.value = false;
      return 'Account number is required';
    }
    if (value.trim().length < 8) {
      isAccountNumberValid.value = false;
      return 'Account number must be at least 8 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
      isAccountNumberValid.value = false;
      return 'Account number must contain only digits';
    }
    isAccountNumberValid.value = true;
    return null;
  }

  String? validateIfscCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      isIfscCodeValid.value = false;
      return 'IFSC code is required';
    }
    if (value.trim().length != 11) {
      isIfscCodeValid.value = false;
      return 'IFSC code must be 11 characters';
    }
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$')
        .hasMatch(value.trim().toUpperCase())) {
      isIfscCodeValid.value = false;
      return 'Invalid IFSC code format';
    }
    isIfscCodeValid.value = true;
    return null;
  }

  Future<void> addAccount() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      ResponseModel response = await PaymentRepo().postAddAccount(params: {
        "type": "BANK",
        "bank_name": bankNameController.text,
        "account_holder_name": bankHolderNameController.text,
        "account_number": accountNumberController.text,
        "ifsc_code": ifscCodeController.text,
        "account_type": selectedBank!.toLowerCase(),
        "upi_id": "",
        "isDefault": isDefault,
      });
      if (response.isSuccess) {
        addAccountResponseModalClass =
            AddAccountResponseModalClass.fromJson(response.response!.data);
        Get.back(result: {
          'bankName': bankNameController.text.trim(),
          'accountNumber': accountNumberController.text.trim(),
          'ifscCode': ifscCodeController.text.trim().toUpperCase(),
        });
        Get.snackbar(
          'Success',
          addAccountResponseModalClass!.message ?? "",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }

      // Here you would typically make an API call to save the account details
      // For now, we'll just show success and go back
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add account. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

// Api calling for update Add BankAccount
  Future<void> updateAccount() async {
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
      "account_type": selectedBank!.toLowerCase(),
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
        'Success',
        addAccountResponseModalClass!.message ?? "",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  void clearForm() {
    bankNameController.clear();
    accountNumberController.clear();
    ifscCodeController.clear();
    isBankNameValid.value = true;
    isAccountNumberValid.value = true;
    isIfscCodeValid.value = true;
  }
}
