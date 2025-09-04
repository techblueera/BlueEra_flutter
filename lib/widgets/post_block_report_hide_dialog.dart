// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/common_dialogs.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/l10n/app_localizations.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:BlueEra/widgets/hide_confirmation_dialog.dart';
// import 'package:BlueEra/widgets/report_dialog.dart';
// import 'package:flutter/material.dart';
//
// void showPostOptionsDialog({
//   required BuildContext context,
//   required int postId,
//   required String userId,
//   required int index,
//   required bool isAuthor,
// }) {
//   showDialog(
//     context: context,
//     builder: (context) => Dialog(
//       backgroundColor: AppColors.white,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//
//       ),
//       child: Padding(
//         padding: EdgeInsets.only(
//           left: 20.0,
//           right: 10.0,
//           top: 20,
//           bottom: MediaQuery
//               .of(context)
//               .viewInsets
//               .bottom + 20,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 CustomText(
//                   "Choose an action",
//                     fontWeight: FontWeight.bold,
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(right: 8.0),
//                   child: InkWell(
//                     onTap: () => Navigator.pop(context),
//                     child: Icon(
//                       Icons.close,
//                       color: AppColors.black,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             ListTile(
//               visualDensity: VisualDensity(vertical: -2),
//               contentPadding: EdgeInsets.zero,
//               onTap: () {
//                 Navigator.pop(context);
//                 openBlockSelectionDialog(context, userId);
//               },
//               title: Text(
//                 AppLocalizations.of(context)!.block,
//                 style: TextStyle(
//                     fontSize: SizeConfig.screenWidth * .036,
//                     fontWeight: FontWeight.w500,
//                     color: AppColors.black28
//                 ),
//               ),
//             ),
//             ListTile(
//               visualDensity: VisualDensity(vertical: -2),
//               contentPadding: EdgeInsets.zero,
//               onTap: () {
//                 Navigator.pop(context);
//                 showDialog(
//                   context: context,
//                   builder: (BuildContext context) {
//                     return Dialog(
//                         insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
//                         backgroundColor: Colors.transparent,
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(25),
//                         child: Material(
//                           color: AppColors.white,
//                           child:  ReportDialog(
//                             reportReasons: {
//                               AppLocalizations.of(context)!.inappropriateContent: false,
//                               AppLocalizations.of(context)!.promotesHatredViolence: false,
//                               AppLocalizations.of(context)!.fraudOrScam: false,
//                               AppLocalizations.of(context)!.contentIsSpam: false,
//                             },
//                             reportType: 'POST',
//                             contentId: postId,
//                             reportTo: postId,
//                             postModelIndex: index,
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//               title: Text(
//                 AppLocalizations.of(context)!.report,
//                 style: TextStyle(
//                     fontSize: SizeConfig.screenWidth * .036,
//                     fontWeight: FontWeight.w500,
//                     color: AppColors.black28
//                 ),
//               ),
//             ),
//             ListTile(
//               visualDensity: VisualDensity(vertical: -2),
//               contentPadding: EdgeInsets.zero,
//               onTap: () {
//                 Navigator.pop(context);
//                 showDialog(
//                   context: context,
//                   builder: (_) => Dialog(
//                     backgroundColor: AppColors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: HideConformationDialog(
//                       postModelIndex: index,
//                       postId: postId.toString(),
//                     ),
//                   ),
//                 );
//               },
//               title: Text(
//                 AppLocalizations.of(context)!.hideThisPost,
//                 style: TextStyle(
//                   fontSize: SizeConfig.screenWidth * .036,
//                   fontWeight: FontWeight.w500,
//                   color: AppColors.black28
//                 ),
//               ),
//             ),
//
//           ],
//         ),
//       ),
//     ),
//   );
// }
//
