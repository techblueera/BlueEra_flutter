// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/shared_preference_utils.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/features/personal/personal_profile/view/add_account_screen/add_account_screen.dart';
// import 'package:BlueEra/widgets/common_back_app_bar.dart';
// import 'package:BlueEra/widgets/custom_btn.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import 'payment_setting_controller.dart';

// class PaymentSettingScreen extends StatelessWidget {
//   const PaymentSettingScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(PaymentSettingController());

//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: CommonBackAppBar(
//         title: 'Payment Setting',
//         isLeading: true,
//       ),
//       bottomNavigationBar: channelId.isNotEmpty
//           ? SafeArea(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(
//                     horizontal: SizeConfig.size10, vertical: SizeConfig.size30),
//                 child: PositiveCustomBtn(
//                     onTap: () {
//                       Get.to(
//                           AddAccountScreen(
//                             channelId: channelId,
//                             isUpdate: false,
//                       ));
//                     },
//                     title: "Add Bank Details"
//                 ),
//               ),
//             )
//           : null,
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(SizeConfig.size16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // All Bank Accounts Section
//             _buildBankAccountsSection(controller),
//             SizedBox(height: SizeConfig.size24),

//             // UPI ID Section
//             _buildUpiSection(controller),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBankAccountsSection(PaymentSettingController controller) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Section Header
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             CustomText(
//               'All Bank Accounts',
//               fontSize: SizeConfig.large,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//             // _buildAddAccountButton(controller.addBankAccount),
//           ],
//         ),
//         SizedBox(height: SizeConfig.size16),

//         // Bank Accounts List
//         Obx(() => Column(
//               children: controller.bankAccounts
//                   .map((account) => _buildBankAccountCard(account, controller))
//                   .toList(),
//             )),
//       ],
//     );
//   }

//   Widget _buildUpiSection(PaymentSettingController controller) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Section Divider with Title
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: SizeConfig.size30),
//           child: Row(
//             children: [
//               Expanded(child: Divider(color: Colors.black)),
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: SizeConfig.size25),
//                 child: CustomText(
//                   'UPI ID',
//                   fontSize: SizeConfig.medium,
//                   fontWeight: FontWeight.bold,
//                   // color: Colors.grey[600],
//                 ),
//               ),
//               Expanded(child: Divider(color: Colors.black)),
//             ],
//           ),
//         ),
//         SizedBox(height: SizeConfig.size16),
//         // _buildAddAccountButton(controller.addBankAccount,),

//         // UPI Accounts List
//         Obx(() => Column(
//               children: controller.upiAccounts
//                   .map((account) => _buildUpiAccountCard(account, controller))
//                   .toList(),
//             )),
//       ],
//     );
//   }

//   Widget _buildAddAccountButton(VoidCallback onTap, bool isbank) {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.primaryColor,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(8),
//           child: Padding(
//             padding: EdgeInsets.symmetric(
//               horizontal: SizeConfig.size12,
//               vertical: SizeConfig.size8,
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CustomText(
//                   'Add Account',
//                   fontSize: SizeConfig.small,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.white,
//                 ),
//                 SizedBox(width: SizeConfig.size4),
//                 Icon(
//                   Icons.keyboard_arrow_down,
//                   color: Colors.white,
//                   size: 16,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBankAccountCard(
//       BankAccount account, PaymentSettingController controller) {
//     return Container(
//       margin: EdgeInsets.only(bottom: SizeConfig.size12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(SizeConfig.size16),
//         child: Row(
//           children: [
//             // Bank Icon
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: _getBankColor(account.iconColor),
//                 shape: BoxShape.circle,
//               ),
//               child: Center(
//                 child: CustomText(
//                   _getBankInitial(account.bankName),
//                   fontSize: SizeConfig.medium,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//             SizedBox(width: SizeConfig.size12),

//             // Bank Details
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       CustomText(
//                         account.bankName,
//                         fontSize: SizeConfig.medium,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                       if (account.isDefault) ...[
//                         SizedBox(width: SizeConfig.size8),
//                         CustomText(
//                           '(Default)',
//                           fontSize: SizeConfig.small,
//                           fontWeight: FontWeight.w400,
//                           color: Colors.grey[600],
//                         ),
//                       ],
//                     ],
//                   ),
//                   SizedBox(height: SizeConfig.size4),
//                   Row(
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           CustomText(
//                             'Account No.',
//                             fontSize: SizeConfig.small,
//                             color: Colors.grey[600],
//                           ),
//                           CustomText(
//                             account.accountNumber,
//                             fontSize: SizeConfig.small,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.black87,
//                           ),
//                         ],
//                       ),
//                       SizedBox(width: SizeConfig.size24),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           CustomText(
//                             'IFSC Code',
//                             fontSize: SizeConfig.small,
//                             color: Colors.grey[600],
//                           ),
//                           CustomText(
//                             account.ifscCode,
//                             fontSize: SizeConfig.small,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.black87,
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             // Action Buttons
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _buildActionButton(
//                   icon: Icons.delete,
//                   color: Colors.red,
//                   onTap: () => controller.deleteBankAccount(account.id),
//                 ),
//                 SizedBox(width: SizeConfig.size8),
//                 _buildActionButton(
//                   icon: Icons.edit,
//                   color: AppColors.primaryColor,
//                   // onTap: () => controller.editBankAccount(account.id),
//                   onTap: () => Get.to(
//                       AddAccountScreen(
//                         channelId: channelId,
//                         isUpdate: true,
//                       )),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildUpiAccountCard(
//       UpiAccount account, PaymentSettingController controller) {
//     return Container(
//       margin: EdgeInsets.only(bottom: SizeConfig.size12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(SizeConfig.size16),
//         child: Row(
//           children: [
//             // Bank Icon
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: Colors.orange,
//                 shape: BoxShape.circle,
//               ),
//               child: Center(
//                 child: CustomText(
//                   _getBankInitial(account.bankName),
//                   fontSize: SizeConfig.medium,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//             SizedBox(width: SizeConfig.size12),

//             // Bank Details
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   CustomText(
//                     account.bankName,
//                     fontSize: SizeConfig.medium,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                   SizedBox(height: SizeConfig.size4),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       CustomText(
//                         'UPI ID',
//                         fontSize: SizeConfig.small,
//                         color: Colors.grey[600],
//                       ),
//                       CustomText(
//                         account.upiId,
//                         fontSize: SizeConfig.small,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.black87,
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             // Action Buttons
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _buildActionButton(
//                   icon: Icons.delete,
//                   color: Colors.red,
//                   onTap: () => controller.deleteUpiAccount(account.id),
//                 ),
//                 SizedBox(width: SizeConfig.size8),
//                 _buildActionButton(
//                   icon: Icons.edit,
//                   color: AppColors.primaryColor,
//                   onTap: () => controller.editUpiAccount(account.id),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       width: 32,
//       height: 32,
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         shape: BoxShape.circle,
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(16),
//           child: Center(
//             child: Icon(
//               icon,
//               size: 16,
//               color: color,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getBankColor(String colorHex) {
//     switch (colorHex) {
//       case '#2196F3':
//         return Colors.blue;
//       case '#F44336':
//         return Colors.red;
//       case '#FF5722':
//         return Colors.deepOrange;
//       default:
//         return Colors.grey;
//     }
//   }

//   String _getBankInitial(String bankName) {
//     if (bankName.contains('State Bank')) return 'S';
//     if (bankName.contains('ICICI')) return 'I';
//     if (bankName.contains('HDFC')) return 'H';
//     if (bankName.contains('Panjab')) return 'P';
//     return bankName.isNotEmpty ? bankName[0] : 'B';
//   }
// }
