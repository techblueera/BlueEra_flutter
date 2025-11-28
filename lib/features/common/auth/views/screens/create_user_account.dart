// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/app_enum.dart';
// import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
// import 'package:BlueEra/features/common/auth/views/screens/Individual/personal_account_new_screen.dart';
// import 'package:BlueEra/features/common/auth/views/screens/gst_verification_screen.dart';
// import 'package:flutter/material.dart';
//
// class CreateUserAccount extends StatefulWidget {
//
//   const CreateUserAccount({
//     super.key,
//     required this.accountType,
//     this.businessType,
//     this.categoryData,
//     this.subCategory
//   });
//
//   final String accountType;
//   final BusinessType? businessType;
//   final CategoryData? categoryData;
//   final SubCategories? subCategory;
//
//   @override
//   State<CreateUserAccount> createState() => _CreateUserAccountState();
// }
//
// class _CreateUserAccountState extends State<CreateUserAccount> {
//
//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       child: (widget.accountType == AppConstants.individual)
//           ? PersonalAccountNewScreen()
//           :  (widget.accountType == AppConstants.business)
//                   ? GstNumberScreen(
//                         businessType: widget.businessType,
//                         categoryData: widget.categoryData,
//                         subCategory: widget.subCategory,
//                    )
//                   : SizedBox(),
//     );
//   }
// }
