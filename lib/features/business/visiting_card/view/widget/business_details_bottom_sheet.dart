//
// import 'dart:developer';
//
// import 'package:BlueEra/core/api/apiService/api_keys.dart';
// import 'package:BlueEra/core/api/model/type_of_business_model.dart';
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/app_enum.dart';
// import 'package:BlueEra/core/constants/common_http_links_textfiled_widget.dart';
// import 'package:BlueEra/core/constants/no_leading_space_formatter.dart';
// import 'package:BlueEra/core/constants/regular_expression.dart';
// import 'package:BlueEra/core/constants/shared_preference_utils.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/core/constants/snackbar_helper.dart';
// import 'package:BlueEra/core/controller/location_controller.dart';
// import 'package:BlueEra/core/routes/route_helper.dart';
// import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
// import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
// import 'package:BlueEra/features/business/visiting_card/view/widget/contact_number_widget.dart';
// import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
// import 'package:BlueEra/l10n/app_localizations.dart';
// import 'package:BlueEra/widgets/commom_textfield.dart';
// import 'package:BlueEra/widgets/common_drop_down-dialoge.dart';
// import 'package:BlueEra/widgets/common_drop_down_icon_dialoge.dart';
// import 'package:BlueEra/widgets/custom_btn.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
//
//
// class BusinessDetailsBottomSheet extends StatefulWidget {
//   final BusinessProfileDetails? prevBusinessDetails;
//   final bool isFromCreateUser;
//
//   const BusinessDetailsBottomSheet({
//     super.key,
//     this.prevBusinessDetails,
//     this.isFromCreateUser = false,
//   });
//
//   @override
//   State<BusinessDetailsBottomSheet> createState() =>
//       _BusinessDetailsBottomSheetState();
// }
//
// class _BusinessDetailsBottomSheetState extends State<BusinessDetailsBottomSheet> {
//   final viewBusinessDetailsController = Get.find<ViewBusinessDetailsController>();
//   final locationController = Get.put(LocationController());
//
//   final companyOrgNameTextController = TextEditingController();
//   final landlineNumberController = TextEditingController();
//   final landlineCodeController = TextEditingController();
//   final mobileController = TextEditingController();
//   final websiteController = TextEditingController();
//   final othersCatController = TextEditingController();
//
//   ContactType? selectedType = ContactType.Mobile;
//   SizeOfBusiness? selectedBusiness;
//
//   final subCategoryTextController = TextEditingController();
//   final subCategorySpecializationTextController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     viewBusinessDetailsController.getAllCategories();
//     _initializeFields();
//   }
//
//   void _initializeFields() {
//     final data = widget.prevBusinessDetails;
//
//     if (data != null) {
//       companyOrgNameTextController.text = data.businessName ?? '';
//
//       selectedBusiness = data.natureOfBusiness != null
//           ? SizeOfBusiness.values.firstWhere(
//             (e) =>
//         e.displayName.toLowerCase() ==
//             data.natureOfBusiness!.toLowerCase(),
//         orElse: () => SizeOfBusiness.OTHERS,
//       )
//           : null;
//
//       websiteController.text = data.websiteUrl ?? '';
//
//       log('officeMobNo --> ${data.businessNumber?.officeMobNo?.number}');
//       if (data.businessNumber?.officeMobNo?.number != null) {
//         mobileController.text =
//             data.businessNumber?.officeMobNo?.number.toString() ?? "";
//         selectedType = ContactType.Mobile;
//       } else if (data.businessNumber?.officeLandlineNo?.number != null) {
//         landlineNumberController.text =
//             data.businessNumber?.officeLandlineNo?.number.toString() ?? "";
//         landlineCodeController.text =
//             data.businessNumber?.officeLandlineNo?.number.toString() ?? "";
//         selectedType = ContactType.Landline;
//       }
//       othersCatController.text = data.natureOfBusiness ?? "";
//
//       subCategoryTextController.text = data.category_other ?? '';
//
//       if((viewBusinessDetailsController.selectedSubCategoryOfBusinessNew.value!=null)
//           ||(viewBusinessDetailsController
//           .selectedCategoryOfBusiness.value!=null))
//       {
//         subCategorySpecializationTextController.text = data.specification ?? '';
//       }
//       else{
//         subCategorySpecializationTextController.clear();
//       }
//
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final appLocalizations = AppLocalizations.of(context);
//     final theme = Theme.of(context);
//
//     return DraggableScrollableSheet(
//       expand: false,
//       initialChildSize: 0.6,
//       minChildSize: 0.5,
//       maxChildSize: 0.95,
//       builder: (context, scrollController) {
//         return Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//           ),
//           child: Container(
//             decoration: BoxDecoration(
//               color: theme.colorScheme.surface,
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//             ),
//             padding: EdgeInsets.only(
//               left: SizeConfig.size16,
//               right: SizeConfig.size16,
//               top: SizeConfig.size30,
//               bottom: SizeConfig.size16,
//             ),
//             child: SingleChildScrollView(
//               controller: scrollController,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "Business Details (Step 1 of 2)",
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.close),
//                         onPressed: () => Navigator.of(context).pop(),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//
//                   CommonTextField(
//                     textEditController: companyOrgNameTextController,
//                     inputLength: AppConstants.inputCharterLimit50,
//                     keyBoardType: TextInputType.text,
//                     regularExpression:
//                     RegularExpressionUtils.alphabetSpacePattern,
//                     title: "Business Name",
//                     hintText: AppConstants.companyOrgBusiness,
//                     isValidate: false,
//                   ),
//                   const SizedBox(height: 20),
//
//                   /// Date Picker
//                   CustomText(
//                     "Date of Incorporation",
//                     fontSize: SizeConfig.medium,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   const SizedBox(height: 10),
//                   NewDatePicker(
//                     selectedDay: viewBusinessDetailsController.selectDay?.value,
//                     selectedMonth:
//                     viewBusinessDetailsController.selectMonth?.value,
//                     selectedYear: viewBusinessDetailsController.selectYear?.value,
//                     onDayChanged: (v) =>
//                     viewBusinessDetailsController.selectDay?.value = v ?? 0,
//                     onMonthChanged: (v) =>
//                     viewBusinessDetailsController.selectMonth?.value = v ?? 0,
//                     onYearChanged: (v) =>
//                     viewBusinessDetailsController.selectYear?.value = v ?? 0,
//                   ),
//
//                   SizedBox(
//                     height: SizeConfig.size20,
//                   ),
//
//                   /// Type of the Business....
//                   CustomText(
//                     "Type of the Business",
//                     fontSize: SizeConfig.medium,
//                     fontWeight: FontWeight.w500,
//                     color: AppColors.black,
//                   ),
//                   SizedBox(
//                     height: SizeConfig.size14,
//                   ),
//                   Obx(() {
//                     return CommonDropdownIconDialog<BusinessCategory>(
//                       items: typeOfBusinessList,
//                       selectedValue: viewBusinessDetailsController
//                           .selectedTypeOfBusiness.value,
//                       hintText:
//                       appLocalizations?.selectNatureOfTheBusiness ?? "",
//                       displayValue: (profession) => profession.title,
//                       title: appLocalizations?.natureOfBusiness ??
//                           "Nature of the Business",
//                       onChanged: (value) {
//                         viewBusinessDetailsController.selectedTypeOfBusiness
//                             .value = value!;
//                         if(value.type==BusinessType.Product.name)
//                         {
//                           viewBusinessDetailsController.selectedBusinessType?.value=BusinessType.Product;
//
//                         }
//                         else if(value.type==BusinessType.Service.name)
//                         {
//                           viewBusinessDetailsController.selectedBusinessType?.value=BusinessType.Service;
//
//                         }
//                         else if(value.type==BusinessType.Food.name)
//                         {
//                           viewBusinessDetailsController.selectedBusinessType?.value=BusinessType.Food;
//
//                         }
//                         else{
//                           viewBusinessDetailsController.selectedBusinessType?.value=BusinessType.Both;
//
//                         }
//                         viewBusinessDetailsController
//                             .selectedCategoryOfBusiness.value = null;
//                         viewBusinessDetailsController
//                             .selectedSubCategoryOfBusinessNew
//                             .value = null;
//                         viewBusinessDetailsController
//                             .businessSubCategoriesList
//                             .clear();
//
//                       },
//                       displayValueSubTitle: (profession) =>
//                       profession.subTitle,
//                       displayValueImagePath: (profession) => profession.icon,
//                     );
//                   }),
//
//
//                   ///Supply chain...
//                   if (viewBusinessDetailsController. selectedTypeOfBusiness.value.type ==
//                       BusinessType.Product.name)...[
//                     SizedBox(
//                       height: SizeConfig.size20,
//                     ),
//
//                     CustomText(
//                       'Nature of the Business',
//                       fontSize: SizeConfig.medium,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.black,
//                     ),
//                     SizedBox(
//                       height: SizeConfig.size10,
//                     ),
//                     CommonDropdownDialog<SizeOfBusiness>(
//                       items: SizeOfBusiness.values,
//                       selectedValue: selectedBusiness,
//                       title: 'Nature of the Business',
//                       hintText: "Enter Category (if Others)",
//                       displayValue: (profession) => profession.displayName,
//                       onChanged: (value) {
//                         setState(() {
//                           selectedBusiness = value;
//                         });
//
//                       },
//                     ),
//
//
//                     (selectedBusiness == SizeOfBusiness.OTHERS)
//                         ? SizedBox(
//                       height: SizeConfig.size10,
//                     )
//                         : SizedBox(),
//                     (selectedBusiness == SizeOfBusiness.OTHERS)
//                         ? CommonTextField(
//                       textEditController: othersCatController,
//                       inputLength: AppConstants.inputCharterLimit50,
//                       keyBoardType: TextInputType.text,
//                       regularExpression:
//                       RegularExpressionUtils.alphabetSpacePattern,
//                       hintText: appLocalizations?.eGMedicalShopKiranaShop,
//                       isValidate: false,
//                     )
//                         : SizedBox(),
//
//                     // SizedBox(
//                     //   height: SizeConfig.size20,
//                     // ),
//
//                   ],
//
//                   const SizedBox(height: 20),
//
//                   CustomText(
//                     "Category of Business ${viewBusinessDetailsController
//                         .selectedBusinessType?.value.name}",
//                     fontSize: SizeConfig.medium,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   SizedBox(
//                     height: SizeConfig.size10,
//                   ),
//
//                   Obx(() {
//                     return viewBusinessDetailsController
//                         .selectedBusinessType?.value.name
//                         .toLowerCase() !=
//                         "both"
//                         ? Column(
//                       children: [
//                         CommonDropdownDialog<CategoryData>(
//                           items: viewBusinessDetailsController
//                               .businessCategoriesList
//                               .where((e) =>
//                           e.type?.toLowerCase() ==
//                               viewBusinessDetailsController
//                                   .selectedBusinessType?.value.name
//                                   .toLowerCase())
//                               .toList(),
//                           title:  "Category of Business",
//                           // items: viewBusinessDetailsController
//                           //     .businessCategoriesList,
//                           selectedValue: viewBusinessDetailsController
//                               .selectedCategoryOfBusiness.value,
//                           hintText:
//                           appLocalizations?.selectCategoryOfBusiness ??
//                               "",
//                           displayValue: (category) => "${category.name}",
//
//                           onChanged: (value) {
//                             viewBusinessDetailsController
//                                 .businessSubCategoriesList
//                                 .clear();
//                             viewBusinessDetailsController
//                                 .businessSubCategoriesList
//                                 .addAll(value?.subCategories ?? []);
//                             viewBusinessDetailsController
//                                 .selectedSubCategoryOfBusinessNew
//                                 .value = null;
//
//                             viewBusinessDetailsController
//                                 .selectedCategoryOfBusiness
//                                 .value = value ?? CategoryData();
//                           },
//                         ),
//                         SizedBox(
//                           height: SizeConfig.size20,
//                         ),
//                         Align(
//                           alignment: Alignment.centerLeft,
//                           child: CustomText(
//                             appLocalizations?.subCategory,
//                             fontSize: SizeConfig.medium,
//                           ),
//                         ),
//                         SizedBox(
//                           height: SizeConfig.size10,
//                         ),
//
//                     viewBusinessDetailsController.isCategoriesLoading.value ?
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation<Color>(
//                               AppColors.primaryColor,
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: 12),
//                         CustomText(
//                           "Loading categories...",
//                           color: AppColors.grey80,
//                           fontSize: SizeConfig.small,
//                         ),
//                       ],
//                     )
//                         : CommonDropdownDialog<SubCategories>(
//                           items: viewBusinessDetailsController
//                               .businessSubCategoriesList,
//                           selectedValue: viewBusinessDetailsController
//                               .selectedSubCategoryOfBusinessNew.value,
//                           hintText: "Select Sub Category",
//                           title: "Select Sub Category",
//
//                           displayValue: (category) => "${category.name}",
//                           onChanged: (value) {
//                             viewBusinessDetailsController
//                                 .selectedSubCategoryOfBusinessNew
//                                 .value = value;
//                           },
//                         ),
//                         const SizedBox(height: 20),
//
//                         CommonTextField(
//                           textEditController:subCategorySpecializationTextController,
//                           hintText: "Eg. South Indian Restaurant",
//                           title: "Business Specialization (Optional)",
//                           maxLine: 1,
//                           maxLength: 24,
//                           keyBoardType: TextInputType.text,
//                           textInputAction: TextInputAction.done,
//                           isValidate: false,
//                           inputFormatters: [
//                             FilteringTextInputFormatter.allow(RegExp(
//                                 RegularExpressionUtils
//                                     .alphabetPatternSpace)),
//                             NoLeadingSpaceFormatter(),
//                             NoConsecutiveSpacesFormatter(),
//                           ],
//                           // we will handle validation manually
//                           onChange: (val) {
//                             String newVal = val;
//                             viewBusinessDetailsController
//                                 .categorySpecializationText.value = val;
//                             // Allow only alphabets + spaces
//                             if (!RegExp(r'^[a-zA-Z ]*$')
//                                 .hasMatch(newVal)) {
//                               viewBusinessDetailsController.errorMessage.value =
//                               "Special characters are not allowed";
//                             }
//                             else if (newVal.isEmpty) {
//                               viewBusinessDetailsController.errorMessage.value =
//                               "Please enter business specialization";
//                             }
//                             else if (newVal.length < 8) {
//                               viewBusinessDetailsController.errorMessage.value =
//                               "Mini 8 char required";
//                             } else if (newVal.length > 24) {
//                               viewBusinessDetailsController.errorMessage.value =
//                               "Maxi 24 char allowed";
//                             } else {
//                               viewBusinessDetailsController.errorMessage.value = "";
//                             }
//
//                             // Keep latest valid value
//                             // authController.otherNatureOfBusinessTextController.text = newVal;
//                             // authController.otherNatureOfBusinessTextController.selection =
//                             //     TextSelection.fromPosition(
//                             //       TextPosition(offset: newVal.length),
//                             //     );
//                           },
//                         ),
//
//                         SizedBox(height: 5),
//
//                         // 👇 Error/Helper Message
//                         Obx(() => viewBusinessDetailsController
//                             .errorMessage.value.isNotEmpty &&
//                             (viewBusinessDetailsController.categorySpecializationText
//                                 .value.isNotEmpty)
//                             ? Align(
//                           alignment: Alignment.centerLeft,
//                           child: CustomText(
//                             viewBusinessDetailsController.errorMessage.value,
//                             color: Colors.red,
//                             fontSize: 12,
//                             textAlign: TextAlign.left,
//                           ),
//                         )
//                             : SizedBox()),
//
//                         // 👇 Counter (bottom right)
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: Obx(() => CustomText(
//                             "${viewBusinessDetailsController.categorySpecializationText.value.length}/24",
//                             color: Colors.grey,
//                             fontSize: 12,
//                           )),
//                         ),
//                       ],
//                     )
//                         : CommonTextField(
//                       textEditController: subCategoryTextController,
//                       maxLength: AppConstants.inputCharterLimit30,
//                       keyBoardType: TextInputType.text,
//                       regularExpression:
//                       RegularExpressionUtils.alphabetSpacePattern,
//                       title: "",
//                       hintText: "Enter Category of Business",
//                       isValidate: true,
//                       onChange: (val) {
//                         setState(() {});
//                       },
//                       validator: (value) {
//                         // if (authController.businessName.value.isEmpty) {
//                         //   return 'Please enter your business or organization name';
//                         // } else if (authController.businessName.value.length <
//                         //     5) {
//                         //   return 'Minimum 5 characters required';
//                         // }
//                         return null;
//                       },
//                     );
//                   }),
//                   SizedBox(
//                     height: SizeConfig.size20,
//                   ),
//
//                   /// Mobile/Landline
//                   ContactInputField1(
//                     mobileController: mobileController,
//                     landlineCodeController: landlineCodeController,
//                     landlineNumberController: landlineNumberController,
//                     selectedType: selectedType ?? ContactType.Mobile,
//                     onTypeChanged: (type) => setState(() => selectedType = type),
//                     prefixOnChange: (v) => true,
//                     mobileNumberOnChange: (v) {},
//                   ),
//                   const SizedBox(height: 20),
//
//                   ///websiteOptional
//                   CustomText(
//                     appLocalizations?.websiteOptional,
//                     fontSize: SizeConfig.medium,
//                     fontWeight: FontWeight.w500,
//                     color: AppColors.black,
//                   ),
//                   SizedBox(
//                     height: SizeConfig.size10,
//                   ),
//                   HttpsTextField(
//                     controller: websiteController,
//                     hintText: AppLocalizations.of(context)!.websiteLinkHere,
//                   ),
//                   SizedBox(
//                     height: SizeConfig.size20,
//                   ),
//
//                   /// Buttons
//                   CustomBtn(
//                     radius: 10,
//                     bgColor: AppColors.primaryColor,
//                     onTap: () async {
//                       if (companyOrgNameTextController.text.isNotEmpty) {
//                         if (viewBusinessDetailsController
//                             .selectedBusinessType?.value.name
//                             .toLowerCase() ==
//                             "both") {
//                           if (subCategoryTextController.text.isEmpty) {
//                             commonSnackBar(
//                                 message: "Please Enter Category of Business");
//                             return;
//                           }
//                         }
//
//
//                         Map<String, dynamic> params = await buildBusinessDetailsPayload();
//                         await Get.find<ViewBusinessDetailsController>()
//                             .updateBusinessDetails(params);
//                         if (widget.isFromCreateUser == false) {
//                           Navigator.of(context).pop();
//                         } else {
//                           Get.offNamedUntil(
//                             RouteHelper.getBottomNavigationBarScreenRoute(),
//                                 (route) => false,
//                           );
//                         }
//
//                       } else {
//                         commonSnackBar(
//                             message: "Please Enter Required Field");
//                       }
//                     },
//                     title: "Save",
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Future<Map<String, dynamic>> buildBusinessDetailsPayload() async {
//     return {
//       ApiKeys.businessId: businessId,
//       ApiKeys.business_name: companyOrgNameTextController.text,
//       ApiKeys.date_of_incorporation: {
//         ApiKeys.date: viewBusinessDetailsController.selectDay?.value,
//         ApiKeys.month: viewBusinessDetailsController.selectMonth?.value,
//         ApiKeys.year: viewBusinessDetailsController.selectYear?.value
//       },
//       ApiKeys.type_of_business:
//       viewBusinessDetailsController.selectedBusinessType?.value.name ?? '',
//       ApiKeys.Nature_of_Business: selectedBusiness == SizeOfBusiness.OTHERS
//           ? othersCatController.text
//           : selectedBusiness?.displayName ?? '',
//       ApiKeys.office_mob_no_Pre: 91,
//       if (mobileController.text.isNotEmpty)
//         ApiKeys.office_mob_no_number: mobileController.text,
//       if (landlineCodeController.text.isNotEmpty)
//         ApiKeys.office_landline_no_pre: landlineCodeController.text,
//       if (landlineNumberController.text.isNotEmpty)
//         ApiKeys.office_landline_no_number: landlineNumberController.text,
//       ApiKeys.website_url: websiteController.text,
//
//       ApiKeys.category_Of_Business:
//       (viewBusinessDetailsController
//           .selectedBusinessType?.value.name
//           .toLowerCase() ==
//           "both")
//           ? "68a80b766fdb4e82b42b77c0"
//           : viewBusinessDetailsController
//           .selectedCategoryOfBusiness.value?.id,
//       if (viewBusinessDetailsController
//           .selectedBusinessType?.value.name
//           .toLowerCase() ==
//           "both")
//         ApiKeys.category_other:
//         subCategoryTextController.text,
//
//       if (viewBusinessDetailsController
//           .selectedSubCategoryOfBusinessNew
//           .value
//           ?.sId
//           ?.isNotEmpty ??
//           false)
//         ApiKeys.sub_category_Of_Business:
//         viewBusinessDetailsController
//             .selectedSubCategoryOfBusinessNew
//             .value
//             ?.sId,
//       if(subCategorySpecializationTextController.text.isNotEmpty)
//         ApiKeys.specification:subCategorySpecializationTextController.text,
//
//     };
//
//   }
//
// }
