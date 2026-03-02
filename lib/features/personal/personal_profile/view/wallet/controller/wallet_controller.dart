import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/wallet_transaction_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/model/wallet_response_modal.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/model/wallet_withdrawal_methods.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/api/apiService/api_response.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/constants/size_config.dart';
import '../../../../../../core/constants/snackbar_helper.dart';
import '../../../../../../widgets/custom_text_cm.dart';
import '../model/upi_details_model.dart';
import '../model/withdrawal_response_modal.dart';
import '../model/bank_details_model.dart';
import '../repo/wallet_repo.dart';

class WalletController extends GetxController {
  Rx<WalletTransactionResponseModalClass> walletTransactionResponseModalClass=WalletTransactionResponseModalClass().obs;
  Rx<ApiResponse> viewWalletBalanceResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> viewTransactionHistoryResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> walletWithdrawalMethodResponse =
      ApiResponse.initial('Initial').obs;

  Rx<WalletResponseModalClass> walletResponseModalClass=WalletResponseModalClass().obs;
  Rx<BankListModel> bankListModel = BankListModel().obs;
  Rx<UpiListModel> upiListModel = UpiListModel().obs;
  // Rx<UpiData> selectedUpiDetails=UpiData().obs;
  // Rx<BankData> selectedBankDetails=BankData().obs;

  String? selectedStatus;
  String? selectedType;
  String? selectedSource;
  final TextEditingController amountController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  WithdrawalResponseModalClass? withdrawalResponseModalClass;
  RxString selectedBank = "Select Payment".obs; // Stores the selected value
  final List<String> bankStatus = ["Bank", "UPI"];
  bool isAmount = true;
  bool paymentMethod = true;
  RxBool isLoading = false.obs;

  ScrollController listScrollController = ScrollController();

  int page = 1;
  bool isMoreDataInList = true;
  bool isLoadingMore = false;

  WalletRepo _walletRepo = WalletRepo();

  var withdrawalMethodDataList = <WithdrawalMethodData>[].obs;
  var bankList = <WithdrawalMethodData>[].obs;
  var upiList = <WithdrawalMethodData>[].obs;
  Rx<WithdrawalMethodData> selectedBankDetails = WithdrawalMethodData().obs;
  Rx<WithdrawalMethodData> selectedUpiDetails = WithdrawalMethodData().obs;

  @override
  void onInit() {
    super.onInit();
    listScrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    listScrollController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (listScrollController.position.pixels >=
        listScrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        isMoreDataInList) {
      page++;
      getWalletTransactionApi(isFromFilter: false);
    }
  }

  Future<void> getWalletApi() async {
    try {
      ResponseModel response = await _walletRepo.getWalletApi();
      if (response.isSuccess) {
        walletResponseModalClass.value =
            WalletResponseModalClass.fromJson(response.response!.data);
        viewWalletBalanceResponse.value=ApiResponse.complete(walletResponseModalClass);
      }else{
        viewWalletBalanceResponse.value=ApiResponse.error(response.message?? AppStrings.somethingWentWrong);
      }
    }catch(e){
      viewWalletBalanceResponse.value=ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> getWalletTransactionApi({bool isFromFilter = true}) async {
    if (isLoadingMore) return;

    if (isFromFilter) {
      page = 1;
      isMoreDataInList = true;
      walletTransactionResponseModalClass.value.data = [];
    }

    isLoadingMore = true;

    ResponseModel response = await _walletRepo.walletTransactionApi(
      source: selectedSource,
      status: selectedStatus,
      type: selectedType,
      page: page,
    );

    if (response.isSuccess) {
      WalletTransactionResponseModalClass value =
      WalletTransactionResponseModalClass.fromJson(
          response.response?.data);

      if (isFromFilter) {
        // First page (replace list)
        walletTransactionResponseModalClass.value = value;
      } else {
        // Next pages (append list)
        walletTransactionResponseModalClass.value.data?.addAll(
          value.data ?? [],
        );

        // Update pagination also
        walletTransactionResponseModalClass.value.pagination =
            value.pagination;
      }

      // Stop calling API when last page reached
      isMoreDataInList = (value.pagination?.page ?? 1) <
          (value.pagination?.totalPages ?? 1);

      viewTransactionHistoryResponse.value =
          ApiResponse.complete(walletTransactionResponseModalClass);
    } else {
      page--; // rollback page if API fails
      viewTransactionHistoryResponse.value =
          ApiResponse.error(response.message ?? "Something went wrong");
    }

    isLoadingMore = false;
  }

  Future<void> getWalletWithdrawalMethodApi() async {
    try {
      walletWithdrawalMethodResponse.value = ApiResponse.initial('Initial');

      ResponseModel response = await _walletRepo.getWalletWithdrawalMethod();

      if (response.isSuccess) {
        var walletWithdrawalMethod = WalletWithdrawalMethod.fromJson(response.response?.data);

        // Update the main list
        withdrawalMethodDataList.value = walletWithdrawalMethod.data ?? [];

        // CLEAR and UPDATE sub-lists based on methodType
        bankList.value = withdrawalMethodDataList.where((element) => element.methodType == "BANK").toList();
        upiList.value = withdrawalMethodDataList.where((element) => element.methodType == "UPI").toList();

        // 3. AUTO-SELECTION LOGIC (New)
        if (bankList.isNotEmpty && upiList.isEmpty) {
          selectedBank.value = "Bank";
        } else if (upiList.isNotEmpty && bankList.isEmpty) {
          selectedBank.value = "UPI";
        } else if (bankList.isNotEmpty && upiList.isNotEmpty) {
          // Optional: Default to Bank if both are available
          selectedBank.value = "Bank";
        }

        walletWithdrawalMethodResponse.value = ApiResponse.complete(walletWithdrawalMethod);
      } else {
        walletWithdrawalMethodResponse.value = ApiResponse.error(response.message);
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      walletWithdrawalMethodResponse.value = ApiResponse.error(e.toString());
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  Future<void> getWalletWithdrawalMethod({required Map<String, dynamic> params}) async {
    try {

      walletWithdrawalMethodResponse.value =
          ApiResponse.initial('Initial');

      ResponseModel response = await _walletRepo.getWalletWithdrawalMethod(params: params);
      walletWithdrawalMethodResponse.value =
          ApiResponse.complete(response.response?.data);
      if (response.isSuccess) {
          if(params[ApiKeys.methodType] == "UPI"){
            upiListModel.value = UpiListModel.fromJson(response.response?.data);
          }else{
            bankListModel.value = BankListModel.fromJson(response.response?.data);

          }
        }
       else{
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        walletWithdrawalMethodResponse.value = ApiResponse.error(response.message?? AppStrings.somethingWentWrong);

      }
    }catch(e){
      commonSnackBar(
          message:  AppStrings.somethingWentWrong);
      walletWithdrawalMethodResponse.value=ApiResponse.error(AppStrings.somethingWentWrong);

    }
  }

  String? amountValidate(String? value) {
    if (value == null || value.trim().isEmpty) {
      isAmount = false;
      return "Amount is required";
    }
    return null;
  }

  String? validatePaymentMethod(String? value) {
    if (value == null || value.trim().isEmpty || value == "Select Payment") {
      paymentMethod = false;
      return "Please select a payment method";
    }
    return null;
  }

  Future<void> WithdrawalApi() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    isLoading.value = false;
    try {
      ResponseModel response = await _walletRepo.addWithdrawApi(params: {
        ApiKeys.amount: amountController.text,
        ApiKeys.withdrawalMethodId: selectedBank.value == "UPI"? selectedUpiDetails.value.id : selectedBankDetails.value.id
      });

      if (response.isSuccess) {
        withdrawalResponseModalClass =
            WithdrawalResponseModalClass.fromJson(response.response!.data);
        showSuccessPopup();
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(
          message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  void showSuccessPopup() {

    bool isWalletInStack = Get.routing.previous == RouteHelper.getWalletScreenRoute();

    Get.dialog(
        UnconstrainedBox(
          child: SizedBox(
            width: Get.width,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                // To display the title it is optional
                title: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppColors.green39,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    CustomText(
                      "Withdrawal Request Sent",
                      fontSize: SizeConfig.extraLarge,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ],
                ),

                content: Column(
                  children: [
                    CustomText(
                      "Your withdrawal request has been submitted successfully. Once approved, the amount will be credited to your payment account.",
                      fontSize: SizeConfig.medium15,
                      textAlign: TextAlign.center,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _navigateToWallet(isWalletInStack),
                            child: Container(
                              height: SizeConfig.size45,
                              decoration: BoxDecoration(
                                  border:
                                  Border.all(color: AppColors.primaryColor),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Center(
                                child: CustomText(
                                  'Go to Wallet',
                                  fontSize: SizeConfig.medium15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: SizeConfig.size10,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _navigateToWallet(isWalletInStack),
                            child: Container(
                              height: SizeConfig.size45,
                              decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  border:
                                  Border.all(color: AppColors.primaryColor),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Center(
                                child: CustomText(
                                  'Got it',
                                  fontSize: SizeConfig.medium15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        barrierDismissible: false);
  }

  void _navigateToWallet(bool isWalletInStack) {
    Get.back(); // Closes the Dialog first
    if (isWalletInStack) {
      // FLOW 1: Pop back to existing Wallet screen and trigger refresh
      Get.back(result: true);
    } else {
      // FLOW 2: Wallet not in stack, push a fresh one and remove the form
      Get.offNamed(RouteHelper.getWalletScreenRoute());
    }
  }
}
