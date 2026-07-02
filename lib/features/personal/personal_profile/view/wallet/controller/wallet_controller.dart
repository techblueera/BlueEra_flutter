import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/utils/fetch_cache.dart';
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
  // See-All list (supports status/type filters + pagination).
  Rx<WalletTransactionResponseModalClass> walletTransactionResponseModalClass=WalletTransactionResponseModalClass().obs;

  // Home preview list — ALWAYS unfiltered and kept separate from the See-All
  // list, so filtering on See-All never changes what the wallet home shows.
  Rx<WalletTransactionResponseModalClass> previewTransactionResponseModalClass =
      WalletTransactionResponseModalClass().obs;
  Rx<ApiResponse> previewTransactionResponse =
      ApiResponse.initial('Initial').obs;
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

  /// Mirror of [amountController]'s text as a reactive value so the Withdraw
  /// button's enabled state can recompute as the user types (a plain
  /// TextEditingController isn't observable on its own).
  RxString enteredAmount = ''.obs;

  /// True only when a positive amount within the available balance is entered.
  bool get isAmountWithinBalance {
    final amount = double.tryParse(enteredAmount.value.trim());
    if (amount == null || amount <= 0) return false;
    final available =
        (walletResponseModalClass.value.data?.withdrawableAmount ?? 0).toDouble();
    return amount <= available;
  }

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

  /// Freshness guard for the balance GET. The drawer prefetches the wallet on
  /// open and WalletScreen fetches again in initState — back-to-back when the
  /// wallet is opened from the drawer. This dedupes those on-entry calls while
  /// still allowing explicit refreshes (e.g. after a withdrawal).
  final FetchCache _walletCache = FetchCache(ttl: const Duration(seconds: 45));

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

  /// On-entry fetch that skips the network call when the balance is already
  /// loaded and fresh (within the cache TTL). Use this from screen `initState`
  /// / drawer open; use [getWalletApi] directly to force a refresh.
  Future<void> getWalletApiIfNeeded() async {
    if (_walletCache.isFresh(
      'wallet',
      hasData: viewWalletBalanceResponse.value.status == Status.COMPLETE,
    )) {
      return;
    }
    await getWalletApi();
  }

  Future<void> getWalletApi() async {
    try {
      ResponseModel response = await _walletRepo.getWalletApi();
      if (response.isSuccess) {
        walletResponseModalClass.value =
            WalletResponseModalClass.fromJson(response.response!.data);
        viewWalletBalanceResponse.value=ApiResponse.complete(walletResponseModalClass);
        _walletCache.mark('wallet');
      }else{
        viewWalletBalanceResponse.value=ApiResponse.error(response.message?? AppStrings.somethingWentWrong);
      }
    }catch(e){
      viewWalletBalanceResponse.value=ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  // Only valid query values the transactions API accepts. Anything else (e.g. a
  // legacy "SUCCESSFUL"/"FAILED" left in a shared controller) is dropped so it
  // never hits the API.
  static const _allowedStatuses = {"PENDING", "COMPLETED", "REJECTED"};
  static const _allowedTypes = {"CREDIT", "DEBIT"};

  /// Clears any active transaction filters. The wallet home preview calls this
  /// so it always shows the full, unfiltered list — the See-All screen shares
  /// this controller and may have left a status/type filter set.
  void resetTransactionFilters() {
    selectedStatus = null;
    selectedType = null;
    selectedSource = null;
  }

  /// Fetches the latest transactions for the wallet home preview — always
  /// unfiltered (no status/type/source) and independent of the See-All list.
  Future<void> getPreviewTransactionApi() async {
    try {
      previewTransactionResponse.value = ApiResponse.loading();
      ResponseModel response = await _walletRepo.walletTransactionApi(
        page: 1,
        limit: 10,
      );
      if (response.isSuccess) {
        previewTransactionResponseModalClass.value =
            WalletTransactionResponseModalClass.fromJson(response.response?.data);
        previewTransactionResponse.value =
            ApiResponse.complete(previewTransactionResponseModalClass);
      } else {
        previewTransactionResponse.value =
            ApiResponse.error(response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      previewTransactionResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  Future<void> getWalletTransactionApi({bool isFromFilter = true}) async {
    // Only block concurrent PAGINATION loads. A filter/refresh must always go
    // through, otherwise an in-flight page load swallows the new filter call.
    if (!isFromFilter && isLoadingMore) return;

    // Sanitize the filters: keep only recognised values and clear the rest so a
    // stale value can't be sent and the UI highlight stays in sync.
    if (selectedStatus != null && !_allowedStatuses.contains(selectedStatus)) {
      selectedStatus = null;
    }
    if (selectedType != null && !_allowedTypes.contains(selectedType)) {
      selectedType = null;
    }

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

        // 4. PRE-SELECT the user's default method (falls back to the first item
        // of each list) so the Withdraw flow starts with a destination chosen.
        if (bankList.isNotEmpty) {
          selectedBankDetails.value = bankList.firstWhere(
            (e) => e.isDefault == true,
            orElse: () => bankList.first,
          );
        }
        if (upiList.isNotEmpty) {
          selectedUpiDetails.value = upiList.firstWhere(
            (e) => e.isDefault == true,
            orElse: () => upiList.first,
          );
        }

        // Open on the tab that owns the default method when both types exist.
        if (bankList.isNotEmpty && upiList.isNotEmpty) {
          WithdrawalMethodData? defaultMethod;
          for (final e in withdrawalMethodDataList) {
            if (e.isDefault == true) {
              defaultMethod = e;
              break;
            }
          }
          if (defaultMethod?.methodType == "UPI") {
            selectedBank.value = "UPI";
          } else if (defaultMethod?.methodType == "BANK") {
            selectedBank.value = "Bank";
          }
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

  /// True while both BANK + UPI withdrawal methods are being fetched together
  /// (the per-call `walletWithdrawalMethodResponse` status gets overwritten by
  /// the second call, so the payment-settings screen uses this flag instead).
  RxBool isMethodsLoading = false.obs;

  /// Fetches BOTH bank accounts and UPI IDs so the payment-settings screen can
  /// list every saved withdrawal method.
  ///
  /// [showLoader] drives the full-screen spinner — `true` for the initial load,
  /// `false` for the silent re-fetch after an edit/delete/set-default so the
  /// list updates in place without blanking the whole screen.
  Future<void> getAllWithdrawalMethods({bool showLoader = true}) async {
    if (showLoader) isMethodsLoading.value = true;
    await getWalletWithdrawalMethod(params: {ApiKeys.methodType: "BANK"});
    await getWalletWithdrawalMethod(params: {ApiKeys.methodType: "UPI"});
    if (showLoader) isMethodsLoading.value = false;
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

  // ── Withdrawal method actions (delete / edit / set-default) ──────────────

  /// Delete a saved bank/UPI withdrawal method, then refresh the list.
  Future<void> deleteWithdrawalMethod(String id) async {
    try {
      final ResponseModel response =
          await _walletRepo.deleteWithdrawalMethod(id: id);
      if (response.isSuccess) {
        commonSnackBar(
            message: response.message ?? "Method removed successfully.");
        await getAllWithdrawalMethods(showLoader: false);
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  /// Edit an existing UPI method.
  Future<void> updateUpiMethod({
    required String id,
    required String upiId,
    required String mobileNumber,
  }) {
    return _updateWithdrawalMethod(id, {
      ApiKeys.upiDetails: {
        ApiKeys.upiId: upiId.trim(),
        ApiKeys.mobileNumber: mobileNumber.trim(),
      }
    });
  }

  /// Edit an existing bank method.
  Future<void> updateBankMethod({
    required String id,
    required String holderName,
    required String accountNo,
    required String ifscCode,
    required String bankName,
  }) {
    return _updateWithdrawalMethod(id, {
      ApiKeys.bankDetails: {
        ApiKeys.holderName: holderName.trim(),
        ApiKeys.accountNo: accountNo.trim(),
        ApiKeys.ifscCode: ifscCode.trim(),
        ApiKeys.bankName: bankName.trim(),
      }
    });
  }

  /// Mark a method as the default payout destination via the dedicated
  /// PATCH …/withdrawal-methods/set-default/{id} endpoint.
  Future<void> setDefaultWithdrawalMethod(String id) async {
    try {
      final ResponseModel response =
          await _walletRepo.setDefaultWithdrawalMethod(id: id);
      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? "Set as default");
        await getAllWithdrawalMethods(showLoader: false);
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  /// Shared PUT handler for edits; refreshes the list silently on success.
  Future<void> _updateWithdrawalMethod(
    String id,
    Map<String, dynamic> params, {
    String? successMessage,
  }) async {
    try {
      final ResponseModel response =
          await _walletRepo.updateWithdrawalMethod(id: id, params: params);
      if (response.isSuccess) {
        commonSnackBar(
            message: successMessage ??
                response.message ??
                "Updated successfully");
        await getAllWithdrawalMethods(showLoader: false);
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }

  String? amountValidate(String? value) {
    if (value == null || value.trim().isEmpty) {
      isAmount = false;
      return "Amount is required";
    }
    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return "Enter a valid amount";
    }
    if (amount <= 0) {
      return "Amount must be greater than 0";
    }
    // Can't withdraw more than the available (withdrawable) balance.
    final available =
        (walletResponseModalClass.value.data?.withdrawableAmount ?? 0).toDouble();
    if (amount > available) {
      return "Amount can't exceed available balance (₹${available.toStringAsFixed(2)})";
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
