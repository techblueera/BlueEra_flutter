// import 'package:BlueEra/core/api/apiService/api_response.dart';
// import 'package:BlueEra/core/api/apiService/response_model.dart';
// import 'package:BlueEra/core/constants/app_strings.dart';
// import 'package:BlueEra/core/constants/snackbar_helper.dart';
// import 'package:BlueEra/features/personal/model/get_bank_details_model.dart';
// import 'package:BlueEra/features/personal/personal_profile/repo/payment_repo.dart';
// import 'package:get/get.dart';

// class BankAccount {
//   final String id;
//   final String bankName;
//   final String accountNumber;
//   final String ifscCode;
//   final bool isDefault;
//   final String iconColor;

//   BankAccount({
//     required this.id,
//     required this.bankName,
//     required this.accountNumber,
//     required this.ifscCode,
//     this.isDefault = false,
//     required this.iconColor,
//   });
// }

// class UpiAccount {
//   final String id;
//   final String bankName;
//   final String upiId;

//   UpiAccount({
//     required this.id,
//     required this.bankName,
//     required this.upiId,
//   });
// }

// class PaymentSettingController extends GetxController {
//   RxList<BankAccount> bankAccounts = <BankAccount>[].obs;
//   RxList<UpiAccount> upiAccounts = <UpiAccount>[].obs;

//   Rx<ApiResponse> getBankDetailsResponse = ApiResponse.initial("Initial").obs;
//   Rx<ApiResponse> deleteBankBankDetailsResponse =
//       ApiResponse.initial("Initial").obs;

//   RxBool isGetBankDetailsLoading = true.obs;
//   BankDetails? getBankDetails;

//   @override
//   void onInit() {
//     super.onInit();
//     loadDummyData();
//   }

//   void loadDummyData() {
//     // Add dummy bank accounts
//     bankAccounts.addAll([
//       BankAccount(
//         id: '1',
//         bankName: 'State Bank Of India',
//         accountNumber: '1234567894',
//         ifscCode: 'SBI7878DG',
//         isDefault: true,
//         iconColor: '#2196F3', // Blue
//       ),
//       BankAccount(
//         id: '2',
//         bankName: 'ICICI Bank',
//         accountNumber: '1234567894',
//         ifscCode: 'ICICI7878DG',
//         iconColor: '#F44336', // Red
//       ),
//       BankAccount(
//         id: '3',
//         bankName: 'HDFC Bank',
//         accountNumber: '1234567894',
//         ifscCode: 'HDFC7878DG',
//         iconColor: '#FF5722', // Deep Orange
//       ),
//     ]);

//     // Add dummy UPI accounts
//     upiAccounts.addAll([
//       UpiAccount(
//         id: '1',
//         bankName: 'Panjab Bank',
//         upiId: '1234567894',
//       ),
//     ]);
//   }

//   void deleteBankAccount(String id) {
//     bankAccounts.removeWhere((account) => account.id == id);
//   }

//   void deleteUpiAccount(String id) {
//     upiAccounts.removeWhere((account) => account.id == id);
//   }

//   void editBankAccount(String id) {
//     // TODO: Implement edit functionality
//     print('Edit bank account: $id');
//   }

//   void editUpiAccount(String id) {
//     // TODO: Implement edit functionality
//     print('Edit UPI account: $id');
//   }

//   // void addBankAccount() {
//   //   Get.to(()=>AddAccountScreen());
//   //   // TODO: Implement add bank account functionality
//   //   print('Add bank account');
//   // }

//   void addUpiAccount() {
//     // TODO: Implement add UPI account functionality
//     print('Add UPI account');
//   }

//   Future<void> getBankDetailsController({required String channelID}) async {
//     try {
//       ResponseModel response =
//           await PaymentRepo().getBankDetailsRepo(channelId: channelID);

//       isGetBankDetailsLoading.value = false;

//       if (response.isSuccess && response.response?.data != null) {
//         getBankDetailsResponse.value = ApiResponse.complete(response);
//         GetBankDetailsModel getBankDetailsModel =
//             GetBankDetailsModel.fromJson(response.response?.data);
//         getBankDetails = getBankDetailsModel.data;
//       } else {
//         getBankDetailsResponse.value =
//             ApiResponse.error(response.message ?? "Something went wrong");
//       }
//     } catch (e) {
//       isGetBankDetailsLoading.value = false;
//       getBankDetailsResponse.value = ApiResponse.error("Error: $e");
//       commonSnackBar(message: AppStrings.somethingWentWrong);
//     } finally {
//       isGetBankDetailsLoading.value = false;
//     }
//   }

//   Future<void> deleteBankDetailsController(
//       {required String channelID, required String id}) async {
//     try {
//       ResponseModel response =
//           await PaymentRepo().deleteBankDetailsRepo(channelId: channelID);

//       if (response.isSuccess && response.response?.data != null) {
//         commonSnackBar(
//             message: response.response?.data['message'] ?? AppStrings.success);
//         deleteBankBankDetailsResponse.value = ApiResponse.complete(response);
//         upiAccounts.removeWhere((account) => account.id == id);
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
// }
