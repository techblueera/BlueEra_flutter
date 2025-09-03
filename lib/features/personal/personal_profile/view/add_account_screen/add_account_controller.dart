/*
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/model/get_bank_details_model.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/payment_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// class AddAccountController extends GetxController {
//   Rx<ApiResponse> addBankDetailsResponse=ApiResponse.initial("Initial").obs;
//   Rx<ApiResponse> getBankDetailsResponse = ApiResponse.initial("Initial").obs;
//   Rx<ApiResponse> deleteBankBankDetailsResponse = ApiResponse.initial("Initial").obs;

//   RxBool isGetBankDetailsLoading = true.obs;
//   BankDetails? getBankDetails;

//   Future<void> addBankDetailsController({required String channelID}) async {
//     try {

//       var myReq= {
//         "holderName": holderNameController.text,
//         "bankName": bankNameController.text,
//         "accountNumber": accountNumberController.text,
//         "ifscCode": ifscCodeController.text,
//         "accountType": selectedAccount.value?.name
//       };
//       ResponseModel response = await PaymentRepo().bankDetailsRepo(channelId: channelID, params:myReq);

//       if (response.isSuccess && response.response?.data != null) {
//         commonSnackBar(message: response.response?.data['message'] ?? AppStrings.success);
//         addBankDetailsResponse.value = ApiResponse.complete(response);
//         clearForm();
//         Get.back();
//       } else {
//         addBankDetailsResponse.value = ApiResponse.error(response.message ?? "Something went wrong");
//         commonSnackBar(
//             message: response.message ?? AppStrings.somethingWentWrong);
//       }
//     } catch (e) {
//       addBankDetailsResponse.value = ApiResponse.error("Error: $e");
//       commonSnackBar(message: AppStrings.somethingWentWrong);
//     }
//   }

//   Future<void> getBankDetailsController({required String channelID}) async {
//     try {
//       ResponseModel response = await PaymentRepo().getBankDetailsRepo(channelId: channelID);

//       isGetBankDetailsLoading.value = false;

//       if (response.isSuccess && response.response?.data != null) {
//         getBankDetailsResponse.value = ApiResponse.complete(response);
//         GetBankDetailsModel getBankDetailsModel = GetBankDetailsModel.fromJson(response.response?.data);
//         getBankDetails = getBankDetailsModel.data;
//         holderNameController.text = getBankDetails?.holderName??'';
//         bankNameController.text = getBankDetails?.bankName??'';
//         accountNumberController.text = getBankDetails?.accountNumber??'';
//         ifscCodeController.text = getBankDetails?.ifscCode??'';
//         selectedAccount.value =
//         (getBankDetails?.accountType != null)
//             ? AccountTypeExtension.fromString(getBankDetails!.accountType)
//             : BankAccountType.CURRENT;
//       } else {
//         getBankDetailsResponse.value = ApiResponse.error(response.message ?? "Something went wrong");

//       }
//     } catch (e) {
//       isGetBankDetailsLoading.value = false;
//       getBankDetailsResponse.value = ApiResponse.error("Error: $e");
//       commonSnackBar(message: AppStrings.somethingWentWrong);
//     } finally {
//       isGetBankDetailsLoading.value = false;
//     }
//   }

//   Future<void> deleteBankDetailsController({required String channelID}) async {
//     try {

//       ResponseModel response = await PaymentRepo().deleteBankDetailsRepo(channelId: channelID);

//       if (response.isSuccess && response.response?.data != null) {
//         commonSnackBar(
//             message: response.response?.data['message'] ?? AppStrings.success);
//         deleteBankBankDetailsResponse.value = ApiResponse.complete(response);
//         clearForm();
//       } else {
//         deleteBankBankDetailsResponse.value =
//             ApiResponse.error(response.message ?? "Something went wrong");
//         commonSnackBar(
//             message: response.message ?? AppStrings.somethingWentWrong);
//       }
//     } catch (e) {
//       deleteBankBankDetailsResponse.value = ApiResponse.error("Error: $e");
//       commonSnackBar(message: AppStrings.somethingWentWrong);
//     }
//   }

//   final TextEditingController holderNameController = TextEditingController();
//   final TextEditingController bankNameController = TextEditingController();
//   final TextEditingController accountNumberController = TextEditingController();
//   final TextEditingController ifscCodeController = TextEditingController();

//   final GlobalKey<FormState> formKey = GlobalKey<FormState>();

//   RxBool isLoading = false.obs;
//   RxBool isBankNameValid = true.obs;
//   RxBool isAccountNumberValid = true.obs;
//   RxBool isIfscCodeValid = true.obs;
//   Rx<BankAccountType?> selectedAccount = Rx<BankAccountType?>(null);

//   @override
//   void onInit() {
//     super.onInit();
//   }

//   @override
//   void onClose() {
//     bankNameController.dispose();
//     accountNumberController.dispose();
//     ifscCodeController.dispose();
//     super.onClose();
//   }

//   String? validateBankName(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       isBankNameValid.value = false;
//       return 'Bank name is required';
//     }
//     if (value.trim().length < 2) {
//       isBankNameValid.value = false;
//       return 'Bank name must be at least 2 characters';
//     }
//     isBankNameValid.value = true;
//     return null;
//   }

//   String? validateAccountNumber(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       isAccountNumberValid.value = false;
//       return 'Account number is required';
//     }
//     if (value.trim().length < 8) {
//       isAccountNumberValid.value = false;
//       return 'Account number must be at least 8 digits';
//     }
//     if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
//       isAccountNumberValid.value = false;
//       return 'Account number must contain only digits';
//     }
//     isAccountNumberValid.value = true;
//     return null;
//   }

//   String? validateIfscCode(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       isIfscCodeValid.value = false;
//       return 'IFSC code is required';
//     }
//     if (value.trim().length != 11) {
//       isIfscCodeValid.value = false;
//       return 'IFSC code must be 11 characters';
//     }
//     if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value.trim().toUpperCase())) {
//       isIfscCodeValid.value = false;
//       return 'Invalid IFSC code format';
//     }
//     isIfscCodeValid.value = true;
//     return null;
//   }

//   Future<void> addAccount() async {
//     if (!formKey.currentState!.validate()) {
//       return;
//     }

//     isLoading.value = true;

//     try {
//       // Simulate API call
//       await Future.delayed(const Duration(seconds: 2));
      
//       // Here you would typically make an API call to save the account details
//       // For now, we'll just show success and go back
      
//       // Get.back(result: {
//       //   'bankName': bankNameController.text.trim(),
//       //   'accountNumber': accountNumberController.text.trim(),
//       //   'ifscCode': ifscCodeController.text.trim().toUpperCase(),
//       // });
      
//     } catch (e) {
//       Get.snackbar(
//         'Error',
//         'Failed to add account. Please try again.',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

  void clearForm() {
    bankNameController.clear();
    accountNumberController.clear();
    ifscCodeController.clear();
    isBankNameValid.value = true;
    isAccountNumberValid.value = true;
    isIfscCodeValid.value = true;
  }
} */
