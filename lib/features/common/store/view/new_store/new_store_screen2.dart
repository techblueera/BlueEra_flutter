// import 'dart:ui';
// import 'package:BlueEra/core/api/apiService/api_keys.dart';
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/app_enum.dart';
// import 'package:BlueEra/core/constants/app_icon_assets.dart';
// import 'package:BlueEra/core/constants/app_image_assets.dart';
// import 'package:BlueEra/core/constants/app_strings.dart';
// import 'package:BlueEra/core/constants/common_methods.dart';
// import 'package:BlueEra/core/constants/shared_preference_utils.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/core/routes/route_helper.dart';
// import 'package:BlueEra/core/services/location/location_service.dart';
// import 'package:BlueEra/core/widgets/custom_form_card.dart';
// import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
// import 'package:BlueEra/features/common/auth/model/individual_profiile_category.dart';
// import 'package:BlueEra/features/common/auth/model/mixed_profile_categrory.dart';
// import 'package:BlueEra/features/common/auth/views/screens/guest_dashboard_screen.dart';
// import 'package:BlueEra/features/common/jobs/view/jobs_screen.dart';
// import 'package:BlueEra/features/common/map/view/customize_map_screen.dart';
// import 'package:BlueEra/features/common/store/controller/new_store_controller.dart';
// import 'package:BlueEra/features/common/store/view/new_store/all_food_store_screen.dart';
// import 'package:BlueEra/features/common/store/view/new_store/all_product_store_screen.dart';
// import 'package:BlueEra/features/common/store/view/new_store/business_store_screen.dart';
// import 'package:BlueEra/features/common/auth/model/business_profile_category.dart';
// import 'package:BlueEra/widgets/circle_icon_grid_item.dart';
// import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
// import 'package:BlueEra/features/personal/personal_profile/view/create_profile_screen.dart';
// import 'package:BlueEra/widgets/common_box_shadow.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:BlueEra/widgets/gradient_floating_button.dart';
// import 'package:BlueEra/widgets/local_assets.dart';
// import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
// import 'package:BlueEra/widgets/update_live_photo_dialog.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mappls_gl/mappls_gl.dart';
// import '../../../../chat/auth/controller/chat_view_controller.dart';
// import '../../../../chat/view/ai_chat/ask_chat_screen.dart';
//
// class NewStoreScreen2 extends StatefulWidget {
//   final bool isHeaderVisible;
//   final Function(bool isVisible)? onHeaderVisibilityChanged;
//
//   const NewStoreScreen2(
//       {super.key,
//       required this.isHeaderVisible,
//       this.onHeaderVisibilityChanged});
//
//   @override
//   State<NewStoreScreen2> createState() => _NewStoreScreen2State();
// }
//
// class _NewStoreScreen2State extends State<NewStoreScreen2> {
//   final NewStoreController controller = Get.put(NewStoreController());
//   late MapplsMapController mapController;
//   late final double userLat;
//   late final double userLng;
//
//   @override
//   void initState() {
//     userLat = LocationService.lat;
//     userLng = LocationService.lng;
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       _calculateHeaderHeight();
//     });
//     super.initState();
//   }
//
//   void _calculateHeaderHeight() {
//     final renderBox =
//         controller.headerKey.currentContext?.findRenderObject() as RenderBox?;
//     if (renderBox != null && mounted) {
//       setState(() => controller.headerHeight = renderBox.size.height);
//     }
//   }
//
//   @override
//   void didUpdateWidget(covariant NewStoreScreen2 oldWidget) {
//     if (oldWidget.isHeaderVisible != widget.isHeaderVisible) {
//       controller.isHeaderVisible.value = widget.isHeaderVisible;
//       super.didUpdateWidget(oldWidget);
//     }
//   }
//
//   Future<void> _onMapCreated(MapplsMapController controller) async {
//     mapController = controller;
//   }
//
//   Future<void> _onStyleLoadedCallback() async {
//     try {
//       // Add marker
//       await mapController.addSymbol(
//         SymbolOptions(geometry: LatLng(userLat, userLng), iconSize: 1.5),
//       );
//
//       // Move camera to the location
//       await mapController.animateCamera(
//         CameraUpdate.newLatLngZoom(
//           LatLng(userLat, userLng),
//           14.0,
//         ),
//       );
//     } catch (e) {
//       print('Error adding marker: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//           extendBodyBehindAppBar: true,
//           floatingActionButton: Padding(
//             padding: EdgeInsets.only(
//                 bottom: kBottomNavigationBarHeight + SizeConfig.size10),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(SizeConfig.size35),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10.0),
//                 child: GradientFloatingButton(
//                   height: SizeConfig.size70,
//                   width: SizeConfig.size70,
//                   borderRadius: SizeConfig.size35,
//                   borderWidth: 1.0,
//                   padding: EdgeInsets.all(8.0),
//                   boxShadow: [
//                     BoxShadow(
//                         color: AppColors.black.withValues(alpha: 0.30),
//                         blurRadius: 4.0,
//                         offset: Offset(0, 2))
//                   ],
//                   backgroundGradientColors: const [
//                     Color(0xFFFFFFFF),
//                     Color(0xFFCCE0FF),
//                   ],
//                   borderGradientColors: const [
//                     Color(0xFF004FCE),
//                     Color(0xFF5C9BFF),
//                   ],
//                   onPressed: () {
//                     final chat =
//                         ChatViewController.inventoryAiChatListSearchModule;
//
//                     Get.to(() => AskInventoryChatScreen(
//                           profileImage: chat?.sender?.profileImage,
//                           name: chat?.sender?.name,
//                           contactNo: chat?.sender?.contactNo,
//                           conversationId: '',
//                           userId: '',
//                           businessId: '',
//                           type: chat?.sender?.accountType,
//                           isInitialMessage: false,
//                         ));
//                   },
//                   child: LocalAssets(imagePath: AppIconAssets.aiChatbotIcon),
//                 ),
//               ),
//             ),
//           ),
//           body: Obx(
//             () => setupScrollVisibilityNotification(
//               controller: controller.scrollController,
//               onVisibilityChanged: (visible, offset) {
//                 final currentOffset = controller.headerOffset.value;
//
//                 // Linear animation step (same speed up/down)
//                 const step = 0.25;
//
//                 double newOffset = currentOffset;
//                 if (visible) {
//                   // show header
//                   newOffset = (currentOffset - step).clamp(0.0, 1.0);
//                 } else {
//                   // hide header
//                   newOffset = (currentOffset + step).clamp(0.0, 1.0);
//                 }
//
//                 controller.headerOffset.value = newOffset;
//                 controller.isHeaderVisible.value = visible;
//                 widget.onHeaderVisibilityChanged?.call(visible);
//               },
//               child: Stack(
//                 children: [
//                   AnimatedPadding(
//                     duration: const Duration(milliseconds: 400),
//                     curve: Curves.easeInOut,
//                     padding: EdgeInsets.only(
//                         top: controller.headerHeight *
//                             (1 - controller.headerOffset.value)),
//                     child: SingleChildScrollView(
//                       controller: controller.scrollController,
//
//                       padding: EdgeInsets.symmetric(
//                           horizontal: SizeConfig.size8,
//                           // vertical: SizeConfig.size10
//                       ),
//                       child: Column(
//                         children: [
//                           InkWell(
//                             onTap: () {
//                               Widget dest = isGuestUser()
//                                   ? GuestDashBoardScreen()
//                                   : JobsScreen();
//
//                               Get.to(() => dest);
//                             },
//                             child: Container(
//                               padding: EdgeInsets.symmetric(
//                                 vertical: SizeConfig.size10,
//                                 horizontal: SizeConfig.size10,
//                               ),
//                               decoration: BoxDecoration(
//                                   color: AppColors.white,
//                                   borderRadius: BorderRadius.circular(10.0),
//                                   border: Border.all(color: AppColors.greyE5, width: 1.2),
//                                   boxShadow: [AppShadows.textFieldShadow]),
//                               child: Row(
//                                 children: [
//                                   LocalAssets(
//                                     imagePath: AppIconAssets.searchJobIcon,
//                                     height: SizeConfig.size30,
//                                     width: SizeConfig.size30,
//                                   ),
//                                   SizedBox(width: SizeConfig.size10),
//                                   CustomText(AppStrings.findYourDreamJobNow,
//                                       fontSize: SizeConfig.medium,
//                                       color: AppColors.secondaryTextColor,
//                                       fontWeight: FontWeight.w400),
//                                 ],
//                               ),
//                             ),
//                           ),
//
//                           SizedBox(height: SizeConfig.size10),
//
//                           // /// Mapple map
//                           // ClipRRect(
//                           //     borderRadius: BorderRadius.circular(10),
//                           //     child: SizedBox(
//                           //       width: double.infinity,
//                           //       height: SizeConfig.size160,
//                           //       child: Stack(
//                           //         children: [
//                           //           MapplsMap(
//                           //             onMapCreated: _onMapCreated,
//                           //             initialCameraPosition: CameraPosition(
//                           //               target: LatLng(userLat, userLng),
//                           //               zoom: 14.0,
//                           //             ),
//                           //             myLocationEnabled: false,
//                           //             compassEnabled: false,
//                           //             rotateGesturesEnabled: true,
//                           //             tiltGesturesEnabled: true,
//                           //             zoomGesturesEnabled: true,
//                           //             scrollGesturesEnabled: true,
//                           //             onStyleLoadedCallback:
//                           //                 _onStyleLoadedCallback,
//                           //           ),
//                           //           Positioned(
//                           //             right: SizeConfig.size10,
//                           //             bottom: SizeConfig.size10,
//                           //             child: InkWell(
//                           //               onTap: () async {
//                           //                 openGoogleMaps(
//                           //                     latitude: userLat,
//                           //                     longitude: userLng);
//                           //               },
//                           //               child: Container(
//                           //                 padding:
//                           //                     EdgeInsets.all(SizeConfig.size8),
//                           //                 decoration: BoxDecoration(
//                           //                   color: AppColors.white,
//                           //                   shape: BoxShape.circle,
//                           //                   border: Border.all(
//                           //                       color: AppColors.skyBlueDF,
//                           //                       width: 1),
//                           //                 ),
//                           //                 child: Transform.rotate(
//                           //                   angle: -0.6,
//                           //                   child: const Icon(
//                           //                     Icons.send_outlined,
//                           //                     color: AppColors.skyBlueDF,
//                           //                     size: 20,
//                           //                   ),
//                           //                 ),
//                           //               ),
//                           //             ),
//                           //           ),
//                           //         ],
//                           //       ),
//                           //     )
//                           // ),
//
//                           CustomFormCard(
//                               padding: EdgeInsets.all(
//                                   SizeConfig.size10
//                               ),
//                               child: InkWell(
//                                 onTap: ()=> Get.toNamed(RouteHelper.getRiderStoreScreenRoute()),
//                                 child: Column(
//                                   children: [
//                                     ClipRRect(
//                                       borderRadius: BorderRadius.circular(10),
//                                       child: Container(
//                                         height: SizeConfig.size190,
//                                         width: SizeConfig.screenWidth,
//                                         child: LocalAssets(
//                                           imagePath: AppImageAssets.riderStoreBanner,
//                                           boxFix: BoxFit.cover,
//                                         ),
//                                       ),
//                                     ),
//
//                                     SizedBox(height: SizeConfig.size10),
//
//                                     Row(
//                                       crossAxisAlignment: CrossAxisAlignment.center,
//                                       children: [
//                                         Expanded(
//                                           child: CustomText(
//                                               AppStrings.bookYourGroceryNdFood,
//                                               fontSize: SizeConfig.large,
//                                               color: AppColors.mainTextColor,
//                                               fontWeight: FontWeight.w600),
//                                         ),
//
//                                         SizedBox(width: SizeConfig.size10),
//
//                                         // Obx(() {
//                                         //   return Stack(
//                                         //     clipBehavior: Clip.none,
//                                         //     children: List.generate(controller.riderList.length, (index) {
//                                         //       return Padding(
//                                         //         // Each image shifts by 15 pixels multiplied by its index
//                                         //         padding: EdgeInsets.only(left: index * 15.0),
//                                         //         child: _buildRiderImageWidget(controller.riderList[index]),
//                                         //       );
//                                         //     }),
//                                         //   );
//                                         // })
//
//
//                                         Stack(
//                                           clipBehavior: Clip.none,
//                                           children: List.generate(3, (index) {
//                                             return Padding(
//                                               padding: EdgeInsets.only(left: index * 15.0),
//                                               child: _buildRiderImageWidget(),
//                                             );
//                                           }),
//                                         )
//                                       ],
//                                     )
//                                   ],
//                                 ),
//                               )
//                           ),
//
//                           SizedBox(height: SizeConfig.size10),
//
//                           /// Near Me
//                           CustomFormCard(
//                               padding: EdgeInsets.only(
//                                 left: SizeConfig.size15,
//                                 right: SizeConfig.size15,
//                                 bottom: SizeConfig.size15,
//                                 top: SizeConfig.size5,
//                               ),
//                               child: Column(
//                                 children: [
//                                   _sectionHeader(
//                                       title: AppStrings.nearMe,
//                                       seeMoreTap: () {}),
//                                   SizedBox(height: SizeConfig.size15),
//                                   genericIconGrid<MixedProfileCategory>(
//                                       items: mainCategories,
//                                       labelBuilder: (c) => c.name,
//                                       iconBuilder: (c) => c.icon,
//                                       onTap: (c) =>
//                                           _handleNearMeCategoryTap(c))
//                                 ],
//                               )),
//                           SizedBox(height: SizeConfig.size10),
//                           Obx(
//                             () => controller.isBannerVisible.value
//                                 ? _bannerWidget(
//                                     AppImageAssets.sampleStoreImage1)
//                                 : SizedBox.shrink(),
//                           ),
//
//                           SizedBox(height: SizeConfig.size10),
//
//                           /// Professionals
//                           CustomFormCard(
//                               padding: EdgeInsets.only(
//                                 left: SizeConfig.size15,
//                                 right: SizeConfig.size15,
//                                 bottom: SizeConfig.size15,
//                                 top: SizeConfig.size5,
//                               ),
//                               child: Column(
//                                 children: [
//                                   _sectionHeader(
//                                       title: AppStrings.professionals,
//                                       seeMoreTap: () {}),
//                                   SizedBox(height: SizeConfig.size15),
//                                   genericIconGrid<IndividualProfileCategory>(
//                                       items: selfWorkCategories,
//                                       labelBuilder: (c) => c.name,
//                                       iconBuilder: (c) => c.icon,
//                                       onTap: (category) {
//                                         Get.to(() => CustomizeMapScreen(
//                                               selectedMapCategoryType:
//                                                   MapServiceCategory
//                                                       .services.label,
//                                             ));
//                                       })
//                                 ],
//                               )),
//                           SizedBox(height: SizeConfig.size10),
//                           Obx(
//                             () => controller.isBannerVisible.value
//                                 ? _bannerWidget(
//                                     AppImageAssets.sampleStoreImage2)
//                                 : SizedBox.shrink(),
//                           ),
//                           SizedBox(height: SizeConfig.size10),
//
//                           /// Services
//                           CustomFormCard(
//                               padding: EdgeInsets.only(
//                                 left: SizeConfig.size15,
//                                 right: SizeConfig.size15,
//                                 bottom: SizeConfig.size15,
//                                 top: SizeConfig.size5,
//                               ),
//                               child: Column(
//                                 children: [
//                                   _sectionHeader(
//                                       title: AppStrings.services,
//                                       seeMoreTap: () {}),
//                                   SizedBox(height: SizeConfig.size15),
//                                   genericIconGrid<BusinessProfileCategory>(
//                                     items: businessServicesCategories,
//                                     labelBuilder: (c) => c.name,
//                                     iconBuilder: (c) => c.icon,
//                                     onTap: (category) {
//                                       Get.to(() => BusinessStoreScreen(
//                                             typeOfBusiness:
//                                                 AppConstants.service,
//                                             selectedStoreCategoryId:
//                                                 category.categoryData?.id,
//                                             selectedStoreCategoryName:
//                                                 category.name,
//                                           ));
//                                     },
//                                   )
//                                 ],
//                               )),
//                           SizedBox(height: SizeConfig.size10),
//                           Obx(
//                             () => controller.isBannerVisible.value
//                                 ? _bannerWidget(
//                                     AppImageAssets.sampleStoreImage3)
//                                 : SizedBox.shrink(),
//                           ),
//                           SizedBox(height: SizeConfig.size10),
//
//                           /// Store Near Me
//                           CustomFormCard(
//                               padding: EdgeInsets.only(
//                                 left: SizeConfig.size15,
//                                 right: SizeConfig.size15,
//                                 bottom: SizeConfig.size15,
//                                 top: SizeConfig.size5,
//                               ),
//                               child: Column(
//                                 children: [
//                                   _sectionHeader(
//                                       title: AppStrings.storesNearMe,
//                                       seeMoreTap: () {}),
//                                   SizedBox(height: SizeConfig.size15),
//                                   genericIconGrid<BusinessProfileCategory>(
//                                     items: businessProductsCategories,
//                                     labelBuilder: (c) => c.name,
//                                     iconBuilder: (c) => c.icon,
//                                     onTap: (category) {
//                                       Get.to(() => BusinessStoreScreen(
//                                             typeOfBusiness:
//                                                 AppConstants.product,
//                                             selectedStoreCategoryId:
//                                                 category.categoryData?.id,
//                                             selectedStoreCategoryName:
//                                                 category.name,
//                                           ));
//                                     },
//                                   )
//                                 ],
//                               )),
//                           SizedBox(height: SizeConfig.size10),
//                           Obx(
//                             () => controller.isBannerVisible.value
//                                 ? _bannerWidget(
//                                     AppImageAssets.sampleStoreImage4)
//                                 : SizedBox.shrink(),
//                           ),
//                           SizedBox(height: SizeConfig.size10),
//
//                           /// Food & Restaurant
//                           CustomFormCard(
//                               padding: EdgeInsets.only(
//                                 left: SizeConfig.size15,
//                                 right: SizeConfig.size15,
//                                 bottom: SizeConfig.size15,
//                                 top: SizeConfig.size5,
//                               ),
//                               child: Column(
//                                 children: [
//                                   _sectionHeader(
//                                       title: AppStrings.foodAndRestaurant,
//                                       seeMoreTap: () {}),
//                                   SizedBox(height: SizeConfig.size15),
//                                   genericIconGrid<BusinessProfileCategory>(
//                                     items: businessFoodsCategories,
//                                     labelBuilder: (c) => c.name,
//                                     iconBuilder: (c) => c.icon,
//                                     onTap: (category) {
//                                       Get.to(() => BusinessStoreScreen(
//                                             typeOfBusiness: AppConstants.food,
//                                             selectedStoreCategoryId:
//                                                 category.categoryData?.id,
//                                             selectedStoreCategoryName:
//                                                 category.name,
//                                           ));
//                                     },
//                                   )
//                                 ],
//                               )),
//                           SizedBox(height: SizeConfig.size10),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   /// Header stays same
//                   AnimatedPositioned(
//                     duration: const Duration(milliseconds: 400),
//                     curve: Curves.easeInOut,
//                     top: -controller.headerOffset.value *
//                         controller.headerHeight,
//                     left: 0,
//                     right: 0,
//                     child: KeyedSubtree(
//                       key: controller.headerKey,
//                       child: Builder(
//                         builder: (context) => Container(
//                           margin: EdgeInsets.only(bottom: 10),
//                           padding: EdgeInsets.only(
//                               left: SizeConfig.size15,
//                               right: SizeConfig.size20,
//                               top: SizeConfig.size10,
//                               bottom: SizeConfig.size10),
//                           color: AppColors.white,
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: Row(children: [
//                                   LocalAssets(
//                                     imagePath:
//                                         AppIconAssets.currentLocationIcon,
//                                     height: SizeConfig.size24,
//                                     width: SizeConfig.size24,
//                                   ),
//                                   SizedBox(width: SizeConfig.size10),
//                                   Expanded(
//                                     child: CustomText(
//                                       [
//                                         LocationService.userCurrentAddress.value.city,
//                                         LocationService.userCurrentAddress.value.state,
//                                       ].where((e) => e.isNotEmpty).join(', '),
//                                       fontSize: SizeConfig.large,
//                                       color: AppColors.primaryColor,
//                                       fontWeight: FontWeight.w600,
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   ),
//                                 ]),
//                               ),
//                               SizedBox(width: SizeConfig.size8),
//                               InkWell(
//                                 onTap: () {
//                                   if (isBusinessUser()) {
//                                     final controller = Get.find<
//                                         ViewBusinessDetailsController>();
//
//                                     if ((controller.businessProfileDetails?.data
//                                                     ?.livePhotos ??
//                                                 [])
//                                             .length <
//                                         3) {
//                                       showLivePhotoDialog(
//                                         context: context,
//                                       );
//                                     } else {
//                                       Get.toNamed(RouteHelper
//                                           .getInventoryScreenRoute());
//                                     }
//                                   } else {
//                                     final controller = Get.find<
//                                         ViewPersonalDetailsController>();
//
//                                     if (controller.personalProfileDetails.value
//                                             .isProfileCreated ==
//                                         false) {
//                                       Get.to(() => CreateProfileScreen());
//                                     } else {
//                                       if(userWorkTypeGlobal == DELIVERY_RIDER){
//                                         Get.toNamed(RouteHelper
//                                             .getRiderServiceScreenRoute());
//                                       }else{
//                                         Get.toNamed(RouteHelper
//                                             .getEarnServiceScreenRoute());
//                                       }
//                                     }
//                                   }
//                                 },
//                                 child: LocalAssets(
//                                   imagePath: AppIconAssets.cartIcon,
//                                 ),
//                               )
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           )),
//     );
//   }
//
//   // ---------------- REUSABLE SECTION HEADER ---------------- //
//   Widget _sectionHeader(
//       {required String title, required VoidCallback seeMoreTap}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         CustomText(title,
//             fontSize: SizeConfig.large,
//             color: AppColors.mainTextColor,
//             fontWeight: FontWeight.w600),
//         TextButton(
//           onPressed: seeMoreTap,
//           child: CustomText(AppStrings.seeMore,
//               fontSize: SizeConfig.small,
//               color: AppColors.primaryColor,
//               fontWeight: FontWeight.w600),
//         ),
//       ],
//     );
//   }
//
// // ---------------- REUSABLE ICON GRID ---------------- //
//   Widget genericIconGrid<T>({
//     required List<T> items,
//     required String Function(T item) labelBuilder,
//     required String Function(T item) iconBuilder,
//     void Function(T item)? onTap,
//   }) {
//     const crossAxisCount = 4;
//     const mainAxisSpacing = 16.0;
//
//     // Split into rows of 4
//     final rows = <List<T>>[];
//
//     for (int i = 0; i < items.length; i += crossAxisCount) {
//       rows.add(
//         items.sublist(
//           i,
//           (i + crossAxisCount).clamp(0, items.length),
//         ),
//       );
//     }
//
//     return Column(
//       children: List.generate(rows.length, (rowIndex) {
//         final rowItems = rows[rowIndex];
//         final isLastRow = rowIndex == rows.length - 1;
//
//         return Padding(
//           padding: EdgeInsets.only(bottom: isLastRow ? 0 : mainAxisSpacing),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: List.generate(crossAxisCount * 2 - 1, (i) {
//               if (i.isEven) {
//                 final itemIndex = i ~/ 2;
//
//                 if (itemIndex < rowItems.length) {
//                   final item = rowItems[itemIndex];
//
//                   return Expanded(
//                     child: CircleIconGridItem(
//                       label: labelBuilder(item),
//                       icon: iconBuilder(item),
//                       imgColor: AppColors.blue6B,
//                       onTap: () {
//                         if (onTap != null) onTap(item);
//                       },
//                     ),
//                   );
//                 } else {
//                   return const Expanded(child: SizedBox.shrink());
//                 }
//               } else {
//                 return SizedBox(width: SizeConfig.size20);
//               }
//             }),
//           ),
//         );
//       }),
//     );
//   }
//
//   // ---------------- REUSABLE BANNER WIDGET ---------------- //
//   Widget _bannerWidget(String bannerImage) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(10),
//       child: Container(
//         height: SizeConfig.size160,
//         width: SizeConfig.screenWidth,
//         child: LocalAssets(
//           imagePath: bannerImage,
//           boxFix: BoxFit.cover,
//         ),
//       ),
//     );
//   }
//
//   void _handleNearMeCategoryTap(MixedProfileCategory category) {
//     switch (category.slugId) {
//       case AppConstants.storeServices:
//         Get.to(() => BusinessStoreScreen(
//               selectedStoreCategoryName: category.name,
//             ));
//         break;
//
//       case AppConstants.foodServices:
//         Get.to(() => AllFoodStoreScreen(isShowInGrid: true));
//         break;
//
//       case AppConstants.productsServices:
//         Get.to(() => AllProductScreen(
//             isShowInGrid: true,
//             providerType: ProviderType.business,
//         ));
//         break;
//
//       case AppConstants.groceryVegetablesDairy:
//         Get.toNamed(
//           RouteHelper.getGrocerySuperCategoryScreenRoute(),
//             arguments: {ApiKeys.argMyGrocery: false}
//         );
//         break;
//
//       case AppConstants.rentalServices:
//         Get.to(() => CustomizeMapScreen(
//               selectedMapCategoryType: MapServiceCategory.rental.label,
//             ));
//         break;
//
//       case AppConstants.homeServices:
//         Get.to(() => CustomizeMapScreen(
//               selectedMapCategoryType: MapServiceCategory.homeService.label,
//             ));
//         break;
//       case AppConstants.riderServices:
//         break;
//
//       default:
//         print("⚠ Unknown category tapped: ${category.name}");
//     }
//   }
//
//   Widget _buildRiderImageWidget() {
//     return Container(
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         border: Border.all(color: AppColors.greyE5, width: 1.5),
//       ),
//       child: CircleAvatar(
//         radius: 15,
//         backgroundImage: NetworkImage("https://picsum.photos/200"),
//       ),
//     );
//   }
// }
