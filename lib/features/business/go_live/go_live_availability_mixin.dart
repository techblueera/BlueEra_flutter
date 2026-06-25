// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/app_strings.dart';
// import 'package:BlueEra/core/constants/shared_preference_utils.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/features/business/auth/repo/business_profile_repo.dart';
// import 'package:BlueEra/features/common/Discover/view/go_live_permission_screen.dart';
// import 'package:BlueEra/features/me/grocery/view/admin/grocery_shop_availability_screen.dart';
// import 'package:BlueEra/permissionCentralize/go_live_permission_service.dart';
// import 'package:BlueEra/widgets/custom_btn.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// /// Shared "Go-Live + shop availability" flow, extracted from the grocery
// /// home screen so every business/profile surface can reuse the exact same
// /// behaviour:
// ///
// ///   • Business accounts must declare their shop availability (daily/weekly
// ///     open–close hours) before going live. Tapping Go-Live prompts a
// ///     Create / Later dialog; "Create" walks through the background-location
// ///     + battery-optimization permission gate and the availability screen.
// ///   • Every other account type keeps a plain toggle, and turning the shop
// ///     OFF never needs any of these checks.
// ///   • On every app open (business account only) sellers who have never set
// ///     their availability are reminded with the same dialog.
// ///
// /// Mix into a [State], drive your go-live toggle from [handleGoLiveTap], read
// /// [isShopGoLive] for the toggle visual, and call
// /// [maybeShowAvailabilityReminder] once after the first frame in `initState`.
// mixin GoLiveAvailabilityMixin<T extends StatefulWidget> on State<T> {
//   /// Local live state backing the host screen's toggle/pill.
//   bool isShopGoLive = false;
//
//   /// Business id the availability is scoped to. Defaults to the global
//   /// [businessId]; override on screens that carry their own id.
//   String get goLiveBusinessId => businessId;
//
//   bool get _isBusinessAccount =>
//       accountTypeGlobal == AppConstants.business;
//
//   /// Drive the host's Go-Live toggle from here. Handles the OFF path,
//   /// the non-business plain-toggle path, and the business availability
//   /// prompt path.
//   Future<void> handleGoLiveTap() async {
//     if (isShopGoLive) {
//       setState(() => isShopGoLive = false);
//       // Mark the shop offline on the backend so reminders/visibility stop.
//       if (_isBusinessAccount) {
//         await BusinessProfileRepo().endLive();
//       }
//       return;
//     }
//
//     if (!_isBusinessAccount) {
//       setState(() => isShopGoLive = true);
//       return;
//     }
//
//     // Business sellers must declare their shop availability before going
//     // live. Open the availability flow directly.
//     openAvailabilityFlow();
//   }
//
//   /// Permission gate + availability screen. On a successful save the shop is
//   /// already live on the backend, so we flip the local toggle and remember
//   /// (locally) that availability has been set to stop the reminder.
//   Future<void> openAvailabilityFlow() async {
//     // Gate on background location + battery optimization. If either is
//     // missing, route through the shared permission screen and bail out
//     // unless the user grants everything there.
//     final statuses = await GoLivePermissionService.checkAll();
//     final permissionsReady =
//         statuses[GoLivePermissionType.backgroundLocation] == true &&
//             statuses[GoLivePermissionType.batteryOptimization] == true;
//     if (!permissionsReady) {
//       final granted = await Get.to(() => const GoLivePermissionScreen());
//       if (granted != true) return;
//     }
//
//     // Permissions in place — collect the shop availability on its own
//     // screen. The screen persists the hours and goes live via the backend,
//     // popping back `true` only on full success.
//     final result = await Get.to(() => const GroceryShopAvailabilityScreen());
//     if (result == true && mounted) {
//       setState(() => isShopGoLive = true);
//       await SharedPreferenceUtils.setGroceryAvailabilitySet(goLiveBusinessId);
//     }
//   }
//
//   /// Reminder shown on every app open (business account only) while the shop
//   /// availability has never been set — and the same prompt a business sees
//   /// when it taps Go-Live. "Create" opens the availability flow; "Later"
//   /// just dismisses.
//   void showSetAvailabilityDialog() {
//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return Dialog(
//           backgroundColor: AppColors.white,
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           child: Padding(
//             padding: EdgeInsets.all(SizeConfig.size20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CustomText(
//                   AppStrings.setYourShopTimings.tr,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w800,
//                   color: AppColors.mainTextColor,
//                 ),
//                 SizedBox(height: SizeConfig.size8),
//                 CustomText(
//                   AppStrings.shopTimingsSubtitle.tr,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                   color: AppColors.secondaryTextColor,
//                 ),
//                 SizedBox(height: SizeConfig.size20),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: CustomBtn(
//                         bgColor: AppColors.white,
//                         borderColor: AppColors.primaryColor,
//                         textColor: AppColors.primaryColor,
//                         title: AppStrings.maybeLater.tr,
//                         onTap: () => Navigator.of(dialogContext).pop(),
//                       ),
//                     ),
//                     SizedBox(width: SizeConfig.size12),
//                     Expanded(
//                       child: CustomBtn(
//                         bgColor: AppColors.primaryColor,
//                         borderColor: AppColors.primaryColor,
//                         textColor: AppColors.white,
//                         title: AppStrings.create.tr,
//                         onTap: () {
//                           Navigator.of(dialogContext).pop();
//                           openAvailabilityFlow();
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   /// On app open, nudge business sellers who have not yet set their shop
//   /// availability. Purely local — once availability is set the flag is
//   /// stored and this stops firing. Call once after the first frame.
//   Future<void> maybeShowAvailabilityReminder() async {
//     if (!_isBusinessAccount) return;
//     final alreadySet =
//         await SharedPreferenceUtils.isGroceryAvailabilitySet(goLiveBusinessId);
//     if (alreadySet || !mounted) return;
//     showSetAvailabilityDialog();
//   }
// }
