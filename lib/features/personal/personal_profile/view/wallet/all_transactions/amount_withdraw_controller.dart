import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/add_account_screen/add_account_modal.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/repo/payment_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/all_transactions/withdrawal_response_modal.dart';
import 'package:BlueEra/features/personal/personal_profile/view/wallet/wallet_Repo/wallet_repo.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AmountWithdrawScreenController extends GetxController {
  final TextEditingController amountController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  WithdrawalResponseModalClass? withdrawalResponseModalClass;
  String? selectedBank = "Select Payment"; // Stores the selected value
  final List<String> bankStatus = ["Bank Account", "UPI Account"];
  bool isAmount = true;
  bool paymentMethod = true;
  bool isLoading = false;

  @override
  void onInit() {
    // args();
    super.onInit();
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
    isLoading = false;
    try {
      ResponseModel response = await WalletRepo().addWithdrawApi(params: {
        "amount": amountController.text,
        "type": selectedBank == "Bank Account" ? "BANK" : "UPI"
      });

      if (response.isSuccess) {
        withdrawalResponseModalClass =
            WithdrawalResponseModalClass.fromJson(response.response!.data);
        showSuccessPopup();
      } else {
        Get.snackbar(
          'Error',
          response.message.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to withdraw. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading = false;
    }
  }

  void showSuccessPopup() {
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
                      "Your withdrawal request has been submitted successfully. Once approved, the amount will be credited to your bank account.",
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
                            onTap: () {
                              Get.back();
                              Get.back();
                            },
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
                            onTap: () {
                              Get.back();
                              Get.back();
                            },
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
}
