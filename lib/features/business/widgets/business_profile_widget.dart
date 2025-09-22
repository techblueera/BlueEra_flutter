// import 'dart:io';

// import 'package:BlueEra/core/api/apiService/api_keys.dart';
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/app_icon_assets.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/core/constants/snackbar_helper.dart';
// import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
// import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
// import 'package:BlueEra/features/business/visiting_card/view/business_details_edit_page_one.dart';
// import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
// import 'package:BlueEra/features/business/visiting_card/visiting_cardlist_screen.dart';
// import 'package:BlueEra/features/business/widgets/stats_card_widget.dart';
// import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
// import 'package:BlueEra/l10n/app_localizations.dart';
// import 'package:BlueEra/widgets/commom_textfield.dart';
// import 'package:BlueEra/widgets/common_box_shadow.dart';
// import 'package:BlueEra/widgets/common_dialog.dart';
// import 'package:BlueEra/widgets/custom_btn.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:BlueEra/widgets/local_assets.dart';
// import 'package:croppy/croppy.dart';
// import 'package:dio/dio.dart' as dio;
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../../../core/constants/shared_preference_utils.dart';
// import '../../../widgets/image_view_screen.dart' show ImageViewScreen;
// import '../visit_business_profile/view/visit_business_profile.dart';

// import 'package:BlueEra/core/constants/common_methods.dart';
// import 'package:BlueEra/widgets/visiting_card_helper.dart';

// class BusinessProfileWidget extends StatefulWidget {
//   BusinessProfileWidget({
//     super.key,
//   });

//   @override
//   State<BusinessProfileWidget> createState() => _BusinessProfileWidgetState();
// }

// class _BusinessProfileWidgetState extends State<BusinessProfileWidget> {
//   BusinessProfileDetails? details;
//   final listingDescriptionController = TextEditingController();
//   final controller = Get.find<ViewBusinessDetailsController>();

//   // Key to capture the visiting card preview widget as an image
//   final GlobalKey _visitingCardKey = GlobalKey();

//   @override
//   Widget build(BuildContext context) {
//     details = controller.businessProfileDetails?.data;

//     final appLocalizations = AppLocalizations.of(context);
//     final theme = Theme.of(context);
//     return Column(
//       children: [
//         ///COMPANY PROFILE VIEW ....
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(
//               width: 8,
//             ),
//             Padding(
//               padding: EdgeInsets.only(
//                   right: SizeConfig.size18, top: SizeConfig.size4),
//               child: Stack(
//                 alignment: Alignment.bottomRight,
//                 children: [
//                   Container(
//                     padding: EdgeInsets.all(SizeConfig.size3),

//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       border:
//                           Border.all(color: AppColors.primaryColor, width: 2),
//                     ),
//                     child: CircleAvatar(
//                       radius: 50,
//                       backgroundColor: Colors.grey,
//                       backgroundImage: details?.logo != null
//                           ? NetworkImage(details?.logo ?? "")
//                           : null,
//                       child: details?.logo == null
//                           ? CustomText(
//                               (details?.businessName ?? '')
//                                   .trim()
//                                   .split(' ')
//                                   .map((e) => e.isNotEmpty ? e[0] : '')
//                                   .take(2)
//                                   .join()
//                                   .toUpperCase(),
//                             )
//                           : null,
//                     ),
//                   ),

//                 ],
//               ),
//             ),
//             SizedBox(width: SizeConfig.size8),
//             Expanded(
//               child: Padding(
//                 padding: EdgeInsets.only(
//                     top: SizeConfig.size10, left: SizeConfig.size8),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Flexible(
//                           child: CustomText(
//                             "${details?.businessName ?? ''}",
//                             fontWeight: FontWeight.bold,
//                             fontSize: 22,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         SizedBox(width: SizeConfig.size8),
//                         GestureDetector(
//                           onTap: () {
//                             navigatePushTo(
//                                 context,
//                                 BusinessDetailsEditPageOne(
//                                     prevBusinessDetails: details));
//                           },
//                           child: CircleAvatar(
//                             radius: SizeConfig.size12,
//                             backgroundColor: AppColors.primaryColor,
//                             child: Icon(Icons.edit_outlined,
//                                 size: 14, color: Colors.white),
//                           ),
//                         ),
//                       ],
//                     ),
//                     CustomText(
//                       "${details?.natureOfBusiness}",
//                       fontWeight: FontWeight.w400,
//                       fontSize: 18,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     (details?.address == null || details?.address == '')
//                         ? SizedBox()
//                         : const SizedBox(
//                             height: 4,
//                           ),
//                     Row(
//                       children: [
//                         (details?.address == null || details?.address == '')
//                             ? SizedBox()
//                             : SvgPicture.asset(
//                                 height: 28,
//                                 width: 28,
//                                 "assets/svg/profile_location.svg",
//                               ),
//                         const SizedBox(
//                           width: 4,
//                         ),
//                         Expanded(
//                           child: CustomText(
//                             "${details?.address ?? ''}",
//                             fontSize: SizeConfig.size14,
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                     (details?.address == null || details?.address == '')
//                         ? SizedBox()
//                         : SizedBox(
//                             height: SizeConfig.size10,
//                           ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//         SizedBox(
//           height: SizeConfig.size10,
//         ),

//         (details?.businessIsVerified ?? false)
//             ? Container(
//                 padding: EdgeInsets.only(
//                     top: SizeConfig.size10, left: SizeConfig.size10),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: theme.colorScheme.inversePrimary,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.check,
//                         color: theme.colorScheme.onTertiary,
//                       ),
//                       const SizedBox(
//                         width: 4,
//                       ),
//                       CustomText(
//                         "Your business is verified.",
//                         color: theme.colorScheme.onTertiary,
//                         fontWeight: FontWeight.w500,
//                         fontSize: SizeConfig.medium,
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//             : Container(
//                 padding: EdgeInsets.only(
//                     top: SizeConfig.size10, left: SizeConfig.size10),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: theme.colorScheme.tertiary,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       SvgPicture.asset(
//                         height: 18,
//                         width: 18,
//                         "assets/svg/ac_verify_icon.svg",
//                       ),
//                       const SizedBox(
//                         width: 4,
//                       ),
//                       CustomText(
//                         "Your business is not verified ",
//                         color: theme.colorScheme.onTertiary,
//                         fontWeight: FontWeight.w500,
//                         fontSize: SizeConfig.medium,
//                         fontStyle: FontStyle.italic,
//                       ),
//                       Flexible(
//                         child: InkWell(
//                           onTap: () {
//                             // Navigator.push(
//                             //     context,
//                             //     MaterialPageRoute(
//                             //         builder: (context) =>
//                             //             BusinessVerificationScrn()));
//                             Get.to(() => VisitBusinessProfile(businessId: businessId));
//                           },
//                           child: CustomText(
//                             fontWeight: FontWeight.w900,
//                             "Verify Now",
//                             color: theme.colorScheme.onTertiary,
//                             fontStyle: FontStyle.italic,
//                             fontSize: SizeConfig.medium,
//                             decoration: TextDecoration.underline,
//                             decorationColor: theme.colorScheme.onTertiary,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//         SizedBox(
//           height: SizeConfig.size18,
//         ),

//         Row(
//           children: [
//             Expanded(
//               child: TextButton(
//                 style: TextButton.styleFrom(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(
//                           8), // Set your desired radius here
//                     ),
//                     side: BorderSide(color: theme.colorScheme.primary),
//                     backgroundColor: theme.colorScheme.primary),
//                 onPressed: null,
//                 // onPressed: _captureAndShareCard,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 4),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       SizedBox(
//                         width: SizeConfig.paddingXSmall,
//                       ),
//                       CustomText(
//                         "Your Orders",
//                         color: theme.colorScheme.surface,
//                         fontSize: 15,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(
//               width: SizeConfig.size12,
//             ),
//             Expanded(
//               child: TextButton(
//                 style: TextButton.styleFrom(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(
//                           8), // Set your desired radius here
//                     ),
//                     side: BorderSide(
//                       color: theme.colorScheme.primary,
//                     )),
//                 onPressed: () {
//                   _showVisitingCardDialog(context);
//                 },
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 4),
//                   child: CustomText(
//                     AppLocalizations.of(context)!.visitingCard,
//                     color: theme.colorScheme.primary,
//                     fontSize: 15,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ),

//             ),
//           ],
//         ),
//         SizedBox(
//           height: 16,
//         ),
//         StatsCard(
//           rating: details?.rating ?? 0,
//           dateOfInCorp:
//               "${details?.dateOfIncorporation?.date}/${details?.dateOfIncorporation?.month}/${details?.dateOfIncorporation?.year}",
//         ),
//         SizedBox(
//           height: 14,
//         ),

//         ///ABOUT YOUR BUSINESS...
//         Obx(() {
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   CustomText(
//                     letterSpacing: 0.4,
//                     "Business Description",
//                     fontSize: SizeConfig.large,
//                     fontWeight: FontWeight.bold,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   (controller.isListingDescriptionEdit.value)
//                       ? InkWell(
//                           onTap: () {
//                             listingDescriptionController.text = controller
//                                     .businessDescription.value
//                                     .toString();
//                             setState(() {
//                               controller.isListingDescriptionEdit.value =
//                                   !controller.isListingDescriptionEdit.value;
//                             });
//                           },
//                           child: SvgPicture.asset(
//                               height: 30, AppIconAssets.profile_pen_tool))
//                       : Row(
//                           children: [
//                             CustomBtn(
//                                 height: 24,
//                                 width: 56,
//                                 onTap: () {
//                                   setState(() {
//                                     controller.isListingDescriptionEdit.value =
//                                         !controller
//                                             .isListingDescriptionEdit.value;
//                                   });
//                                 },
//                                 title: "Cancel"),
//                             const SizedBox(
//                               width: 8,
//                             ),
//                             CustomBtn(
//                                 height: 24,
//                                 width: 56,
//                                 bgColor: theme.colorScheme.primary,
//                                 onTap: () async {
//                                   if (listingDescriptionController
//                                       .text.isNotEmpty) {
//                                     setState(() {
//                                       controller
//                                               .isListingDescriptionEdit.value =
//                                           !controller
//                                               .isListingDescriptionEdit.value;
//                                     });
//                                     Map<String, dynamic> params = {
//                                       ApiKeys.description:
//                                           "${listingDescriptionController.text}"
//                                     };
//                                     await controller
//                                         .updateBusinessDescription(params);
//                                   } else {
//                                     commonSnackBar(
//                                         message:
//                                             "Description can not be empty");
//                                   }
//                                 },
//                                 title: "Save"),
//                           ],
//                         )
//                 ],
//               ),
//               CustomText(
//                 appLocalizations?.tellCustomersWhatYouOffer,
//                 fontSize: SizeConfig.size12,
//                 color: Color.fromRGBO(38, 50, 56, 1),
//               ),
//               (controller.isListingDescriptionEdit.value)
//                   ? SizedBox()
//                   : const SizedBox(
//                       height: 4,
//                     ),
//               (controller.isListingDescriptionEdit.value &&
//                       controller.businessDescription != '')
//                   ? Container(
//                       decoration: BoxDecoration(
//                           color: theme.colorScheme.secondary,
//                           borderRadius: BorderRadius.circular(10)),
//                       width: double.infinity,
//                       margin: EdgeInsets.only(top: 16),
//                       padding:
//                           EdgeInsets.symmetric(horizontal: 13, vertical: 13),
//                       child: Obx(() {
//                         return CustomText(
//                           "${controller.businessDescription.value}",
//                           fontSize: SizeConfig.medium,
//                           color: Colors.black,
//                         );
//                       }),
//                     )
//                   : Container(
//                       margin: EdgeInsets.only(top: 6),
//                       decoration: BoxDecoration(),
//                       child: CommonTextField(
//                         validator: null,
//                         borderWidth: 0,
//                         borderColor: Colors.transparent,
//                         hintText: "Add your business details",
//                         textEditController: listingDescriptionController,
//                         maxLine: 5,
//                         isValidate: false,
//                         inputLength: AppConstants.inputCharterLimit200,

//                       ),
//                     ),
//               Obx(() {
//                 return SizedBox(
//                   height: (controller.isListingDescriptionEdit.value)
//                       ? 8
//                       : SizeConfig.size18,
//                 );
//               }),
//             ],
//           );
//         }),

//         ///STORE IMAGE...
//         const SizedBox(
//           height: 18,
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             CustomText(
//               letterSpacing: 0.6,
//               "Your live store pictures",
//               fontSize: SizeConfig.large,
//               fontWeight: FontWeight.bold,
//               overflow: TextOverflow.ellipsis,
//             ),
//             // (controller.imgUploadL2.isNotEmpty) ?
//             // Row(
//             //   children: [
//             //     CustomBtn(
//             //         height: 24,
//             //         width: 56,
//             //         onTap: () {
//             //           setState(() {
//             //             controller.imgUploadL2.clear();
//             //           });
//             //         }, title: "Cancel"),
//             //     const SizedBox(
//             //       width: 8,
//             //     ),
//             //     CustomBtn(
//             //         height: 24,
//             //         width: 56,
//             //         bgColor: theme.colorScheme.primary,
//             //         onTap: () {
//             //         },
//             //         title: "Save"),
//             //   ],
//             // ) :
//             // InkWell(
//             //     onTap: () {},
//             //     child: SvgPicture.asset(AppIconAssets.profile_pen_tool))
//           ],
//         ),
//         Row(
//           children: [
//             CustomText(
//               textAlign: TextAlign.left,
//               appLocalizations?.minThreeImg,
//               fontSize: SizeConfig.size12,
//               color: Color.fromRGBO(38, 50, 56, 1),
//             ),
//           ],
//         ),

//         SizedBox(
//           height: SizeConfig.size10,
//         ),
//         SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: Row(
//             children: [
//               ///API
//               (details?.livePhotos?.isNotEmpty ?? false)
//                   ? Row(
//                       children: List<Widget>.generate(
//                           (details?.livePhotos?.length ?? 0), (apiIndex) {
//                         return _APIbuildImageContainer(
//                             details?.livePhotos?[apiIndex],
//                             apiIndex,
//                             false,
//                             apiIndex,
//                             theme,
//                             controller);
//                       }),
//                     )
//                   : SizedBox(),

//               // // ///UPLOADED
//               // Row(
//               //   children:
//               //   List.generate(controller.imgUploadL2.length, (uploadIndex) {
//               //     return _buildImageContainer(
//               //         controller.imgUploadL2[uploadIndex], uploadIndex, false,controller);
//               //   }),
//               // ),
//               //
//               ///LOCAL
//               Row(
//                 children: List<Widget>.generate(
//                     controller.imgLocalL3.length, (localIndex) {
//                   return _buildImageContainer(controller.imgLocalL3[localIndex],
//                       localIndex, false, controller);
//                 }),
//               ),

//               ///EMPTY.....
//               (3 -
//                               (details?.livePhotos?.length ?? 0) -
//                               // controller.imgUploadL2.length -
//                               controller.imgLocalL3.length) +
//                           controller.imgDeleteL3.length >
//                       0
//                   ? Row(
//                       children: List<Widget>.generate(
//                           (3 -
//                               (details?.livePhotos?.length ?? 0) -
//                               // controller.imgUploadL2.length -
//                               controller.imgLocalL3.length), (index) {
//                         return _buildImageContainer("", 0, false, controller);
//                       }),
//                     )
//                   : SizedBox(),
//             ],
//           ),
//         ),

//         if ((details?.businessLocation?.lat != null &&
//             details?.businessLocation?.lat != 0) &&
//             (details?.businessLocation?.lon != null &&
//                 details?.businessLocation?.lon != 0)) ...[
//           SizedBox(
//             height: SizeConfig.size20,
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Align(
//                 alignment: Alignment.centerLeft,
//                 child: CustomText(
//                   "Your business live location",
//                   fontSize: SizeConfig.large,
//                   fontWeight: FontWeight.bold,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               // InkWell(
//               //     onTap: () {},
//               //     child: SvgPicture.asset(AppIconAssets.profile_pen_tool))
//             ],
//           ),
//           Align(
//             alignment: Alignment.centerLeft,
//             child: CustomText(
//               "Your store’s map location",
//               fontSize: SizeConfig.medium,
//               color: theme.colorScheme.outline,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           BusinessLocationWidget(
//               latitude: (details?.businessLocation?.lat?.toDouble() ?? 0.0),
//               longitude: (details?.businessLocation?.lon?.toDouble() ?? 0.0),
//               businessName: details?.businessName ?? "",
//               isTitleShow: false),
//         ],
//         SizedBox(
//           height: SizeConfig.size20,
//         ),
//         Row(
//           children: [
//             Expanded(
//               child: Container(
//                 width: SizeConfig.screenWidth,
//                 height: 2,
//                 color: Colors.black,
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
//               child: CustomText(
//                 color: Colors.black,
//                 appLocalizations?.listYourProductServices,
//                 fontSize: SizeConfig.large,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             Expanded(
//               child: Container(
//                 width: SizeConfig.screenWidth,
//                 height: 2,
//                 color: Colors.black,
//               ),
//             ),
//           ],
//         ),
//         SizedBox(
//           height: SizeConfig.size10,
//         ),
//         Container(
//           decoration: BoxDecoration(
//               boxShadow: AppShadows.bottomAndTopShadow,
//               color: theme.colorScheme.surface,
//               borderRadius: BorderRadius.circular(10)),
//           padding: EdgeInsets.symmetric(
//               horizontal: SizeConfig.size10, vertical: SizeConfig.size10),
//           child: Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     CustomText(
//                       appLocalizations?.createStoreSections,
//                       fontSize: SizeConfig.small,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     CustomText(
//                       "Organize your products into 👔 Men • 👗 Women • 🧒 Kids. Make shopping easier for your customers!",
//                       fontSize: SizeConfig.extraSmall,
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(
//                 width: SizeConfig.size20,
//               ),
//               LocalAssets(imagePath: AppIconAssets.store_bg)
//             ],
//           ),
//         ),
//         SizedBox(
//           height: SizeConfig.size20,
//         ),
//       ],
//     );
//   }

//   void _showVisitingCardDialog(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.grey,
//       builder: (context) {
//         return SizedBox(
//           height: Get.height * 0.8,
//           child: Padding(
//             padding: const EdgeInsets.only(top: 12.0),
//             child: SingleChildScrollView(
//               child: Column(children: [
//                 Center(
//                   child: Container(
//                     height: 4,
//                     width: 100,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(4),
//                       color: AppColors.white,
//                     ),
//                   ),
//                 ),
//                 SizedBox(
//                   height: 12,
//                 ),
//                 Container(
//                     // color: AppColors.pinkE2,
//                     padding: EdgeInsets.all(SizeConfig.size12),
//                     child: SingleChildScrollView(
//                         child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // SizedBox(height: SizeConfig.size12),

//                         // Theme selector (4 themes) as pill chips
//                         // Row(
//                         //   mainAxisSize: MainAxisSize.max,
//                         //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         //   children: [
//                         //     CustomText(
//                         //       'Visiting Card',
//                         //       fontWeight: FontWeight.w600,
//                         //       fontSize: SizeConfig.size14,
//                         //       color: AppColors.black,
//                         //     ),
//                         //     InkWell(
//                         //       onTap: () {
//                         //         Get.back();
//                         //         Get.to(() => VisitingCardlistScreen(),
//                         //             arguments: details);
//                         //         // Get.to(()=>VisitingCardlistScreen());
//                         //       },
//                         //       child: CustomText('View All',
//                         //           fontWeight: FontWeight.w600,
//                         //           fontSize: SizeConfig.size14,
//                         //           color: AppColors.black),
//                         //     ),
//                         //   ],
//                         // ),

//                         Stack(
//                           children: [
//                             VisitingCardPreview(details: details),
//                             Positioned(
//                               bottom: 10,
//                               right: 10,
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                     color: AppColors.primaryColor,
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: AppColors.white,
//                                         blurRadius: 6,
//                                         spreadRadius: 2
//                                       )
//                                     ],
//                                     borderRadius: BorderRadius.circular(12)),
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(8.0),
//                                   child: Icon(
//                                     Icons.ios_share,
//                                     color: AppColors.white,
//                                   ),
//                                 ),
//                               ),
//                             )
//                           ],
//                         ),
//                         SizedBox(height: SizeConfig.size20),
//                         Column(
//                           children: [
//                             Stack(
//                               children: [
//                                 buildCard1(details!),
//                                 Positioned(
//                                   bottom: 10,
//                                   right: 10,
//                                   child: InkWell(
//                                     onTap: () {

//                                     },
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                           color: AppColors.primaryColor,
//                                           boxShadow: [
//                                             BoxShadow(
//                                                 color: AppColors.white,
//                                                 blurRadius: 6,
//                                                 spreadRadius: 2
//                                             )
//                                           ],
//                                           borderRadius: BorderRadius.circular(12)),
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(8.0),
//                                         child: Icon(
//                                           Icons.ios_share,
//                                           color: AppColors.white,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               ],
//                             ),
//                             SizedBox(
//                               height: 20,
//                             ),
//                             Stack(
//                               children: [
//                                 buildCard2(details!),
//                                 Positioned(
//                                   bottom: 10,
//                                   right: 10,
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                         color: AppColors.primaryColor,
//                                         boxShadow: [
//                                           BoxShadow(
//                                               color: AppColors.white,
//                                               blurRadius: 6,
//                                               spreadRadius: 2
//                                           )
//                                         ],
//                                         borderRadius: BorderRadius.circular(12)),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(8.0),
//                                       child: Icon(
//                                         Icons.ios_share,
//                                         color: AppColors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               ],
//                             ),
//                             SizedBox(
//                               height: 20,
//                             ),
//                             Stack(
//                               children: [
//                                 buildCard3(details!),
//                                 Positioned(
//                                   bottom: 10,
//                                   right: 10,
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                         color: AppColors.primaryColor,
//                                         boxShadow: [
//                                           BoxShadow(
//                                               color: AppColors.white,
//                                               blurRadius: 6,
//                                               spreadRadius: 2
//                                           )
//                                         ],
//                                         borderRadius: BorderRadius.circular(12)),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(8.0),
//                                       child: Icon(
//                                         Icons.ios_share,
//                                         color: AppColors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               ],
//                             ),
//                             SizedBox(
//                               height: 20,
//                             ),
//                             Stack(
//                               children: [
//                                 buildCard4(details!),
//                                 Positioned(
//                                   bottom: 10,
//                                   right: 10,
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                         color: AppColors.primaryColor,
//                                         boxShadow: [
//                                           BoxShadow(
//                                               color: AppColors.white,
//                                               blurRadius: 6,
//                                               spreadRadius: 2
//                                           )
//                                         ],
//                                         borderRadius: BorderRadius.circular(12)),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(8.0),
//                                       child: Icon(
//                                         Icons.ios_share,
//                                         color: AppColors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               ],
//                             ),
//                             SizedBox(
//                               height: 20,
//                             ),
//                             Stack(
//                               children: [
//                                 buildCard5(details!),
//                                 Positioned(
//                                   bottom: 10,
//                                   right: 10,
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                         color: AppColors.primaryColor,
//                                         boxShadow: [
//                                           BoxShadow(
//                                               color: AppColors.white,
//                                               blurRadius: 6,
//                                               spreadRadius: 2
//                                           )
//                                         ],
//                                         borderRadius: BorderRadius.circular(12)),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(8.0),
//                                       child: Icon(
//                                         Icons.ios_share,
//                                         color: AppColors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               ],
//                             ),
//                             SizedBox(
//                               height: 20,
//                             ),
//                             Stack(
//                               children: [
//                                 buildCard6(details!),
//                                 Positioned(
//                                   bottom: 10,
//                                   right: 10,
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                         color: AppColors.primaryColor,
//                                         boxShadow: [
//                                           BoxShadow(
//                                               color: AppColors.white,
//                                               blurRadius: 6,
//                                               spreadRadius: 2
//                                           )
//                                         ],
//                                         borderRadius: BorderRadius.circular(12)),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(8.0),
//                                       child: Icon(
//                                         Icons.ios_share,
//                                         color: AppColors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               ],
//                             ),
//                             SizedBox(
//                               height: 20,
//                             ),
//                             Stack(
//                               children: [
//                                 buildCard7(details!),
//                                 Positioned(
//                                   bottom: 10,
//                                   right: 10,
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                         color: AppColors.primaryColor,
//                                         boxShadow: [
//                                           BoxShadow(
//                                               color: AppColors.white,
//                                               blurRadius: 6,
//                                               spreadRadius: 2
//                                           )
//                                         ],
//                                         borderRadius: BorderRadius.circular(12)),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(8.0),
//                                       child: Icon(
//                                         Icons.ios_share,
//                                         color: AppColors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               ],
//                             ),
//                             SizedBox(
//                               height: 20,
//                             ),
//                             Stack(
//                               children: [
//                                 buildCard8(details!),
//                                 Positioned(
//                                   bottom: 10,
//                                   right: 10,
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                         color: AppColors.primaryColor,
//                                         boxShadow: [
//                                           BoxShadow(
//                                               color: AppColors.white,
//                                               blurRadius: 6,
//                                               spreadRadius: 2
//                                           )
//                                         ],
//                                         borderRadius: BorderRadius.circular(12)),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(8.0),
//                                       child: Icon(
//                                         Icons.ios_share,
//                                         color: AppColors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               ],
//                             ),
//                             SizedBox(
//                               height: 20,
//                             ),
//                             Stack(
//                               children: [
//                                 buildCard9(details!),
//                                 Positioned(
//                                   bottom: 10,
//                                   right: 10,
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                         color: AppColors.primaryColor,
//                                         boxShadow: [
//                                           BoxShadow(
//                                               color: AppColors.white,
//                                               blurRadius: 6,
//                                               spreadRadius: 2
//                                           )
//                                         ],
//                                         borderRadius: BorderRadius.circular(12)),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(8.0),
//                                       child: Icon(
//                                         Icons.ios_share,
//                                         color: AppColors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               ],
//                             ),
//                             SizedBox(
//                               height: 20,
//                             ),
//                             Stack(
//                               children: [
//                                 buildCard10(details!),
//                                 Positioned(
//                                   bottom: 10,
//                                   right: 10,
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                         color: AppColors.primaryColor,
//                                         boxShadow: [
//                                           BoxShadow(
//                                               color: AppColors.white,
//                                               blurRadius: 6,
//                                               spreadRadius: 2
//                                           )
//                                         ],
//                                         borderRadius: BorderRadius.circular(12)),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(8.0),
//                                       child: Icon(
//                                         Icons.ios_share,
//                                         color: AppColors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               ],
//                             ),
//                             SizedBox(
//                               height: 20,
//                             ),
//                             Stack(
//                               children: [
//                                 buildCard11(details!),
//                                 Positioned(
//                                   bottom: 10,
//                                   right: 10,
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                         color: AppColors.primaryColor,
//                                         boxShadow: [
//                                           BoxShadow(
//                                               color: AppColors.white,
//                                               blurRadius: 6,
//                                               spreadRadius: 2
//                                           )
//                                         ],
//                                         borderRadius: BorderRadius.circular(12)),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(8.0),
//                                       child: Icon(
//                                         Icons.ios_share,
//                                         color: AppColors.white,
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               ],
//                             ),
//                           ],
//                         )
//                         //
//                         //                   // Footer actions
//                         //                   Align(
//                         //                     alignment: Alignment.center,
//                         //                     child: ElevatedButton.icon(
//                         //                       style: ElevatedButton.styleFrom(
//                         //                         shape: const StadiumBorder(),
//                         //                         // backgroundColor: accentChip, // per theme
//                         //                         foregroundColor: Colors.white,
//                         //                       ),
//                         //                       onPressed: () {
//                         //                         Navigator.of(context).maybePop();
//                         //                       },
//                         //                       icon: const Icon(Icons.ios_share,color: AppColors.black,),
//                         //                       label: Text(
//                         //                           AppLocalizations.of(context)!.shareVisitingCard,style: TextStyle(color: AppColors.black),
//                         //                           ),
//                         //                     ),
//                         //                   ),
//                       ],
//                     )))
//               ]),
//             ),
//           ),
//         );
//       },
//     );

//     //
//     // showDialog(
//     //   context: context,
//     //   barrierDismissible: true,
//     //   builder: (ctx) {
//     //     VisitingCardTheme selected = VisitingCardTheme.theme1;
//     //     return StatefulBuilder(
//     //       builder: (ctx, setState) {
//     //         return Dialog(
//     //           backgroundColor: Colors.white,
//     //           insetPadding: EdgeInsets.symmetric(
//     //             // small margin from screen sides
//     //             horizontal: SizeConfig.size12,
//     //             vertical: SizeConfig.size12,
//     //           ),
//     //           shape: RoundedRectangleBorder(
//     //               borderRadius: BorderRadius.circular(16)),
//     //           child:
//     //           Container(
//     //             // color: AppColors.pinkE2,
//     //             padding: EdgeInsets.all(SizeConfig.size12),
//     //             child: SingleChildScrollView(
//     //               child: Column(
//     //                 mainAxisSize: MainAxisSize.min,
//     //                 crossAxisAlignment: CrossAxisAlignment.start,
//     //                 children: [
//     //                   SizedBox(height: SizeConfig.size12),
//     //
//     //                   // Theme selector (4 themes) as pill chips
//     //                   Row(
//     //                     mainAxisSize: MainAxisSize.max,
//     //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     //                     children: [
//     //                       CustomText(
//     //                         'Visiting Card',
//     //                         fontWeight: FontWeight.w600,
//     //                         fontSize: SizeConfig.size14,
//     //                         color: AppColors.black,
//     //                       ),
//     //                       InkWell(
//     //                         onTap: () {
//     //                           Get.back();
//     //                           Get.to(()=>VisitingCardlistScreen(),arguments:details );
//     //                           // Get.to(()=>VisitingCardlistScreen());
//     //                         },
//     //                         child: CustomText('View All',
//     //                             fontWeight: FontWeight.w600,
//     //                             fontSize: SizeConfig.size14,
//     //                             color: AppColors.black),
//     //                       ),
//     //
//     //                     ],
//     //                   ),
//     //
//     //                   SizedBox(height: SizeConfig.size4),
//     //
//     //                   // Live visiting card preview
//     //                   VisitingCardPreview( details: details),
//     //
//     //                   SizedBox(height: SizeConfig.size4),
//     //
//     //                   // Footer actions
//     //                   Align(
//     //                     alignment: Alignment.center,
//     //                     child: ElevatedButton.icon(
//     //                       style: ElevatedButton.styleFrom(
//     //                         shape: const StadiumBorder(),
//     //                         // backgroundColor: accentChip, // per theme
//     //                         foregroundColor: Colors.white,
//     //                       ),
//     //                       onPressed: () {
//     //                         Navigator.of(ctx).maybePop();
//     //                       },
//     //                       icon: const Icon(Icons.ios_share,color: AppColors.black,),
//     //                       label: Text(
//     //                           AppLocalizations.of(context)!.shareVisitingCard,style: TextStyle(color: AppColors.black),
//     //                           ),
//     //                     ),
//     //                   ),
//     //                 ],
//     //               ),
//     //             ),
//     //           ),
//     //         );
//     //       },
//     //     );
//     //   },
//     // );
//   }

//   Future<void> _openMap(double lat, double lng) async {
//     final Uri googleMapUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");

//     if (await canLaunchUrl(googleMapUrl)) {
//       await launchUrl(googleMapUrl, mode: LaunchMode.externalApplication);
//     } else {
//       throw "Could not open Google Maps";
//     }
//   }

//   Widget _themeChip({
//     required String label,
//     required bool selected,
//     required VoidCallback onTap,
//     required ThemeData theme,
//     required Color selectedColor,
//     required Color unselectedColor,
//     required Color dotColor,
//     required bool isDarkDialog,
//   }) {

//     // small dot
// //     final textScale = MediaQuery.textScaleFactorOf(context);
// // final baseLabelSize = SizeConfig.small; // same you use for the label
// // final dotSize = (baseLabelSize * textScale * 0.9).clamp(8.0, 12.0);

// // bigger dot
// final textScale = MediaQuery.textScaleFactorOf(context);
// final baseLabelSize = SizeConfig.small11; // tie to your label size
// final dotSize = (baseLabelSize * textScale * 1.5).clamp(16.0, 16.0);

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(24),
//       child: Container(
//         // inside _themeChip
// margin: EdgeInsets.symmetric(horizontal: SizeConfig.size4, vertical: SizeConfig.size4),

// padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8, vertical: SizeConfig.size8), // was size10
//         decoration: BoxDecoration(
//           color: selected
//               ? selectedColor
//               : (isDarkDialog ? Colors.white.withOpacity(0.06) : Colors.transparent),
//           borderRadius: BorderRadius.circular(24),
//           border: Border.all(
//             color: selected
//                 ? selectedColor
//                 : (isDarkDialog ? Colors.white38 : unselectedColor),
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             // color dot representing theme card color
//             Container(
//   width: dotSize,
//   height: dotSize,
//   decoration: BoxDecoration(
//     color: dotColor,
//     shape: BoxShape.circle,
//     border: Border.all(
//       width: 1.2,
//       color: isDarkDialog
//           ? Colors.white.withOpacity(0.6)
//           : Colors.black.withOpacity(0.2),
//     ),
//   ),
// ),

//             CustomText(
//               label,
//               color: selected
//                   ? Colors.white
//                   : (isDarkDialog ? Colors.white70 : unselectedColor),
//               fontWeight: FontWeight.w700,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               fontSize: SizeConfig.small11, // smaller text for responsiveness
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildImageContainer(String? imagePath, int index,
//       bool uploadFromGallery, ViewBusinessDetailsController controller) {
//     return Stack(
//       children: [
//         GestureDetector(
//           onTap: () async {
//             if (imagePath == "") {
//               commonConformationDialog(
//                   context: context,
//                   barrierDismissible: false,
//                   text: "Photo should be selected from actual business location",
//                   confirmCallback: () {
//                     Get.back();
//                     selectedFromCamera(context);
//                   },
//                   cancelCallback: () {
//                     Get.back();
//                   });
//             }
//             else{
//               navigatePushTo(
//                 context,
//                 ImageViewScreen(
//                   subTitle: '',
//                   appBarTitle: AppLocalizations.of(context)!.imageViewer,
//                   imageUrls: [imagePath!],
//                   initialIndex: index,
//                 ),
//               );
//             }
//           },
//           child: Container(
//             height: SizeConfig.screenWidth * .30,
//             width: SizeConfig.screenWidth * .30,
//             margin: EdgeInsets.only(
//                 right: SizeConfig.size6, bottom: 8, left: 4, top: 4),
//             decoration: BoxDecoration(
//               color: Color.fromRGBO(237, 237, 237, 1),
//               borderRadius: BorderRadius.circular(10),
//               image: imagePath != null
//                   ? DecorationImage(
//                       image: imagePath.startsWith("http")
//                           ? NetworkImage(imagePath) as ImageProvider
//                           : FileImage(File(imagePath)),
//                       fit: BoxFit.cover,
//                     )
//                   : null,
//             ),
//             child: imagePath == ""
//                 ? Center(
//                     child: SvgPicture.asset(AppIconAssets.profile_camera_pic),
//                   )
//                 : null,
//           ),
//         ),
//         if (imagePath != "")
//           Positioned(
//             top: 8,
//             right: 18,
//             child: Container(
//               margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
//               decoration: BoxDecoration(
//                   color: Colors.white, borderRadius: BorderRadius.circular(50)),
//               child: GestureDetector(
//                 onTap: () {
//                   Map<String, dynamic> data = {ApiKeys.image_url: imagePath};
//                   controller.deleteLiveStoreImage(data);
//                 },
//                 child: const Icon(
//                   Icons.close,
//                   color: Colors.grey,
//                   size: 20,
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   ///UPDATE BUSINESS IMAGES....
//   saveBusinessImages(String imagePath, List<int> deleteProfileId,
//       ViewBusinessDetailsController controller) async {
//     dio.MultipartFile? imageByPart;

//     String fileName = imagePath.split('/').last;
//     imageByPart =
//         await dio.MultipartFile.fromFile(imagePath, filename: fileName);

//     Map<String, dynamic> params = {ApiKeys.category_image: imageByPart};

//     controller.uploadLiveStoreImage(params);
//     await Future.delayed(Duration(seconds: 2));
//     controller.imgDeleteL3.clear();
//     // viewBusinessDetailsController.imgUploadL2.addAll(viewBusinessDetailsController.imgLocalL3);
//   }

//   Widget _APIbuildImageContainer(
//       String? imagePath,
//       int index,
//       bool uploadFromGallery,
//       int indexDelete,
//       ThemeData theme,
//       ViewBusinessDetailsController controller) {
//     return Stack(
//       children: [
//         Container(
//           height: SizeConfig.screenWidth * .30,
//           width: SizeConfig.screenWidth * .30,
//           margin: EdgeInsets.only(right: SizeConfig.size10),
//           decoration: BoxDecoration(
//             color: theme.colorScheme.surface,
//             borderRadius: BorderRadius.circular(8),
//             image: imagePath != null
//                 ? DecorationImage(
//                     image: imagePath.startsWith("http")
//                         ? NetworkImage(imagePath) as ImageProvider
//                         : FileImage(File(imagePath)),
//                     fit: BoxFit.cover,
//                   )
//                 : null,
//           ),
//           child: imagePath == null
//               ? const Center(
//                   child: Icon(
//                     Icons.camera_alt,
//                     color: Colors.white,
//                     size: 32,
//                   ),
//                 )
//               : null,
//         ),
//         if (imagePath != null)
//           Positioned(
//             top: 8,
//             right: 18,
//             child: Container(
//               decoration: BoxDecoration(
//                   color: Colors.white, borderRadius: BorderRadius.circular(50)),
//               child: GestureDetector(
//                 onTap: () {
//                   Map<String, dynamic> data = {ApiKeys.image_url: imagePath};
//                   controller.deleteLiveStoreImage(data);
//                   // if (!viewBusinessDetailsController.imgDeleteL3.contains(indexDelete)) {
//                   //   viewBusinessDetailsController.imgDeleteL3.add(indexDelete);
//                   // }
//                 },
//                 child: const Icon(
//                   Icons.close,
//                   color: Colors.grey,
//                   size: 20,
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Future<void> selectedFromCamera(BuildContext context) async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.camera);

//     if (pickedFile != null) {
//       final croppedPath = await SelectProfilePictureDialog.cropImage(
//           context,
//           pickedFile.path,
//           cropAspectRatio: CropAspectRatio(width: 9, height: 16)
//       );
//       if (croppedPath.isNotEmpty) {
//         setState(() {
//           // viewBusinessDetailsController.imgUploadL2.add(imgStr);
//           saveBusinessImages(
//               croppedPath, controller.imgDeleteL3, controller);

//           // Send updated list to the parent widget
//         });
//       }

//     }
//   }

// }

// enum VisitingCardTheme { theme1, theme2, theme3, theme4 }

// class VisitingCardPreview extends StatelessWidget {
//   final VisitingCardTheme theme;
//   final BusinessProfileDetails? details;

//   const _VisitingCardPreview({required this.theme, required this.details});

//   @override
//   Widget build(BuildContext context) {
//     // Colors per theme (card colors). Theme 1 per spec: card #273747
//     late final Color bg; // card background
//     late final Color panel; // avatar backing
//     late final Color textPrimary;
//     late final Color textSecondary;
//     late final Color dividerColor;
//     late final Color iconAccent; // icon highlight color

//     switch (theme) {
//       case VisitingCardTheme.theme1:
//         bg = const Color(0xFF273747); // card
//         panel = const Color(0xFF31475A);
//         textPrimary = Colors.white;
//         textSecondary = Colors.white70;
//         dividerColor = Colors.white24;
//         iconAccent = Colors.white70;
//         break;
//       case VisitingCardTheme.theme2:
//         bg = Colors.white;
//         panel = const Color(0xFFF0F3F6);
//         textPrimary = const Color(0xFF0E141B);
//         textSecondary = const Color(0xFF5A6B7A);
//         dividerColor = const Color(0x1F000000);
//         iconAccent = const Color(0xFF5A6B7A);
//         break;
//       case VisitingCardTheme.theme3:
//         bg = const Color(0xFF145A32); // Darker green card
//         panel = const Color(0xFF0E3D22);
//         textPrimary = Colors.white;
//         textSecondary = Colors.white70;
//         dividerColor = Colors.white24;
//         iconAccent = const Color(0xFFA9DFBF); // Mint accent for icons
//         break;
//       case VisitingCardTheme.theme4:
//         // Silver theme (darker so it doesn't look white)
//         bg = const Color(0xFFE0E0E0);        // silver card (Material Grey 300)
//         panel = const Color(0xFFBDBDBD);     // avatar backing (Grey 400)
//         textPrimary = const Color(0xFF1A1A1A);
//         textSecondary = const Color(0xFF5C5C5C);
//         dividerColor = const Color(0xFF9E9E9E); // slightly darker divider
//         iconAccent = const Color(0xFF9E9E9E);
//         break;
//     }

//     return Container(
//       width: double.infinity, // fill dialog width
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: AppShadows.bottomAndTopShadow,
//       ),
//       padding: EdgeInsets.all(SizeConfig.size16),
//       child: Container(
//         decoration: BoxDecoration(
//           color: bg,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: IntrinsicHeight(
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Left: avatar + company block
//               Expanded(
//                 flex: 11,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Avatar
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         CircleAvatar(
//                           radius: 50,
//                           backgroundImage: (details?.logo != null && (details?.logo ?? '').isNotEmpty)
//                               ? NetworkImage(details?.logo ?? '')
//                               : null,
//                           backgroundColor: panel,
//                           child: (details?.logo == null || (details?.logo ?? '').isEmpty)
//                               ? CustomText(
//                                   (details?.businessName ?? 'B')
//                                       .trim()
//                                       .split(' ')
//                                       .map((e) => e.isNotEmpty ? e[0] : '')
//                                       .take(2)
//                                       .join()
//                                       .toUpperCase(),
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                 )
//                               : null,
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: SizeConfig.size12),

//                     // Company name and tagline
//                     CustomText(
//                       details?.businessName ?? 'BLUE (OPC) PVT LTD',
//                       fontWeight: FontWeight.w800,
//                       fontSize: SizeConfig.size18,
//                       color: textPrimary,
//                     ),
//                     SizedBox(height: SizeConfig.size6),
//                     CustomText(
//                       details?.natureOfBusiness ?? 'Consultant Services',
//                       color: textSecondary,
//                       fontSize: SizeConfig.medium,
//                     ),

//                     SizedBox(height: SizeConfig.size12),

//                     // Short description (optional)
//                     CustomText(
//                     details?.businessDescription ??  'to unique custom designs, we offer something special for every occasion.',
//                       color: textSecondary,
//                       fontSize: SizeConfig.small11,
//                     ),
//                   ],
//                 ),
//               ),

//               // Vertical divider
//                 Padding(
//         padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12), // horizontal padding
//         child: VerticalDivider(
//           color: dividerColor,
//           thickness: 1,
//           width: 1,                      // divider line width; spacing handled by Padding
//           indent: SizeConfig.size8,      // top padding
//           endIndent: SizeConfig.size8,   // bottom padding
//         ),
//       ),

//               // Right: person and contact info
//               Expanded(
//                 flex: 10,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     CustomText(
//                       details?.ownerDetails?.first.name ?? 'Manish Kumar',
//                       fontWeight: FontWeight.w700,
//                       fontSize: SizeConfig.size16,
//                       color: textPrimary,
//                     ),
//                     SizedBox(height: SizeConfig.size2),
//                     CustomText(
//                       details?.ownerDetails?.first.role_in_business ?? 'Director',
//                       color: textSecondary,
//                       fontSize: SizeConfig.small,
//                     ),
//                     SizedBox(height: SizeConfig.size10),

//                     _infoRow(Icons.phone, details?.businessNumber?.officeMobNo?.number.toString() ?? '982880009', textPrimary, textSecondary, iconAccent),
//                     SizedBox(height: SizeConfig.size8),
//                     _infoRow(Icons.mail_outline, details?.ownerDetails?.first.email ?? 'info@bluehr.com', textPrimary, textSecondary, iconAccent),
//                     SizedBox(height: SizeConfig.size8),
//                     _infoRow(Icons.public, details?.websiteUrl ?? 'www.vikash.bluehr.com', textPrimary, textSecondary, iconAccent, ellipsis: true),

//                     SizedBox(height: SizeConfig.size10),
//                     CustomText(
//                       details?.address ?? '115, Road No 04 BN Ready Nagar Address abcdefgh1234567890 nmae Nagar\nHyderabad 834553',
//                       color: textSecondary,
//                       fontSize: SizeConfig.small,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Row _infoRow(IconData icon, String text, Color textPrimary, Color textSecondary, Color iconColor, {bool ellipsis = false}) {
//     return Row(
//       children: [
//         Icon(icon, size: 18, color: iconColor),
//         SizedBox(width: 6),
//         Expanded(
//           child: Text(
//             text,
//             maxLines: ellipsis ? 1 : null,
//             overflow: ellipsis ? TextOverflow.ellipsis : TextOverflow.visible,
//             style: TextStyle(color: textPrimary, fontSize: SizeConfig.medium),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/business_profile_header.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_details_edit_page_one.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/business/visiting_card/visiting_cardlist_screen.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/visiting_card_helper.dart';
import 'package:croppy/croppy.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/shared_preference_utils.dart';
import 'package:dio/dio.dart' as dioObj;

import '../visit_business_profile/view/visit_business_profile_new.dart';

class BusinessProfileWidget extends StatefulWidget {
  BusinessProfileWidget({
    super.key,
  });

  @override
  State<BusinessProfileWidget> createState() => _BusinessProfileWidgetState();
}

class _BusinessProfileWidgetState extends State<BusinessProfileWidget> {
  BusinessProfileDetails? details;
  final listingDescriptionController = TextEditingController();
  final controller = Get.find<ViewBusinessDetailsController>();
  final viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();

  @override
  Widget build(BuildContext context) {
    details = controller.businessProfileDetails?.data;

    final appLocalizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        ///COMPANY PROFILE VIEW ....
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 8,
            ),

            ///UPLOAD PROFILE....
            CommonProfileImage(
              imagePath: viewBusinessDetailsController.imagePath?.value ?? "",
              onImageUpdate: (image) async {
                viewBusinessDetailsController.imagePath?.value = image;
                dioObj.MultipartFile? imageByPart;
                // if (viewBusinessDetailsController.isImageUpdated.value) {
                if (viewBusinessDetailsController.imagePath?.value.isNotEmpty ??
                    false) {
                  String fileName = viewBusinessDetailsController
                          .imagePath?.value
                          .split('/')
                          .last ??
                      "";
                  imageByPart = await dioObj.MultipartFile.fromFile(
                      viewBusinessDetailsController.imagePath?.value ?? "",
                      filename: fileName);
                }
                // }
                dynamic reqData = {
                  ApiKeys.businessId: businessId,
                  ApiKeys.logo_image: imageByPart,
                };

                await Get.find<ViewBusinessDetailsController>()
                    .updateBusinessDetails(reqData);
              },
              dialogTitle: 'Upload Business Logo',
            ),
            SizedBox(width: SizeConfig.size20),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    top: SizeConfig.size10, left: SizeConfig.size8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: CustomText(
                            "${details?.businessName ?? ''}",
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: SizeConfig.size10,
                        ),
                        GestureDetector(
                          onTap: () {
                            navigatePushTo(
                                context,
                                BusinessDetailsEditPageOne(
                                    prevBusinessDetails: details));
                          },
                          child: CircleAvatar(
                            radius: SizeConfig.size12,
                            backgroundColor: AppColors.primaryColor,
                            child: Icon(Icons.edit_outlined,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    CustomText(
                      (details?.categoryDetails?.name?.isNotEmpty ?? false)
                          ? details?.categoryDetails?.name ?? 'Other'
                          : (details?.subCategoryDetails?.name?.isNotEmpty ??
                                  false)
                              ? details?.subCategoryDetails?.name ?? ''
                              : (details?.natureOfBusiness ?? 'OTHERS'),
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    (details?.address == null || details?.address == '')
                        ? SizedBox()
                        : const SizedBox(
                            height: 4,
                          ),
                    Row(
                      children: [
                        (details?.address == null || details?.address == '')
                            ? SizedBox()
                            : SvgPicture.asset(
                                height: 28,
                                width: 28,
                                "assets/svg/profile_location.svg",
                              ),
                        const SizedBox(
                          width: 4,
                        ),
                        Expanded(
                          child: CustomText(
                            "${details?.address ?? ''}",
                            fontSize: SizeConfig.size14,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    (details?.address == null || details?.address == '')
                        ? SizedBox()
                        : SizedBox(
                            height: SizeConfig.size10,
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: SizeConfig.size10,
        ),

        (details?.businessIsVerified ?? false)
            ? Container(
                padding: EdgeInsets.only(
                    top: SizeConfig.size10, left: SizeConfig.size10),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.inversePrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check,
                        color: theme.colorScheme.onTertiary,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      CustomText(
                        "Your business is verified.",
                        color: theme.colorScheme.onTertiary,
                        fontWeight: FontWeight.w500,
                        fontSize: SizeConfig.medium,
                        fontStyle: FontStyle.italic,
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                padding: EdgeInsets.only(
                    top: SizeConfig.size10, left: SizeConfig.size10),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        height: 18,
                        width: 18,
                        "assets/svg/ac_verify_icon.svg",
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Expanded(
                        child: CustomText(
                          "Your business is not verified ",
                          color: theme.colorScheme.onTertiary,
                          fontWeight: FontWeight.w500,
                          fontSize: SizeConfig.medium,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                       SizedBox(
                        width: 1,
                      ),
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            // Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //         builder: (context) =>
                            //             BusinessVerificationScrn()));
                            Get.to(() => VisitBusinessProfileNew(
                                businessId: businessId, screenName:  AppConstants.feedScreen,));
                          },
                          child: CustomText(
                            fontWeight: FontWeight.w900,
                            "Verify Now",
                            color: theme.colorScheme.onTertiary,
                            fontStyle: FontStyle.italic,
                            fontSize: SizeConfig.medium,
                            decoration: TextDecoration.underline,
                            decorationColor: theme.colorScheme.onTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        SizedBox(
          height: SizeConfig.size18,
        ),

        Row(
          children: [
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          8), // Set your desired radius here
                    ),
                    side: BorderSide(color: theme.colorScheme.primary),
                    backgroundColor: theme.colorScheme.primary),
                onPressed: null,
                // onPressed: _captureAndShareCard,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: SizeConfig.paddingXSmall,
                      ),
                      CustomText(
                        "Your Orders",
                        color: theme.colorScheme.surface,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: SizeConfig.size12,
            ),
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          8), // Set your desired radius here
                    ),
                    side: BorderSide(
                      color: theme.colorScheme.primary,
                    )),
                onPressed: () {
                  _showVisitingCardDialog(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: CustomText(
                    AppLocalizations.of(context)!.visitingCard,
                    color: theme.colorScheme.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 16,
        ),
        SizedBox(height: SizeConfig.size12),
        Container(
          // margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
          padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size10,
            horizontal: SizeConfig.size10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFD3E4F7),

            border: Border.all(
              color: const Color(0xFFE5E5E5), // #E5E5E5 border
              width: 1,
            ),
            borderRadius: BorderRadius.circular(SizeConfig.size14),
            boxShadow: [
              BoxShadow(
                color: const Color(0x14000000), // #000000 with 8% opacity
                offset: const Offset(0, 1), // X: 0, Y: 1
                blurRadius: 2,
                spreadRadius: 0,
              ),
            ],
            // color: Colors.white, // optional background
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildInfo("Rating",
                        "★ ${(details?.rating ?? 0).toStringAsFixed(1)}"),
                    SizedBox(
                      height: SizeConfig.size12,
                    ),
                    buildInfo(
                        "Views", "${formatIndianNumber(details?.total_views ?? 0)}"),
                  ],
                ),
              ),
              // SizedBox(
              //   width: 100,
              // ),
              Expanded(
                child: SizedBox(
                  height: SizeConfig.size50,
                  child: VerticalDivider(
                    color: AppColors.coloGreyText,
                    width: 12,
                    thickness: 1.2,
                  ),
                ),
              ),
              // SizedBox(
              //   width: SizeConfig.size24,
              // ),
              Flexible(
                flex: 2,

                child: Container(
                  // color: Colors.red,
                  width: Get.width,
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding:  EdgeInsets.symmetric(),
                        child: buildInfo("Inquiries",formatIndianNumber(0) ),
                      ),
                      SizedBox(
                        height: SizeConfig.size12,
                      ),
                      InkWell(
                          onTap: () {
                            Get.to(() => FollowersFollowingPage(
                              tabIndex: 1,
                              userID: details?.id ?? "",
                            ));
                          },
                          child: buildInfo("Followers",
                              "${formatIndianNumber(details?.total_followers ?? 0)}")),
                    ],
                  ),
                ),
              ),
              // SizedBox(
              //   width: SizeConfig.size20,
              // ),
              Expanded(
                child: SizedBox(
                  height: SizeConfig.size50,
                  child: VerticalDivider(
                    color: AppColors.coloGreyText,
                    width: 12,
                    thickness: 1.2,
                  ),
                ),
              ),
              // SizedBox(
              //   width: SizeConfig.size20,
              // ),
              Expanded(
                flex: 2,

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CustomText(
                      "Joined",
                      fontSize: SizeConfig.size12,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(height: SizeConfig.size2),
                    CustomText(
                      details?.dateOfIncorporation == null
                          ? ""
                          : "${details?.dateOfIncorporation?.date ?? ""}/${(details?.dateOfIncorporation?.month ?? 1)}/${details?.dateOfIncorporation?.year ?? ""}",
                      fontSize: SizeConfig.size12,
                      maxLines: 1,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(height: SizeConfig.size10),
                  ],
                ),
              )
            ],
          ),
        ),
        SizedBox(height: SizeConfig.size12),

        ///ABOUT YOUR BUSINESS...
        Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    letterSpacing: 0.4,
                    "Business Description",
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                  (controller.isListingDescriptionEdit.value)
                      ? InkWell(
                          onTap: () {
                            listingDescriptionController.text =
                                controller.businessDescription.value.toString();
                            setState(() {
                              controller.isListingDescriptionEdit.value =
                                  !controller.isListingDescriptionEdit.value;
                            });
                          },
                          child: SvgPicture.asset(
                              height: 30, AppIconAssets.profile_pen_tool))
                      : Row(
                          children: [
                            CustomBtn(
                                height: 24,
                                width: 56,
                                onTap: () {
                                  setState(() {
                                    controller.isListingDescriptionEdit.value =
                                        !controller
                                            .isListingDescriptionEdit.value;
                                  });
                                },
                                title: "Cancel"),
                            const SizedBox(
                              width: 8,
                            ),
                            CustomBtn(
                                height: 24,
                                width: 56,
                                bgColor: theme.colorScheme.primary,
                                onTap: () async {
                                  if (listingDescriptionController
                                      .text.isNotEmpty) {
                                    setState(() {
                                      controller
                                              .isListingDescriptionEdit.value =
                                          !controller
                                              .isListingDescriptionEdit.value;
                                    });
                                    Map<String, dynamic> params = {
                                      ApiKeys.description:
                                          "${listingDescriptionController.text}"
                                    };
                                    await controller
                                        .updateBusinessDescription(params);
                                  } else {
                                    commonSnackBar(
                                        message:
                                            "Description can not be empty");
                                  }
                                },
                                title: "Save"),
                          ],
                        )
                ],
              ),
              CustomText(
                appLocalizations?.tellCustomersWhatYouOffer,
                fontSize: SizeConfig.size12,
                color: Color.fromRGBO(38, 50, 56, 1),
              ),
              (controller.isListingDescriptionEdit.value)
                  ? SizedBox()
                  : const SizedBox(
                      height: 4,
                    ),
              (controller.isListingDescriptionEdit.value &&
                      controller.businessDescription != '')
                  ? Container(
                      decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(10)),
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 16),
                      padding:
                          EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                      child: Obx(() {
                        return CustomText(
                          "${controller.businessDescription.value}",
                          fontSize: SizeConfig.medium,
                          color: Colors.black,
                        );
                      }),
                    )
                  : Container(
                      margin: EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(),
                      child: CommonTextField(
                        validator: null,
                        borderWidth: 0,
                        borderColor: Colors.transparent,
                        hintText: "Add your business details",
                        textEditController: listingDescriptionController,
                        maxLine: 5,
                        isValidate: false,
                        inputLength: AppConstants.inputCharterLimit200,
                      ),
                    ),
              Obx(() {
                return SizedBox(
                  height: (controller.isListingDescriptionEdit.value)
                      ? 8
                      : SizeConfig.size18,
                );
              }),
            ],
          );
        }),

        ///STORE IMAGE...
        const SizedBox(
          height: 18,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              letterSpacing: 0.6,
              "Your live store pictures",
              fontSize: SizeConfig.large,
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis,
            ),
            // (controller.imgUploadL2.isNotEmpty) ?
            // Row(
            //   children: [
            //     CustomBtn(
            //         height: 24,
            //         width: 56,
            //         onTap: () {
            //           setState(() {
            //             controller.imgUploadL2.clear();
            //           });
            //         }, title: "Cancel"),
            //     const SizedBox(
            //       width: 8,
            //     ),
            //     CustomBtn(
            //         height: 24,
            //         width: 56,
            //         bgColor: theme.colorScheme.primary,
            //         onTap: () {
            //         },
            //         title: "Save"),
            //   ],
            // ) :
            // InkWell(
            //     onTap: () {},
            //     child: SvgPicture.asset(AppIconAssets.profile_pen_tool))
          ],
        ),
        Row(
          children: [
            CustomText(
              textAlign: TextAlign.left,
              appLocalizations?.minThreeImg,
              fontSize: SizeConfig.size12,
              color: Color.fromRGBO(38, 50, 56, 1),
            ),
          ],
        ),

        SizedBox(
          height: SizeConfig.size10,
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ///API
              (details?.livePhotos?.isNotEmpty ?? false)
                  ? Row(
                      children: List<Widget>.generate(
                          (details?.livePhotos?.length ?? 0), (apiIndex) {
                        return _APIbuildImageContainer(
                            details?.livePhotos?[apiIndex],
                            apiIndex,
                            false,
                            apiIndex,
                            theme,
                            controller);
                      }),
                    )
                  : SizedBox(),

              // // ///UPLOADED
              // Row(
              //   children:
              //   List.generate(controller.imgUploadL2.length, (uploadIndex) {
              //     return _buildImageContainer(
              //         controller.imgUploadL2[uploadIndex], uploadIndex, false,controller);
              //   }),
              // ),
              //
              ///LOCAL
              Row(
                children: List<Widget>.generate(controller.imgLocalL3.length,
                    (localIndex) {
                  return _buildImageContainer(controller.imgLocalL3[localIndex],
                      localIndex, false, controller);
                }),
              ),

              ///EMPTY.....
              (3 -
                              (details?.livePhotos?.length ?? 0) -
                              // controller.imgUploadL2.length -
                              controller.imgLocalL3.length) +
                          controller.imgDeleteL3.length >
                      0
                  ? Row(
                      children: List<Widget>.generate(
                          (3 -
                              (details?.livePhotos?.length ?? 0) -
                              // controller.imgUploadL2.length -
                              controller.imgLocalL3.length), (index) {
                        return _buildImageContainer("", 0, false, controller);
                      }),
                    )
                  : SizedBox(),
            ],
          ),
        ),

        if ((details?.businessLocation?.lat != null &&
                details?.businessLocation?.lat != 0) &&
            (details?.businessLocation?.lon != null &&
                details?.businessLocation?.lon != 0)) ...[
          SizedBox(
            height: SizeConfig.size20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CustomText(
                  "Your business live location",
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // InkWell(
              //     onTap: () {},
              //     child: SvgPicture.asset(AppIconAssets.profile_pen_tool))
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: CustomText(
              "Your store’s map location",
              fontSize: SizeConfig.medium,
              color: theme.colorScheme.outline,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            height: SizeConfig.size10,
          ),
          BusinessLocationWidget(
              latitude: (details?.businessLocation?.lat?.toDouble() ?? 0.0),
              longitude: (details?.businessLocation?.lon?.toDouble() ?? 0.0),
              businessName: details?.businessName ?? "",
              isTitleShow: false),
        ],
        SizedBox(
          height: SizeConfig.size20,
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                width: SizeConfig.screenWidth,
                height: 2,
                color: Colors.black,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
              child: CustomText(
                color: Colors.black,
                appLocalizations?.listYourProductServices,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Container(
                width: SizeConfig.screenWidth,
                height: 2,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(
          height: SizeConfig.size10,
        ),
        Container(
          decoration: BoxDecoration(
              boxShadow: AppShadows.bottomAndTopShadow,
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size10, vertical: SizeConfig.size10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      appLocalizations?.createStoreSections,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.bold,
                    ),
                    CustomText(
                      "Organize your products into 👔 Men • 👗 Women • 🧒 Kids. Make shopping easier for your customers!",
                      fontSize: SizeConfig.extraSmall,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: SizeConfig.size20,
              ),
              LocalAssets(imagePath: AppIconAssets.store_bg)
            ],
          ),
        ),
        SizedBox(
          height: SizeConfig.size20,
        ),
      ],
    );
  }

  void _showVisitingCardDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey,
      builder: (context) {
        return SizedBox(
          height: Get.height * 0.8,
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: SingleChildScrollView(
              child: Column(children: [
                Center(
                  child: Container(
                    height: 4,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.white,
                    ),
                  ),
                ),
                SizedBox(
                  height: 12,
                ),
                Container(
                    // color: AppColors.pinkE2,
                    padding: EdgeInsets.all(SizeConfig.size12),
                    child: SingleChildScrollView(
                        child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SizedBox(height: SizeConfig.size12),

                        // Theme selector (4 themes) as pill chips
                        // Row(
                        //   mainAxisSize: MainAxisSize.max,
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     CustomText(
                        //       'Visiting Card',
                        //       fontWeight: FontWeight.w600,
                        //       fontSize: SizeConfig.size14,
                        //       color: AppColors.black,
                        //     ),
                        //     InkWell(
                        //       onTap: () {
                        //         Get.back();
                        //         Get.to(() => VisitingCardlistScreen(),
                        //             arguments: details);
                        //         // Get.to(()=>VisitingCardlistScreen());
                        //       },
                        //       child: CustomText('View All',
                        //           fontWeight: FontWeight.w600,
                        //           fontSize: SizeConfig.size14,
                        //           color: AppColors.black),
                        //     ),
                        //   ],
                        // ),

                        VisitingCardPreview(details: details),
                        SizedBox(height: SizeConfig.size20),
                        Column(
                          children: [
                            buildCard1(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard2(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard3(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard4(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard5(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard6(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard7(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard8(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard9(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard10(details!),
                            SizedBox(
                              height: 20,
                            ),
                            buildCard11(details!),
                          ],
                        )
                        //
                        //                   // Footer actions
                        //                   Align(
                        //                     alignment: Alignment.center,
                        //                     child: ElevatedButton.icon(
                        //                       style: ElevatedButton.styleFrom(
                        //                         shape: const StadiumBorder(),
                        //                         // backgroundColor: accentChip, // per theme
                        //                         foregroundColor: Colors.white,
                        //                       ),
                        //                       onPressed: () {
                        //                         Navigator.of(context).maybePop();
                        //                       },
                        //                       icon: const Icon(Icons.ios_share,color: AppColors.black,),
                        //                       label: Text(
                        //                           AppLocalizations.of(context)!.shareVisitingCard,style: TextStyle(color: AppColors.black),
                        //                           ),
                        //                     ),
                        //                   ),
                      ],
                    )))
              ]),
            ),
          ),
        );
      },
    );

  }



  Widget _buildImageContainer(String? imagePath, int index,
      bool uploadFromGallery, ViewBusinessDetailsController controller) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () async {
            if (imagePath == "") {
              final imgStr = await SelectProfilePictureDialog.pickFromCamera(
                  context,
                  cropAspectRatio: CropAspectRatio(width: 9, height: 16));
              if (imgStr != null) {
                saveBusinessImages(imgStr, controller.imgDeleteL3, controller);
              }

              // _pickImage(index); // Pick an image if the slot is empty
              // uploadFromGallery ? _pickImage(index) :
              //
              // String? imgStr = await SelectProfilePictureDialog.showLogoDialog(
              //     context, "Upload store live image",
              //     isOnlyCamera: true, isGallery: true, isCircleCrop: false);
              // if (imgStr != null && imgStr.isNotEmpty) {
              //   setState(() {
              // viewBusinessDetailsController.imgUploadL2.add(imgStr);
              // saveBusinessImages(
              //     imgStr, controller.imgDeleteL3, controller);
              //
              //     // Send updated list to the parent widget
              //   });
              // }
            } else {
              navigatePushTo(
                context,
                ImageViewScreen(
                  subTitle: '',
                  appBarTitle: AppLocalizations.of(context)!.imageViewer,
                  imageUrls: controller.imgLocalL3,
                  initialIndex: index,
                ),
              );
            }
          },
          child: Container(
            height: SizeConfig.screenWidth * .30,
            width: SizeConfig.screenWidth * .30,
            margin: EdgeInsets.only(
                right: SizeConfig.size6, bottom: 8, left: 4, top: 4),
            decoration: BoxDecoration(
              color: Color.fromRGBO(237, 237, 237, 1),
              borderRadius: BorderRadius.circular(10),
              image: imagePath != null
                  ? DecorationImage(
                      image: imagePath.startsWith("http")
                          ? NetworkImage(imagePath) as ImageProvider
                          : FileImage(File(imagePath)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imagePath == ""
                ? Center(
                    child: SvgPicture.asset(AppIconAssets.profile_camera_pic),
                  )
                : null,
          ),
        ),
        if (imagePath != "")
          Positioned(
            top: 8,
            right: 18,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(50)),
              child: GestureDetector(
                onTap: () {
                  Map<String, dynamic> data = {ApiKeys.image_url: imagePath};
                  controller.deleteLiveStoreImage(data);
                },
                child: const Icon(
                  Icons.close,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  ///UPDATE BUSINESS IMAGES....
  saveBusinessImages(String imagePath, List<int> deleteProfileId,
      ViewBusinessDetailsController controller) async {
    dio.MultipartFile? imageByPart;

    String fileName = imagePath.split('/').last;
    imageByPart =
        await dio.MultipartFile.fromFile(imagePath, filename: fileName);

    Map<String, dynamic> params = {ApiKeys.category_image: imageByPart};

    controller.uploadLiveStoreImage(params);
    await Future.delayed(Duration(seconds: 2));
    controller.imgDeleteL3.clear();
    // viewBusinessDetailsController.imgUploadL2.addAll(viewBusinessDetailsController.imgLocalL3);
  }

  Widget _APIbuildImageContainer(
      String? imagePath,
      int index,
      bool uploadFromGallery,
      int indexDelete,
      ThemeData theme,
      ViewBusinessDetailsController controller) {
    return Stack(
      children: [
        Container(
          height: SizeConfig.screenWidth * .30,
          width: SizeConfig.screenWidth * .30,
          margin: EdgeInsets.only(right: SizeConfig.size10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            image: imagePath != null
                ? DecorationImage(
                    image: imagePath.startsWith("http")
                        ? NetworkImage(imagePath) as ImageProvider
                        : FileImage(File(imagePath)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imagePath == null
              ? const Center(
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 32,
                  ),
                )
              : null,
        ),
        if (imagePath != null)
          Positioned(
            top: 8,
            right: 18,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(50)),
              child: GestureDetector(
                onTap: () {
                  Map<String, dynamic> data = {ApiKeys.image_url: imagePath};
                  controller.deleteLiveStoreImage(data);
                  // if (!viewBusinessDetailsController.imgDeleteL3.contains(indexDelete)) {
                  //   viewBusinessDetailsController.imgDeleteL3.add(indexDelete);
                  // }
                },
                child: const Icon(
                  Icons.close,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

enum VisitingCardTheme { theme1, theme2, theme3, theme4 }

class VisitingCardPreview extends StatelessWidget {
  final GlobalKey cardKey = GlobalKey();

  // final VisitingCardTheme theme;
  final BusinessProfileDetails? details;

  VisitingCardPreview({required this.details});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          key: cardKey,
          child: Container(
            padding: EdgeInsets.all(SizeConfig.size16),
            decoration: BoxDecoration(
              color: Color(0xFF31475A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: avatar + company block
                  Expanded(
                    // flex: 11,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: (details?.logo != null &&
                                      (details?.logo ?? '').isNotEmpty)
                                  ? NetworkImage(details?.logo ?? '')
                                  : null,
                              backgroundColor: Color(0xFF31475A),
                              child: (details?.logo == null ||
                                      (details?.logo ?? '').isEmpty)
                                  ? CustomText(
                                      (details?.businessName ?? 'B')
                                          .trim()
                                          .split(' ')
                                          .map((e) => e.isNotEmpty ? e[0] : '')
                                          .take(2)
                                          .join()
                                          .toUpperCase(),
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size12),

                        // Company name and tagline
                        CustomText(
                          // 'BLUE (OPC) PVT LTD',
                          details?.businessName ?? "",
                          // details?.businessName ?? 'BLUE (OPC) PVT LTD',
                          fontWeight: FontWeight.w700,
                          fontSize: SizeConfig.size14,
                          color: AppColors.white,
                        ),
                        SizedBox(height: SizeConfig.size6),
                        CustomText(
                          details?.natureOfBusiness ?? 'Consultant Services',
                          color: AppColors.white,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                        ),
                        infoRow(
                            icon: Icons.call,
                            title:
                                (details?.businessNumber?.officeMobNo?.number ??
                                        0)
                                    .toString(),
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            textColor: AppColors.white),

                        SizedBox(height: SizeConfig.size12),

                        // Short description (optional)
                        CustomText(
                          details?.businessDescription ??
                              'to unique custom designs, we offer something special for every occasion.',
                          color: AppColors.white,
                          fontSize: SizeConfig.small,
                        ),
                      ],
                    ),
                  ),
                  VerticalDivider(
                    color: AppColors.appBackgroundColor,
                  ),

                  // Right: person and contact info
                  Expanded(
                    // flex: 10,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            details?.ownerDetails?.isNotEmpty ?? false
                                ? details?.ownerDetails?.first.name ?? ""
                                : "",
                            // details?.ownerDetails?.first.name ?? 'Manish Kumar',
                            fontWeight: FontWeight.w700,
                            fontSize: SizeConfig.size14,
                            color: AppColors.appBackgroundColor,
                          ),
                          SizedBox(height: SizeConfig.size2),
                          CustomText(
                            details?.ownerDetails?.isNotEmpty ?? false
                                ? details?.ownerDetails?.first
                                        .role_in_business ??
                                    ""
                                : "",
                            color: AppColors.appBackgroundColor,
                            fontSize: SizeConfig.small,
                          ),
                          SizedBox(height: SizeConfig.size10),
                          infoRow(
                              icon: Icons.call,
                              title: (details?.businessNumber?.officeMobNo
                                          ?.number ??
                                      0)
                                  .toString(),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              textColor: AppColors.white),
                          // _infoRow(
                          //     Icons.phone,
                          //   (details?.businessNumber?.officeMobNo
                          //                           ?.number ??
                          //                       0)
                          //                   .toString(),

                          //     ),
                          SizedBox(height: SizeConfig.size8),

                          infoRow(
                              icon: Icons.email,
                              title: details?.ownerDetails?.isNotEmpty ?? false
                                  ? details?.ownerDetails?.first.email ?? ""
                                  : "",
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              textColor: AppColors.white),
                          SizedBox(height: SizeConfig.size8),
                          // _infoRow(
                          //     Icons.public,
                          //     details?.websiteUrl??"",
                          //     // details?.websiteUrl ?? 'www.vikash.bluehr.com',
                          //     textPrimary,
                          //     textSecondary,
                          //     iconAccent,
                          //     ellipsis: true),
                          infoRow(
                              icon: Icons.language,
                              title: details?.websiteUrl ?? "",
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              textColor: AppColors.white),
                          SizedBox(height: SizeConfig.size10),
                          infoRow(
                              icon: Icons.add_location,
                              title: details?.address ?? "",
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              textColor: AppColors.white)
                          // _infoRow(
                          //   Icons.add_location,
                          //   details?.address??"",
                          //   // details?.websiteUrl ?? 'www.vikash.bluehr.com',
                          //   textPrimary,
                          //   textSecondary,
                          //   iconAccent,
                          //   ellipsis: true),
                          // CustomText(
                          //   // "'www.vikash.bluehr.com",""
                          //   details?.address ??"",
                          //   //     '115, Road No 04 BN Ready Nagar Address abcdefgh1234567890 nmae Nagar\nHyderabad 834553',
                          //   color: textSecondary,
                          //   fontSize: SizeConfig.small,
                          // ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: InkWell(
            onTap: () async =>
                await VisitingCardHelper().shareVisitingCard(cardKey),
            child: Container(
              decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.white, blurRadius: 6, spreadRadius: 2)
                  ],
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.ios_share,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget infoRow(
      {required IconData? icon,
      required String? title,
      Color? textColor,
      double? fontSize,
      FontWeight? fontWeight,
      TextAlign? textAlign,
      Color? iconColor}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: AppColors.white,
        ),
        SizedBox(
          width: 5,
        ),
        Expanded(
            child: CustomText(
          title,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: textColor,
        ))
      ],
    );
  }
}
