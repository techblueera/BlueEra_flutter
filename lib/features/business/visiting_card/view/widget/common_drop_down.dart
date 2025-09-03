// // import 'package:BlueEra/core/constants/app_colors.dart';
// // import 'package:BlueEra/core/constants/size_config.dart';
// // import 'package:BlueEra/widgets/custom_text_cm.dart';
// // import 'package:flutter/material.dart';
//
// // class CommonDropdown<T> extends StatelessWidget {
// //   final List<T> items;
// //   final T? selectedValue;
// //   final String hintText;
// //   final String? Function(T?)? validator;
// //   final void Function(T?) onChanged;
// //   final String Function(T) displayValue;
// //   final bool isExpanded;
//
// //   const CommonDropdown({
// //     Key? key,
// //     required this.items,
// //     required this.selectedValue,
// //     required this.hintText,
// //     required this.onChanged,
// //     required this.displayValue,
// //     this.validator,
// //     this.isExpanded = true,
// //   }) : super(key: key);
//
// //   @override
// //   Widget build(BuildContext context) {
// //     return DropdownButtonFormField<T>(
// //       value: selectedValue,
// //       isExpanded: isExpanded,
// //       style: const TextStyle(color: Colors.white),
// //       dropdownColor:AppColors.black28,
// //       icon: Icon(Icons.keyboard_arrow_down_outlined,color: Colors.white,),
// //       hint: CustomText(hintText,
// //           color: AppColors.grey9B,
// //           fontSize: SizeConfig.medium,
// //           fontWeight: FontWeight.w400),
// //       items: items.map((T item) {
// //         return DropdownMenuItem<T>(
// //           value: item,
// //           child: CustomText(displayValue(item),
// //               fontSize: SizeConfig.medium, fontWeight: FontWeight.w400),
// //         );
// //       }).toList(),
// //       onChanged: onChanged,
// //       validator: validator,
//
// //     );
// //   }
// // }
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:flutter/material.dart';
//
// class CommonDropdown<T> extends StatelessWidget {
//   final List<T> items;
//   final T? selectedValue;
//   final String hintText;
//   final String? Function(T?)? validator;
//   final void Function(T?) onChanged;
//   final String Function(T) displayValue;
//   final bool isExpanded;
//
//   const CommonDropdown({
//     Key? key,
//     required this.items,
//     required this.selectedValue,
//     required this.hintText,
//     required this.onChanged,
//     required this.displayValue,
//     this.validator,
//     this.isExpanded = true,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return DropdownButtonFormField<T>(
//       value: selectedValue,
//       isExpanded: isExpanded,
//       style: const TextStyle(
//         color: Colors.white,
//         fontWeight: FontWeight.w500,
//       ),
//       dropdownColor: AppColors.blue35,
//       icon: const Icon(Icons.keyboard_arrow_down_outlined, color: Colors.white),
//       hint: CustomText(
//         hintText,
//         color: AppColors.grey9B,
//         fontSize: SizeConfig.medium,
//         fontWeight: FontWeight.w400,
//       ),
//       // To avoid full highlight in selected dropdown field
//       selectedItemBuilder: (BuildContext context) {
//         return items.map((T item) {
//           return CustomText(
//             displayValue(item),
//             color: AppColors.white,
//             fontSize: SizeConfig.medium,
//             fontWeight: FontWeight.w400,
//           );
//         }).toList();
//       },
//       items: items.map((T item) {
//         final isSelected = selectedValue == item;
//         return DropdownMenuItem<T>(
//           value: item,
//           child: Container(
//             width: double.infinity,
//             color: isSelected ? AppColors.primaryColor : Colors.transparent,
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
//             child: CustomText(
//               displayValue(item),
//               color: Colors.white,
//               fontSize: SizeConfig.medium,
//               fontWeight: FontWeight.w400,
//             ),
//           ),
//         );
//       }).toList(),
//       onChanged: onChanged,
//       validator: validator,
//     );
//   }
// }
