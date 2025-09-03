// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_enum.dart';
// import 'package:BlueEra/core/constants/regular_expression.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/widgets/commom_textfield.dart';
// import 'package:BlueEra/widgets/common_back_app_bar.dart';
// import 'package:BlueEra/widgets/common_card_widget.dart';
// import 'package:BlueEra/widgets/common_drop_down.dart';
// import 'package:BlueEra/widgets/custom_btn.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';

// import 'add_account_controller.dart';

// class AddAccountScreen extends StatefulWidget {
//   final String channelId;
//   final bool isUpdate;

//   const AddAccountScreen({super.key, required this.channelId, required this.isUpdate});

//   @override
//   State<AddAccountScreen> createState() => _AddAccountScreenState();
// }

// class _AddAccountScreenState extends State<AddAccountScreen> {
//   final controller = Get.put(AddAccountController());
//   bool validate = false;

//   @override
//   void initState() {
//     if(widget.isUpdate) {
//       controller.getBankDetailsController(channelID: widget.channelId);
//     }
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CommonBackAppBar(
//         title: (widget.isUpdate) ? 'Add Bank Account' : 'Edit Bank Account',
//       ),
//       body: Obx(() {
//         return controller.isGetBankDetailsLoading.isFalse ? SingleChildScrollView(
//           child: Padding(
//             padding: EdgeInsets.all(SizeConfig.size16),
//             child: CommonCardWidget(
//               child: Form(
//                 key: controller.formKey,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Form Container
//                     CommonTextField(
//                       title: 'Account Holder Name',
//                       textEditController: controller.holderNameController,
//                       hintText: 'E.g. Sumit',
//                       keyBoardType: TextInputType.text,
//                       validator: controller.validateBankName,
//                       regularExpression:RegularExpressionUtils.alphabetPatternSpace ,
//                       inputFormatters: [
//                         LengthLimitingTextInputFormatter(24),
//                       ],
//                       onChange: (val) {
//                         isFormValid();
//                       },
//                     ),
//                     SizedBox(height: SizeConfig.size16),
          
//                     CommonTextField(
//                       title: 'Bank Name',
//                       regularExpression:RegularExpressionUtils.alphabetPatternSpace ,
          
//                       textEditController: controller.bankNameController,
//                       hintText: 'E.g. State Bank Of India',
//                       keyBoardType: TextInputType.text,
//                       validator: controller.validateBankName,
//                       inputFormatters: [
          
//                         LengthLimitingTextInputFormatter(24),
//                       ],
//                       onChange: (val) {
//                         isFormValid();
//                       },
//                     ),
//                     SizedBox(height: SizeConfig.size16),
          
//                     CommonTextField(
//                       title: 'Account Number',
//                       textEditController: controller.accountNumberController,
//                       hintText: 'E.g. 1234567890',
//                       keyBoardType: TextInputType.number,
//                       inputFormatters: [
//                         FilteringTextInputFormatter.digitsOnly,
//                         LengthLimitingTextInputFormatter(16),
//                       ],
//                       validator: controller.validateAccountNumber,
//                       onChange: (val) {
//                         isFormValid();
//                       },
//                       // borderRadius: SizeConfig.size8,
//                     ),
//                     SizedBox(height: SizeConfig.size16),
          
//                     // IFSC Code Field
          
//                     CommonTextField(
//                       title: 'IFSC code',
//                       textEditController: controller.ifscCodeController,
//                       hintText: 'E.g. SB17878DG',
//                       keyBoardType: TextInputType.text,
//                       validator: controller.validateIfscCode,
//                       inputFormatters: [
//                         LengthLimitingTextInputFormatter(11),
//                       ],
//                       onChange: (val) {
//                         isFormValid();
//                       },
//                       // borderRadius: SizeConfig.size8,
//                     ),
//                     SizedBox(height: SizeConfig.size18),
          
//                     CustomText(
//                       "Account Type",
//                       fontSize: SizeConfig.medium,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.black,
//                     ),
//                     SizedBox(height: SizeConfig.paddingXSL),
//                     CommonDropdown<BankAccountType>(
//                       items: BankAccountType.values,
//                       selectedValue: controller.selectedAccount.value,
//                       hintText: "Saving",
//                       displayValue: (bankAccountType) =>
//                           bankAccountType.displayName,
//                       onChanged: (value) {
//                         controller.selectedAccount.value = value!;
//                         isFormValid();
          
//                         // Trigger rebuild for dynamic fields
//                       },
//                       validator: (value) {
//                         if (value == null) {
//                           return 'Please select your profession';
//                         }
//                         return null;
//                       },
//                     ),
//                     SizedBox(height: SizeConfig.size24),
          
//                     // Add Button
//                     CustomBtn(
//                       isValidate: validate,
//                       onTap: validate
//                           ? () async {
//                               await controller.addBankDetailsController(
//                                   channelID: widget.channelId);
//                             }
//                           : null,
//                       title: (widget.isUpdate) ? 'Update' : 'Add',
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ) : Center(child: CircularProgressIndicator());
//       }),
//     );
//   }

//   void isFormValid() {
//     validate = controller.bankNameController.text.trim().isNotEmpty &&
//         controller.bankNameController.text.trim().isNotEmpty &&
//         controller.accountNumberController.text.trim().isNotEmpty &&
//         controller.ifscCodeController.text.trim().isNotEmpty &&
//         controller.selectedAccount.value != null;
//     setState(() {});
//   }
// }
