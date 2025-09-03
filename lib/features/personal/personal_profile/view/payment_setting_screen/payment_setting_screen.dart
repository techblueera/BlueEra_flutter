import 'dart:math';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/payment_setting_screen/add_account_screen/get_account_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'payment_setting_controller.dart';

class PaymentSettingScreen extends StatelessWidget {
  const PaymentSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final controller = Get.put(PaymentSettingController());
    return GetBuilder<PaymentSettingController>(
        init: PaymentSettingController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: CommonBackAppBar(
              title: 'Payment Setting',
              isLeading: true,
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(SizeConfig.size16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // All Bank Accounts Section
                  _buildBankAccountsSection(controller),
                  SizedBox(height: SizeConfig.size24),

                  // UPI ID Section
                  _buildUpiSection(controller),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildBankAccountsSection(PaymentSettingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              'All Bank Accounts',
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            _buildAddAccountButton(true, controller),
          ],
        ),
        SizedBox(height: SizeConfig.size16),

        // Bank Accounts List
        // Obx(() =>
        Column(
          children: controller.getAccountResponseModalClass != null
              ? controller.getAccountResponseModalClass!.data!
                  .where((e) => e.type == "BANK")
                  .map((account) => _buildBankAccountCard(account, controller))
                  .toList()
              : [SizedBox()],
        )
        // ),
      ],
    );
  }

  Widget _buildUpiSection(PaymentSettingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Divider with Title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Expanded(child: Divider(color: Colors.black)),
              CustomText(
                'UPI ID',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.bold,
                // color: Colors.grey[600],
              ),
              _buildAddUpiButton(true, controller)
              // Expanded(child: Divider(color: Colors.black)),
            ],
          ),
        ),
        SizedBox(height: SizeConfig.size16),

        // UPI Accounts List
        // Obx(() =>
        Column(
          children: controller.getAccountResponseModalClass != null
              ? controller.getAccountResponseModalClass!.data!
                  .where((e) => e.type == "UPI")
                  .map((account) => _buildUpiAccountCard(account, controller))
                  .toList()
              : [SizedBox()],
        )
        // ),
      ],
    );
  }

  Widget _buildAddAccountButton(
      bool isbank, PaymentSettingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            controller.addBankAccount();
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12,
              vertical: SizeConfig.size8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  'Add Account',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                SizedBox(width: SizeConfig.size4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddUpiButton(bool isbank, PaymentSettingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            controller.addUpiAccount();
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12,
              vertical: SizeConfig.size8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  'Add UPI',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                SizedBox(width: SizeConfig.size4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankAccountCard(DatumGetAccountResponseModalClass account,
      PaymentSettingController controller) {
    return InkWell(
      onTap: () {
        Get.dialog(
            UnconstrainedBox(
              child: SizedBox(
                width: Get.width,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AlertDialog(
                    // To display the title it is optional
                    title: CustomText(
                      "Deafult Bank Account",
                      fontSize: SizeConfig.extraLarge,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),

                    content: CustomText(
                      "Do you want to set this account as default",
                      fontSize: SizeConfig.medium15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    // Text("Do you want to set this account as default"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          // Navigator.of(context).pop();
                          Get.back();
                        },
                        child: CustomText(
                          "CANCLE",
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                        // Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () => controller.setAccountAsDefault(
                            id: account.id ?? ""),
                        child: CustomText(
                          "YES",
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                        //  Text('Yes'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            barrierDismissible: false);
    
      },
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: Row(
            children: [
              // Bank Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color((Random().nextDouble() * 0xFFFFFF).toInt())
                      .withOpacity(1.0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomText(
                    _getBankInitial(account.bankName ?? ""),
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.size12),

              // Bank Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomText(
                          account.bankName,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        if (account.isDefault == true) ...[
                          SizedBox(width: SizeConfig.size8),
                          CustomText(
                            '(Default)',
                            fontSize: SizeConfig.size12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: SizeConfig.size4),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              'Account No.',
                              fontSize: SizeConfig.small,
                              color: Colors.grey[600],
                            ),
                            CustomText(
                              account.accountNumber,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                        SizedBox(width: SizeConfig.size18),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              'IFSC Code',
                              fontSize: SizeConfig.small,
                              color: Colors.grey[600],
                            ),
                            CustomText(
                              account.ifscCode,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    icon: Icons.delete,
                    color: Colors.red,
                    onTap: () => controller.deleteBankAccount(account.id ?? ""),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  _buildActionButton(
                    icon: Icons.edit,
                    color: AppColors.primaryColor,
                    // onTap: () => controller.editBankAccount(account.id ?? ""),
                    onTap: () {
                      Get.toNamed(RouteHelper.getAddAccountScreenRoute(),
                          arguments: {
                            "BankName": account.bankName ?? "",
                            "Account": account.accountNumber,
                            "IfscCode": account.ifscCode ?? "",
                            "AccountId": account.id,
                            "accountHolderName": account.accountHolderName,
                            "isDefault": account.isDefault,
                            "accountType": account.accountType
                          })?.then((_) {
                        controller.getAccountApi();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpiAccountCard(DatumGetAccountResponseModalClass account,
      PaymentSettingController controller) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size16),
        child: Row(
          children: [
            // Bank Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomText(
                  _getBankInitial(account.bankName ?? ""),
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: SizeConfig.size12),

            // Bank Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    account.bankName,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  SizedBox(height: SizeConfig.size4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'UPI ID',
                        fontSize: SizeConfig.small,
                        color: Colors.grey[600],
                      ),
                      CustomText(
                        account.upiId,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: Icons.delete,
                  color: Colors.red,
                  onTap: () => controller.deleteUpiAccount(account.id ?? ""),
                ),
                SizedBox(width: SizeConfig.size8),
                _buildActionButton(
                  icon: Icons.edit,
                  color: AppColors.primaryColor,
                  // onTap: () => controller.editUpiAccount(account.id ?? ""),
                  onTap: () {
                    Get.toNamed(RouteHelper.getAddAccountUpiScreenRoute(),
                        arguments: {
                          "BankName": account.bankName,
                          "UPIId": account.upiId,
                          "UPIAccountId": account.id
                        })?.then((_) {
                      controller.getAccountApi();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
        ),
      ),
    );
  }


  String _getBankInitial(String bankName) {
    if (bankName.contains('State Bank')) return 'S';
    if (bankName.contains('ICICI')) return 'I';
    if (bankName.contains('HDFC')) return 'H';
    if (bankName.contains('Panjab')) return 'P';
    return bankName.isNotEmpty ? bankName[0] : 'B';
  }
}
