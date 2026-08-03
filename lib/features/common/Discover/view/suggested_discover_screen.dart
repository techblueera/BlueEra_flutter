// import 'dart:developer';
// import 'dart:ui';
//
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_icon_assets.dart';
// import 'package:BlueEra/core/constants/app_image_assets.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/core/services/location/location_service.dart';
// import 'package:BlueEra/core/widgets/custom_form_card.dart';
// import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
// import 'package:BlueEra/features/chat/view/ai_chat/view/ask_chat_screen.dart';
// import 'package:BlueEra/features/chat/view/find_contacts_with_service/find_contact_with_service.dart';
// import 'package:BlueEra/features/common/franchise/view/franchise_home.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
// import 'package:BlueEra/widgets/local_assets.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// // import 'package:smooth_page_indicator/smooth_page_indicator.dart';
//
// class SuggestedDiscoverScreen extends StatefulWidget {
//   const SuggestedDiscoverScreen({super.key});
//
//   @override
//   State<SuggestedDiscoverScreen> createState() => _SuggestedDiscoverScreenState();
// }
//
// class _SuggestedDiscoverScreenState extends State<SuggestedDiscoverScreen> {
//   late GoogleMapController mapController;
//   Set<Marker> _markers = {};
//   late final double userLat;
//   late final double userLng;
//   bool isMapLoading = true;
//   BitmapDescriptor? _customIcon;
//   final List<String> _filters = ['Overview', 'In Contact'];
//   var _selectedFilters = 'Overview'.obs;
//
//   @override
//   void initState() {
//     userLat = LocationService.lat;
//     userLng = LocationService.lng;
//     super.initState();
//   }
//
//   Future<void> _onMapCreated(GoogleMapController controller) async {
//     mapController = controller;
//
//     if (!mounted) return;
//
//     _customIcon = await BitmapDescriptor.asset(
//       const ImageConfiguration(size: Size(30, 40)),
//       AppImageAssets.locationMarkerIcon,
//     );
//
//     // await _loadMarkerAsset();
//
//
//     setState(() {
//       _markers.add(Marker(
//         markerId: const MarkerId("custom_marker_id"),
//         position: LatLng(userLat, userLng),
//         icon: _customIcon ?? BitmapDescriptor.defaultMarker,
//         onTap: () => Get.to(() => FranchiseHome()),
//       ));
//       isMapLoading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: SizeConfig.size8,
//         vertical: SizeConfig.size10,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Obx(()=> HorizontalTabSelector<String>(
//             tabs: _filters,
//             selectedIndex: _filters.indexOf(_selectedFilters.value),
//             horizontalMargin: 0.0,
//             onTabSelected: (index, _) {
//               final selectedEnum = _filters[index];
//
//               if (_selectedFilters.value == selectedEnum) return;
//
//               _selectedFilters.value = selectedEnum;
//             },
//             labelBuilder: (label) => label,
//             unSelectedBackgroundColor: AppColors.white,
//           )),
//           _buildVerticalGap(),
//           Expanded(
//             child: SingleChildScrollView(
//               physics: BouncingScrollPhysics(),
//               padding: EdgeInsets.only(bottom: 3 * kBottomNavigationBarHeight),
//               child: Obx(() {
//                 if (_selectedFilters.value == 'Overview') {
//                   return _buildOverviewWidget();
//                 } else {
//                   return _buildInContactWidget();
//                 }
//               }),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//
//   Widget _buildOverviewWidget() {
//     return Column(
//       children: [
//         _buildMapWidget(),
//         _buildVerticalGap(),
//         searchViaAiWidget(),
//         _buildVerticalGap(),
//         _recentActivityWidget(),
//         _buildVerticalGap(),
//         _bestDealWidget()
//       ],
//     );
//   }
//
//   Widget _buildInContactWidget() {
//     return FindContactWithService(fromBottomNav: true);
//   }
//
//   Widget _buildVerticalGap({double? gap}) {
//     return SizedBox(height: gap ?? SizeConfig.paddingXSL);
//   }
//
//   Widget _buildHorizontalGap({double? gap}) {
//     return SizedBox(width: gap ?? SizeConfig.paddingXS);
//   }
//
//   Widget _title(String title) {
//     return CustomText(title,
//         fontSize: SizeConfig.large,
//         color: AppColors.mainTextColor,
//         fontWeight: FontWeight.w600);
//   }
//
//   Widget _viewAll([VoidCallback? onTap]) {
//     return InkWell(
//       onTap: onTap,
//       child: CustomText('View All',
//           fontSize: SizeConfig.medium,
//           color: AppColors.primaryColor,
//           fontWeight: FontWeight.w600),
//     );
//   }
//
//   Widget _buildMapWidget() {
//     return CustomFormCard(
//       padding: EdgeInsets.all(SizeConfig.size10),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(child: _title('BlueEra Partner Near you')),
//               SizedBox(width: SizeConfig.size8),
//               Container(
//                   padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//                   decoration: BoxDecoration(
//                       color: AppColors.white.withValues(alpha: 0.1),
//                       borderRadius: BorderRadius.circular(6.0),
//                       border: Border.all(color: AppColors.primaryColor)),
//                   child: CustomText(
//                       LocationService.userCurrentAddress.value.postalCode,
//                       color: AppColors.primaryColor,
//                       fontSize: SizeConfig.medium,
//                       fontWeight: FontWeight.w600))
//             ],
//           ),
//           SizedBox(height: SizeConfig.paddingXSL),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: SizedBox(
//               width: double.infinity,
//               height: SizeConfig.size140,
//               child: Stack(
//                 children: [
//                   GoogleMap(
//                     onMapCreated: _onMapCreated,
//                     initialCameraPosition: CameraPosition(
//                       target: LatLng(userLat, userLng),
//                       zoom: 12.0,
//                     ),
//                     markers: _markers,
//                     onTap: (LatLng latLng) {
//                       log("logMsg");
//                       Get.to(() => FranchiseHome());
//                     },
//                     zoomGesturesEnabled: false,
//                     myLocationButtonEnabled: false,
//                     zoomControlsEnabled: false,
//                     scrollGesturesEnabled: false,
//                   ),
//                   Positioned(
//                       right: 6.0,
//                       bottom: 6.0,
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(6.0),
//                         child: BackdropFilter(
//                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
//                           child: Container(
//                             padding: EdgeInsets.all(6.0),
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(6.0),
//                               color: AppColors.black.withValues(alpha: 0.5),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: AppColors.black.withValues(alpha: 0.25),
//                                   blurRadius: 4.0,
//                                   offset: Offset(0, 4)
//                                 )
//                               ]
//                             ),
//                             child: CustomText(
//                                 'Need Help ?',
//                                 color: AppColors.white,
//                                 fontSize: SizeConfig.extraSmall,
//                                 fontWeight: FontWeight.w600),
//                           ),
//                         ),
//                       )),
//                   if (isMapLoading)
//                     Container(
//                       color: Colors.grey[200],
//                       child: const Center(
//                         child: CircularProgressIndicator(
//                           valueColor: AlwaysStoppedAnimation<Color>(
//                               AppColors.primaryColor),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//   Widget searchViaAiWidget() {
//     return InkWell(
//       onTap: () {
//         final chat = ChatViewController.inventoryAiChatListSearchModule;
//         Get.to(() => AskChatScreen(
//           // profileImage: AppImageAssets.sampleGirlImage,
//           profileImage: chat?.sender?.profileImage,
//           name: chat?.sender?.name,
//           contactNo: chat?.sender?.contactNo,
//           conversationId: '',
//           userId: '',
//           businessId: '',
//           type: chat?.sender?.accountType,
//           isInitialMessage: false,
//         ));
//       },
//       child: Container(
//         padding: EdgeInsets.only(
//           left: SizeConfig.size14,
//           right: SizeConfig.size14,
//           top: SizeConfig.size14,
//         ),
//         decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10.0),
//             border:
//             Border.all(color: AppColors.blueShade.withValues(alpha: 0.1)),
//             gradient: LinearGradient(colors: [
//               AppColors.blueShade.withValues(alpha: 0.02),
//               AppColors.blueShade.withValues(alpha: 0.3)
//             ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
//         child: Row(
//           children: [
//             LocalAssets(
//                 imagePath: AppImageAssets.sampleGirlImage,
//                 width: SizeConfig.size90,
//                 boxFix: BoxFit.cover),
//             SizedBox(width: SizeConfig.size12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   FittedBox(
//                     fit: BoxFit.scaleDown,
//                     child: CustomText('Hi!',
//                         fontSize: SizeConfig.medium,
//                         color: AppColors.mainTextColor,
//                         fontWeight: FontWeight.w400),
//                   ),
//                   SizedBox(
//                     height: SizeConfig.size5,
//                   ),
//                   FittedBox(
//                     fit: BoxFit.scaleDown,
//                     child: RichText(
//                       text: TextSpan(
//                         style: TextStyle(
//                             fontSize: SizeConfig.medium,
//                             color: AppColors.mainTextColor,
//                             fontWeight: FontWeight.w400),
//                         children: [
//                           const TextSpan(text: 'May I '),
//                           TextSpan(
//                             text: 'Help You',
//                             style: TextStyle(
//                               color: AppColors.primaryColor,
//                               fontWeight: FontWeight.w600,
//                               fontSize: SizeConfig.medium,
//                             ),
//                           ),
//                           const TextSpan(text: ' to Find Out'),
//                         ],
//                       ),
//                     ),
//                   ),
//                   SizedBox(
//                     height: SizeConfig.size5,
//                   ),
//                   FittedBox(
//                     fit: BoxFit.scaleDown,
//                     child: RichText(
//                       text: TextSpan(
//                         style: TextStyle(
//                             fontSize: SizeConfig.medium,
//                             color: AppColors.mainTextColor,
//                             fontWeight: FontWeight.w400),
//                         children: [
//                           const TextSpan(text: 'Your Product From '),
//                           TextSpan(
//                             text: 'Local Market.',
//                             style: TextStyle(
//                               color: AppColors.primaryColor,
//                               fontWeight: FontWeight.w600,
//                               fontSize: SizeConfig.medium,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: SizeConfig.size12),
//                   Container(
//                     height: SizeConfig.size32,
//                     decoration: BoxDecoration(
//                       color: AppColors.white,
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     alignment: Alignment.center,
//                     child: TextFormField(
//                       enabled: false,
//                       autofocus: false,
//                       controller: TextEditingController(),
//                       style: TextStyle(
//                           color: AppColors.mainTextColor,
//                           fontSize: SizeConfig.medium),
//                       textAlignVertical: TextAlignVertical.center,
//                       decoration: InputDecoration(
//                         hintText: 'Search Product....',
//                         hintStyle: TextStyle(
//                             fontSize: SizeConfig.medium,
//                             color: AppColors.secondaryTextColor),
//                         isDense: true,
//                         filled: false,
//                         contentPadding: EdgeInsets.zero,
//                         border: InputBorder.none,
//                         enabledBorder: InputBorder.none,
//                         focusedBorder: InputBorder.none,
//                         prefixIcon: Padding(
//                           padding: EdgeInsets.only(
//                             top: SizeConfig.size5,
//                             bottom: SizeConfig.size5,
//                           ),
//                           child: Icon(Icons.search,
//                               color: AppColors.secondaryTextColor,
//                               size: SizeConfig.paddingXL),
//                         ),
//                         suffixIcon: Padding(
//                           padding: EdgeInsets.only(
//                               left: SizeConfig.size8,
//                               right: SizeConfig.size16,
//                               top: SizeConfig.size5,
//                               bottom: SizeConfig.size5),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(Icons.mic_none_outlined,
//                                   color: AppColors.secondaryTextColor,
//                                   size: SizeConfig.paddingXL),
//                               SizedBox(width: SizeConfig.size10),
//                               Icon(Icons.camera_alt_outlined,
//                                   color: AppColors.secondaryTextColor,
//                                   size: SizeConfig.paddingXL),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _recentActivityWidget(){
//     return CustomFormCard(
//         padding: EdgeInsets.all(SizeConfig.size10),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _title('Recent Activity'),
//             SizedBox(height: SizeConfig.paddingXSL),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 commonCategoryItem(
//                   iconPath: AppImageAssets.groceryItemsColorful,
//                   label: 'Grocery',
//                   onTap: () {},
//                 ),
//                 _buildHorizontalGap(),
//                 commonCategoryItem(
//                   iconPath: AppImageAssets.vegetablesColorful,
//                   label: 'Veg',
//                   onTap: () {},
//                 ),
//                 _buildHorizontalGap(),
//                 commonCategoryItem(
//                   iconPath: AppImageAssets.fruitsColorful,
//                   label: 'Fruits',
//                   onTap: () {},
//                 ),
//                 _buildHorizontalGap(),
//                 commonCategoryItem(
//                   iconPath: AppImageAssets.bakeryNamkeenItemsColorful,
//                   label: 'Bakery',
//                   onTap: () {},
//
//                 ),
//
//               ],
//             )
//           ],
//         )
//     );
//   }
//
//   Widget commonCategoryItem({
//     required String label,
//     required String iconPath,
//     required VoidCallback onTap,
//     Color? textColor,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // Icon Section
//           LocalAssets(
//             imagePath: iconPath,
//             height: SizeConfig.size45,
//           ),
//
//           SizedBox(height: SizeConfig.paddingXSL),
//
//           // Label Section
//           CustomText(
//             label,
//             fontSize: SizeConfig.small,
//             color: textColor ?? AppColors.secondaryTextColor,
//             fontWeight: FontWeight.w400,
//             textAlign: TextAlign.center,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _bestDealWidget() {
//     final PageController _pageController = PageController();
//
//     // Your list of deal images
//     final List<String> dealImages = [
//       AppImageAssets.medicalHealthService,
//       AppImageAssets.consultingService,
//       AppImageAssets.educationTraining,
//       AppImageAssets.hostel,
//     ];
//
//     return CustomFormCard(
//       padding: EdgeInsets.all(SizeConfig.size10),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(child: _title('Best Deal')),
//               SizedBox(width: SizeConfig.size8),
//               _viewAll(() {}),
//             ],
//           ),
//           SizedBox(height: SizeConfig.paddingXSL),
//
//           // Image Slider Section
//           SizedBox(
//             height: SizeConfig.size180,
//             child: PageView.builder(
//               controller: _pageController,
//               itemCount: dealImages.length,
//               itemBuilder: (context, index) {
//                 return ClipRRect(
//                   borderRadius: BorderRadius.circular(10),
//                   child: LocalAssets(
//                     imagePath: dealImages[index],
//                     boxFix: BoxFit.cover,
//                     width: SizeConfig.screenWidth,
//                   ),
//                 );
//               },
//             ),
//           ),
//
//           SizedBox(height: SizeConfig.paddingS),
//
//           // Bottom Indicator Section
//           // Center(
//           //   child: SmoothPageIndicator(
//           //     controller: _pageController,
//           //     count: dealImages.length,
//           //     effect: ExpandingDotsEffect(
//           //       dotHeight: 8,
//           //       dotWidth: 8,
//           //       activeDotColor: AppColors.primaryColor,
//           //       dotColor: AppColors.secondaryTextColor.withValues(alpha: 0.3),
//           //       expansionFactor: 3,
//           //     ),
//           //   ),
//           // ),
//         ],
//       ),
//     );
//   }
//
//
// }
