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
      update();
    }
  }
  final upiRegex = RegExp(r'^[\w.\-]{2,256}@[a-zA-Z]{2,64}$');
  String? upiValidate(String? value) {
    if (value == null || value.trim().isEmpty) {
      isUpiValidate.value = false;
      return "Upi Id is required";
    }
    if (upiRegex.hasMatch(value.trim())) {
      isUpiValidate.value = false;
      return "Invalide UPI ID";
    }
    isUpiValidate.value = true;
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
        commonSnackBar(message: response.message??"Bank Added Successfully");
        isLoading.value = false;
        clearForm();
      }else{
        commonSnackBar(message: response.message??AppStrings.somethingWentWrong);
        isLoading.value = false;
        clearForm();

      }
    } catch (e) {
      commonSnackBar(message: "Failed to add account. Please try again.");
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
  }

  Future<void> AddUpiApi() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    isLoading.value = false;
    try {
      ResponseModel response = await PaymentRepo().postAddAccount(params:
      {
        ApiKeys.userId: "${userId}",
        ApiKeys.methodType: "UPI",
        ApiKeys.upiDetails: {
          ApiKeys.upiId: upiIdController.text,
          ApiKeys.bankName:  bankNameController.text
        },
        ApiKeys.isDefault:  false
      }
      );
      if (response.isSuccess) {
        commonSnackBar(message: response.message??"Bank Added Successfully");
        isLoading.value = false;
        clearForm();
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
          'Success',
          addAccountResponseModalClass!.message ?? "",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update account. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }

  }

}
