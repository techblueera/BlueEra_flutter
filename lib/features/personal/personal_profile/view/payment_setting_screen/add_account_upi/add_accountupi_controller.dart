import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/add_account_screen/add_account_modal.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/repo/payment_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddAccountupiController extends GetxController {
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController upiController = TextEditingController();
  final upiRegex = RegExp(r'^[\w.\-]{2,256}@[a-zA-Z]{2,64}$');
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  AddAccountResponseModalClass? addAccountResponseModalClass;

  RxBool isBankNameValid = true.obs;
  RxBool isUpiValidate = true.obs;
  RxBool isLoading = false.obs;
  RxBool isUpdate = false.obs;
  String upiAccountId = "";

  @override
  void onInit() {
    args();
    super.onInit();
  }

  @override
  void onClose() {
    bankNameController.dispose();
    upiController.dispose();

    super.onClose();
  }

  void args() {
    var data = Get.arguments;
    if (data != null) {
      isUpdate.value = true;
      bankNameController.text = data["BankName"];
      upiController.text = data["UPIId"];
      upiAccountId = data["UPIAccountId"];
      update();
    }
  }

  String? bankValidate(String? value) {
    if (value == null || value.trim().isEmpty) {
      isBankNameValid.value = false;
      return "Bank name is required";
    }
    if (value.trim().length < 2) {
      isBankNameValid.value = false;
      return 'Bank name must be at least 2 characters';
    }
    isBankNameValid.value = true;
    return null;
  }

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

  Future<void> AddUpiApi() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    isLoading.value = false;
    try {
      ResponseModel response = await PaymentRepo().postAddAccount(params: {
        "type": "UPI",
        "bank_name": bankNameController.text,
        "account_number": "",
        "ifsc_code": "",
        "upi_id": upiController.text
      });
      if (response.isSuccess) {
        addAccountResponseModalClass =
            AddAccountResponseModalClass.fromJson(response.response!.data);
        Get.back(result: {
          'bankName': bankNameController.text.trim(),
          'upi_id': upiController.text.trim().toUpperCase(),
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
        'Failed to add account. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }




  Future<void> updateUpiAccount({required String id}) async {
    var body = {
      "type": "UPI",
      "bank_name": bankNameController.text,
      "account_number": "",
      "ifsc_code": "",
      "upi_id": upiController.text,
      "AccountId": upiAccountId
    };
    ResponseModel response =
        await PaymentRepo().updateAccount(Id: id, params: body);
    if (response.isSuccess) {
      addAccountResponseModalClass =
          AddAccountResponseModalClass.fromJson(response.response!.data);
      // Get.to(RouteHelper.)
      Get.back(result: {
        'bankName': bankNameController.text.trim(),
        'upi_id': upiController.text.trim().toUpperCase(),
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
    upiController.clear();
    isBankNameValid.value = true;
  }
}
