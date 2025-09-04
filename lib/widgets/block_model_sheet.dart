// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
// import 'package:BlueEra/l10n/app_localizations.dart';
// import 'package:BlueEra/widgets/custom_btn.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class BlockModalSheet extends StatefulWidget {
//   const BlockModalSheet({
//     super.key,
//     required this.userId,
//   });
//
//   final String userId;
//
//   @override
//   State<BlockModalSheet> createState() => _BlockModalSheetState();
// }
//
// class _BlockModalSheetState extends State<BlockModalSheet> {
//   final LayerLink _layerLink = LayerLink(); // To link the target and follower
//   final LayerLink _layerLink2 = LayerLink(); // To link the target and follower
//
//   OverlayEntry? _overlayEntry;
//   OverlayEntry? _overlayEntry2; // To store the overlay entry
//
//   @override
//   Widget build(BuildContext context) {
//     AppLocalizations.of(context);
//
//     return Container(
//         width: 500,
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           // color: AppColors.blueBackground,
//             color: AppColors.white,
//             borderRadius: BorderRadius.circular(12)),
//         // height: screenHeight(context) * 0.5,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: CustomText(
//                     AppLocalizations.of(context)!.blockUser,
//                     fontSize: SizeConfig.extraLarge22,
//                     color: AppColors.mainTextColor,
//                     fontWeight: FontWeight.w700,
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   icon: const Icon(
//                     Icons.close_rounded,
//                     color: AppColors.mainTextColor,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             InkWell(
//               onTap: () {
//                 Navigator.pop(context);
//                 Get.find<FeedController>().userBlocked(isPartialBlocked: true, otherUserId: widget.userId);
//               },
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: CustomText(
//                       AppLocalizations.of(context)!.partiallyBlockThisUser,
//                       color: AppColors.secondaryTextColor,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   CompositedTransformTarget(
//                     link: _layerLink, // Linking the position of the info icon
//                     child: IconButton(
//                       icon: const Icon(Icons.info_outline,
//                           color: AppColors.black28
//                       ),
//                       onPressed: () {
//                         if (_overlayEntry == null) {
//                           _showPartialBlockOverlay(context);
//                           _removeFullyBlockOverlay();
//                         } else {
//                           _removePartialBlockOverlay();
//                         }
//                       },
//                     ),
//                   )
//                 ],
//               ),
//             ),
//             InkWell(
//               onTap: () {
//                 Navigator.pop(context);
//                 openFullyBlockModal(context, widget.userId);
//               },
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: CustomText(
//                       AppLocalizations.of(context)!.fullyBlockThisUser,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.secondaryTextColor,
//                     ),
//                   ),
//                   CompositedTransformTarget(
//                     link:
//                     _layerLink2, // Linking the position of the info icon
//                     child: IconButton(
//                       icon: const Icon(Icons.info_outline,
//                           color: AppColors.black28
//                       ),
//                       onPressed: () {
//                         if (_overlayEntry2 == null) {
//                           _showFullyBlockOverlay(context);
//                           _removePartialBlockOverlay();
//                         } else {
//                           _removeFullyBlockOverlay();
//                         }
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ));
//   }
//
//   // Function to display the overlay
//   void _showPartialBlockOverlay(BuildContext context) {
//     _overlayEntry = OverlayEntry(
//       builder: (context) => Positioned(
//         width: SizeConfig.screenWidth * 0.8,
//         child: CompositedTransformFollower(
//           link: _layerLink,
//           offset: Offset(-SizeConfig.screenWidth * 0.72, -110), // Adjust position of the overlay
//           showWhenUnlinked: false,
//           child: Material(
//             color: Colors.transparent,
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: AppColors.black.withValues(alpha: 0.7), // Black background
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 AppLocalizations.of(context)!.partiallyBlockedUserCanSeeYourProfileAndPostsButCannotConnectOrSendYouMessagesOnBlueEra,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                     color: Colors.white, fontSize: 16), // White text
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//
//     Overlay.of(context).insert(_overlayEntry!);
//   }
//
//   // Function to remove the overlay
//   void _removePartialBlockOverlay() {
//     _overlayEntry?.remove();
//     _overlayEntry = null;
//   }
//
//   // Function to display the overlay
//   void _showFullyBlockOverlay(BuildContext context) {
//     _overlayEntry2 = OverlayEntry(
//       builder: (context) => Positioned(
//         width: SizeConfig.screenWidth * 0.8,
//         child: CompositedTransformFollower(
//           link: _layerLink2,
//           offset: Offset(-SizeConfig.screenWidth * 0.72, -160), // Adjust position of the overlay
//           showWhenUnlinked: false,
//           child: Material(
//             color: Colors.transparent,
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: AppColors.black.withValues(alpha: 0.7), // Black background
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 AppLocalizations.of(context)!.fullyBlockedUserCannotSeeYourProfileOrPostsOnBlueEra,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                     color: Colors.white, fontSize: 16), // White text
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//
//     Overlay.of(context).insert(_overlayEntry2!);
//   }
//
//   // Function to remove the overlay
//   void _removeFullyBlockOverlay() {
//     _overlayEntry2?.remove();
//     _overlayEntry2 = null;
//   }
// }
//
// void openFullyBlockModal(BuildContext context, String userId) {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return Dialog(
//         backgroundColor: AppColors.white,
//         child: FullyBlockModalSheet(
//           userId: userId,
//         ),
//       );
//     },
//   );
// }
//
// class FullyBlockModalSheet extends StatefulWidget {
//   const FullyBlockModalSheet({
//     super.key,
//     required this.userId
//   });
//
//
//   final String userId;
//
//   @override
//   State<FullyBlockModalSheet> createState() => _FullyBlockModalSheetState();
// }
//
// class _FullyBlockModalSheetState extends State<FullyBlockModalSheet> {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//             color: AppColors.white,
//             border: Border.all(color: AppColors.grey66),
//             borderRadius: BorderRadius.circular(12)),
//         // height: screenHeight(context) * 0.25,
//         // width: screenWidth(context),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: CustomText(
//                     AppLocalizations.of(context)!.areYouSureYouWantToBlockThisUser,
//                     fontSize: SizeConfig.large,
//                     color: AppColors.mainTextColor,
//                     fontWeight: FontWeight.w700,
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   icon: const Icon(
//                     Icons.close_rounded,
//                     color: AppColors.mainTextColor,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             CustomBtn(
//               width: SizeConfig.screenWidth * 0.9,
//               title: AppLocalizations.of(context)!.blockUser,
//               isValidate: true,
//               onTap: () {
//                 Navigator.pop(context);
//                 Get.find<FeedController>().userBlocked(isPartialBlocked: false, otherUserId: widget.userId);
//               },
//             ),
//             SizedBox(height: SizeConfig.size10),
//             CustomBtn(
//                 width: SizeConfig.screenWidth * 0.9,
//                 title: AppLocalizations.of(context)!.goBack,
//                 onTap: () {
//                   Navigator.pop(context);
//                 },
//                 bgColor: AppColors.white,
//                 borderColor: AppColors.secondaryTextColor,
//                 textColor: AppColors.secondaryTextColor,
//             ),
//           ],
//         ));
//   }
// }