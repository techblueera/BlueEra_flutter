import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/model/add_account_modal.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment/repo/payment_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddBankAccountController extends GetxController {
  final TextEditingController bankHolderNameController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController ifscCodeController = TextEditingController();
  AddAccountResponseModalClass? addAccountResponseModalClass;


  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  RxBool isLoading = false.obs;
  RxBool isupdate = false.obs;
  String accountId = "";
  RxBool isDefault = false.obs;

  final Rx<BankAccountType?> selectedBankAccountType = Rx<BankAccountType?>(null);


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
      selectedBankAccountType.value = BankAccountTypeExtension.fromString(data['accountType'].toString());
      update();
    }
  }

  Future<void> addAccount() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if(selectedBankAccountType.value == null){
      commonSnackBar(message: "Please select Bank Account Type.");
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
        "account_type": selectedBankAccountType.value?.displayName,
        "upi_id": "",
        "isDefault": isDefault.value,
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
    if (!formKey.currentState!.validate()) {
      return;
    }

    if(selectedBankAccountType.value == null){
      commonSnackBar(message: "Please select Bank Account Type.");
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
        "account_type": selectedBankAccountType.value?.displayName,
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

  void clearForm() {
    bankNameController.clear();
    accountNumberController.clear();
    ifscCodeController.clear();
    selectedBankAccountType.value = null;
  }
}
