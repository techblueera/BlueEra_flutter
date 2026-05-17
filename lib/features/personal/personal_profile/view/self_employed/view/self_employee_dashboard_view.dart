// import 'dart:ui';
//
// import 'package:BlueEra/core/api/apiService/api_keys.dart';
// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_constant.dart';
// import 'package:BlueEra/core/constants/app_icon_assets.dart';
// import 'package:BlueEra/core/constants/app_strings.dart';
// import 'package:BlueEra/core/constants/getx_utils.dart';
// import 'package:BlueEra/core/constants/shared_preference_utils.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/core/routes/route_helper.dart';
// import 'package:BlueEra/core/services/multipart_image_service.dart';
// import 'package:BlueEra/core/services/share_service.dart';
// import 'package:BlueEra/features/business/widgets/business_card_ui.dart';
// import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
// import 'package:BlueEra/features/common/home/widgets/drawer.dart';
// import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
// import 'package:BlueEra/features/common/visiting_card/view/all_personal_visiting_cards.dart';
// import 'package:BlueEra/features/me/me_tab_registry.dart';
// import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
// import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
// import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_employee_orders.dart';
// import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_profession_service_screen.dart';
// import 'package:BlueEra/features/personal/personal_profile/view/widget/edit_profile_bottom_sheet.dart';
// import 'package:BlueEra/features/personal/personal_profile/view/widget/profile_designation_bottom_sheet.dart';
// import 'package:BlueEra/features/contribution/view/contribution_status_view.dart';
// import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
// import 'package:BlueEra/widgets/common_card_widget.dart';
// import 'package:BlueEra/widgets/common_circular_profile_image.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:BlueEra/widgets/local_assets.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:croppy/croppy.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
//
// class SelfEmployeeDashboardView extends StatefulWidget {
//   final bool fromBottomNavBar;
//
//   const SelfEmployeeDashboardView({
//     super.key,
//     required this.fromBottomNavBar,
//   });
//
//   @override
//   State<SelfEmployeeDashboardView> createState() =>
//       _SelfEmployeeDashboardViewState();
// }
//
// class _SelfEmployeeDashboardViewState extends State<SelfEmployeeDashboardView>
//     with SingleTickerProviderStateMixin {
//   final _viewCtrl = Get.find<ViewPersonalDetailsController>();
//   final _personalCtrl = getOrPut(() => PersonalCreateProfileController());
//
//   late TabController _tabController;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     MeTabRegistry.register(_tabController);
//     _viewCtrl.UserFollowersAndPostsCount(userId);
//     WidgetsBinding.instance.addPostFrameCallback((_) => _syncShopStatus());
//   }
//
//   @override
//   void dispose() {
//     MeTabRegistry.unregister(_tabController);
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   void _syncShopStatus() {
//     _viewCtrl.shopStatusOpenClose.value =
//         serviceProviderStatusGlobal.toUpperCase() ==
//             AppConstants.OPEN.toUpperCase();
//   }
//
//   String _capitalizeFirst(String text) {
//     if (text.isEmpty) return '';
//     return text[0].toUpperCase() + text.substring(1).toLowerCase();
//   }
//
//   String _formatCount(int count) {
//     if (count >= 1000000) return "${(count / 1000000).toStringAsFixed(1)}M";
//     if (count >= 1000) return "${(count / 1000).toStringAsFixed(1)}k";
//     return "$count";
//   }
//
//   String _extractCityState(String address) {
//     if (address.isEmpty) return '';
//     final parts = address.split(',').map((e) => e.trim()).toList();
//     if (parts.length >= 3) {
//       final statePart =
//           parts[parts.length - 2].replaceAll(RegExp(r'\d{5,6}'), '').trim();
//       final city = parts[parts.length - 3].trim();
//       if (city.isNotEmpty && statePart.isNotEmpty) return "$city, $statePart";
//       return city.isNotEmpty ? city : statePart;
//     }
//     return address;
//   }
//
//   String _formatJoinedDate(String dateStr) {
//     try {
//       final date = DateTime.parse(dateStr);
//       return DateFormat('MMMM yyyy').format(date);
//     } catch (_) {
//       return '';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // No outer Obx — the only reactive reads at this level were the
//     // selectedProfileIndex / earnProfileType pair used to swap in
//     // EarnServiceDashboardView. That switch was driven by the
//     // (now-retired) EarnServiceProfileSelector, so the branch can
//     // never fire any more. Reactive sub-trees (banner, name, stats,
//     // Go-live toggle) keep their own inner Obx wrappers.
//     return Scaffold(
//       body: SafeArea(
//         bottom: false,
//         child: BottomNavHideOnScroll(
//           child: NestedScrollView(
//             headerSliverBuilder: (context, innerBoxIsScrolled) => [
//               SliverToBoxAdapter(child: _buildCoverSection(context)),
//               SliverToBoxAdapter(child: _buildProfileInfoSection()),
//               SliverToBoxAdapter(child: _buildStatsRow()),
//               SliverAppBar(
//                 pinned: true,
//                 floating: false,
//                 primary: false,
//                 automaticallyImplyLeading: false,
//                 toolbarHeight: 0,
//                 collapsedHeight: 0,
//                 expandedHeight: 0,
//                 backgroundColor: Colors.white,
//                 surfaceTintColor: Colors.white,
//                 bottom: TabBar(
//                   controller: _tabController,
//                   labelColor: AppColors.primaryColor,
//                   unselectedLabelColor: AppColors.secondaryTextColor,
//                   indicatorColor: AppColors.primaryColor,
//                   indicatorWeight: 2,
//                   indicatorPadding: EdgeInsets.zero,
//                   labelPadding: EdgeInsets.zero,
//                   tabAlignment: TabAlignment.fill,
//                   indicatorSize: TabBarIndicatorSize.tab,
//                   labelStyle: const TextStyle(
//                       fontWeight: FontWeight.w600, fontSize: 14),
//                   unselectedLabelStyle: const TextStyle(
//                       fontWeight: FontWeight.w400, fontSize: 14),
//                   tabs: [
//                     Tab(text: AppStrings.myOrder.tr),
//                     Tab(text: AppStrings.home.tr),
//                     Tab(text: AppStrings.statistics.tr),
//                   ],
//                 ),
//               ),
//             ],
//             body: TabBarView(
//               controller: _tabController,
//               children: [
//                 SelfEmployeeOrders(),
//                 SelfProfessionServiceScreen(),
//                 const ContributionStatusView(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // COVER SECTION
//   // ============================================================
//
//   Widget _buildCoverSection(BuildContext context) {
//     const bannerHeight = 250.0;
//     return Container(
//       color: AppColors.white,
//       height: bannerHeight + 40,
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Obx(() {
//             final banner = _personalCtrl.coverImagePath?.value ?? '';
//             return SizedBox(
//               height: bannerHeight,
//               width: double.infinity,
//               child: banner.isNotEmpty
//                   ? Image.network(banner, fit: BoxFit.cover)
//                   : CachedNetworkImage(
//                       imageUrl: _personalCtrl.imagePath?.value ?? '',
//                       fit: BoxFit.cover,
//                       placeholder: (_, __) => Container(
//                         decoration: const BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                         ),
//                       ),
//                       errorWidget: (_, __, ___) => Container(
//                         decoration: const BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                         ),
//                       ),
//                     ),
//             );
//           }),
//           // Single glassmorphic header row sitting on the banner, just
//           // below the status bar (SafeArea handles the top padding).
//           // Layout: [drawer] [Earn / profile selector]  …  [bell] [Go Live]
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             child: _buildGlassHeaderRow(context),
//           ),
//           // Banner-edit camera — bottom-right of the banner image.
//           Positioned(
//             right: 8,
//             top: bannerHeight - 44,
//             child: _coverIconButton(
//               icon: Icons.camera_alt_outlined,
//               onTap: () => _onCoverImageEdit(context),
//             ),
//           ),
//           // Profile image + share + card
//           Positioned(
//             left: 16,
//             bottom: 0,
//             right: 16,
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.white, width: 4),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(alpha: 0.1),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Obx(() {
//                     return CommonProfileImage(
//                       imagePath: _personalCtrl.imagePath?.value ?? "",
//                       onImageUpdate: (image) async {
//                         _personalCtrl.imagePath?.value = image;
//                         dynamic dataImage =
//                             await multiPartImage(imagePath: image);
//                         var reqProfile = {ApiKeys.profile_image: dataImage};
//                         await _personalCtrl.updateUserProfileDetails(
//                             params: reqProfile, isFromProfileOnly: true);
//                       },
//                       dialogTitle: AppStrings.uploadProfilePicture,
//                       showProfileBorder: false,
//                     );
//                   }),
//                 ),
//                 const Spacer(),
//                 GestureDetector(
//                   onTap: () async {
//                     // Centralized share — ShareService builds the link
//                     // from session globals and hands it to the share
//                     // sheet with the standard "See my profile" body.
//                     final userName = _viewCtrl
//                             .personalProfileDetails.value.user?.name ??
//                         '';
//                     await ShareService.instance.shareProfile(
//                         userId: userId,
//                         subject: userName);
//                   },
//                   child: Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: BoxDecoration(
//                       color: AppColors.white,
//                       border: Border.all(color: AppColors.greyE5, width: 1.5),
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           offset: const Offset(0, 1),
//                           blurRadius: 2,
//                           color: AppColors.black.withValues(alpha: 0.08),
//                         ),
//                       ],
//                     ),
//                     child: LocalAssets(
//                       imagePath: AppIconAssets.profile_share,
//                       width: 16,
//                       height: 16,
//                       imgColor: AppColors.secondaryTextColor,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 BusinessCardUi(
//                   onTap: () => Get.to(() => AllPersonalVisitingCards(
//                         personalDetails:
//                             _viewCtrl.personalProfileDetails.value,
//                       )),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ============================================================
//   // PROFILE INFO SECTION
//   // ============================================================
//
//   Widget _buildProfileInfoSection() {
//     final user = _viewCtrl.personalProfileDetails.value.user;
//     final name = _capitalizeFirst(user?.name ?? '');
//     final username = user?.username ?? '';
//     final designation = user?.designation ?? '';
//     final location = _extractCityState(user?.address ?? '');
//     final email = user?.email ?? '';
//     final createdAt = user?.createdAt ?? '';
//
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (name.isNotEmpty)
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Expanded(
//                         child: CustomText(
//                           name,
//                           fontSize: SizeConfig.extraLarge22,
//                           fontWeight: FontWeight.w700,
//                           color: AppColors.mainTextColor,
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       const SizedBox(width: 6),
//                       _buildEditProfileChip(),
//                     ],
//                   ),
//                 if (username.isNotEmpty || createdAt.isNotEmpty) ...[
//                   const SizedBox(height: 2),
//                   Row(
//                     children: [
//                       if (username.isNotEmpty)
//                         CustomText(
//                           "@$username",
//                           fontSize: SizeConfig.medium,
//                           color: AppColors.secondaryTextColor,
//                           fontWeight: FontWeight.w400,
//                         ),
//                       if (username.isNotEmpty && createdAt.isNotEmpty)
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 6),
//                           child: CustomText(
//                             "\u2022",
//                             fontSize: SizeConfig.small,
//                             color: AppColors.secondaryTextColor,
//                           ),
//                         ),
//                       if (createdAt.isNotEmpty)
//                         CustomText(
//                           "Joined ${_formatJoinedDate(createdAt)}",
//                           fontSize: SizeConfig.small,
//                           color: AppColors.secondaryTextColor,
//                           fontWeight: FontWeight.w400,
//                         ),
//                     ],
//                   ),
//                 ],
//                 const SizedBox(height: 8),
//                 _buildDesignationChip(designation),
//                 if (location.isNotEmpty || email.isNotEmpty) ...[
//                   const SizedBox(height: 10),
//                   if (location.isNotEmpty) ...[
//                     _infoRow(Icons.location_on_outlined, location),
//                     const SizedBox(height: 6),
//                   ],
//                   if (email.isNotEmpty)
//                     _infoRow(Icons.email_outlined, email),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGlassHeaderRow(BuildContext context) {
//     // No reactive reads remain in this header now that the earn-
//     // profile selector + Earn action pill have been retired — drop
//     // the Obx wrapper so we don't emit "improper use of GetX" at
//     // runtime.
//     return Stack(
//         children: [
//           // Full-width dark glassmorphic backing strip — touches top/left/right
//           // edges with no border radius.
//           Positioned.fill(
//             child: ClipRect(
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
//                 child: DecoratedBox(
//                   decoration: BoxDecoration(
//                     color: Colors.black.withValues(alpha: 0.25),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           // Individual dark glass pills sitting on top of the strip.
//           Padding(
//             padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 _GlassPill(
//                   onTap: () => _openDrawer(context),
//                   padding: const EdgeInsets.all(8),
//                   shape: BoxShape.circle,
//                   dark: true,
//                   child: LocalAssets(
//                     imagePath: AppIconAssets.drawer_more,
//                     width: 18,
//                     height: 18,
//                     imgColor: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 // EarnServiceProfileSelector + the Earn action pill
//                 // have been retired from this header — the Earn entry
//                 // now lives in the drawer. Nothing replaces them here;
//                 // the Spacer below pushes the right-hand pills (bell,
//                 // Go-live) to the edge as before.
//                 const Spacer(),
//                 if (!isGuestUser()) ...[
//                   _GlassPill(
//                     onTap: () => Navigator.pushNamed(
//                       context,
//                       RouteHelper.getNotificationScreenRoute(),
//                     ),
//                     padding: const EdgeInsets.all(8),
//                     shape: BoxShape.circle,
//                     dark: true,
//                     child: LocalAssets(
//                       imagePath: AppIconAssets.notificationOutlineIcon,
//                       width: 18,
//                       height: 18,
//                       imgColor: Colors.white,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                 ],
//                 _buildGoLiveChip(),
//               ],
//             ),
//           ),
//         ],
//     );
//   }
//
//   Widget _buildGoLiveChip() {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(100),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
//         child: Container(
//           height: SizeConfig.size36,
//           decoration: BoxDecoration(
//             color: Colors.black.withValues(alpha: 0.35),
//             border: Border.all(
//               color: Colors.white.withValues(alpha: 0.18),
//               width: 0.6,
//             ),
//             borderRadius: BorderRadius.circular(100),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               SizedBox(width: SizeConfig.size10),
//               CustomText(
//                 AppStrings.goLive,
//                 fontSize: SizeConfig.small,
//                 color: Colors.white,
//                 fontWeight: FontWeight.w600,
//               ),
//               SizedBox(width: SizeConfig.size5),
//               Obx(() {
//                 if (_viewCtrl.isShopStatusUpdating.value) {
//                   return Padding(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: SizeConfig.size10,
//                       vertical: SizeConfig.size6,
//                     ),
//                     child: SizedBox(
//                       width: 16,
//                       height: 16,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                             AppColors.primaryColor),
//                       ),
//                     ),
//                   );
//                 }
//                 final isOn = _viewCtrl.shopStatusOpenClose.value;
//                 return GestureDetector(
//                   onTap: () => _viewCtrl.toggleShopStatus(),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(100),
//                     child: BackdropFilter(
//                       filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
//                       child: AnimatedContainer(
//                         duration: const Duration(milliseconds: 180),
//                         width: 38,
//                         height: 22,
//                         padding: const EdgeInsets.all(3),
//                         decoration: BoxDecoration(
//                           color: isOn
//                               ? AppColors.primaryColor
//                               : Colors.black.withValues(alpha: 0.25),
//                           borderRadius: BorderRadius.circular(100),
//                           border: Border.all(
//                             color: isOn
//                                 ? AppColors.primaryColor
//                                 : Colors.white.withValues(alpha: 0.18),
//                             width: 0.6,
//                           ),
//                         ),
//                         alignment:
//                             isOn ? Alignment.centerRight : Alignment.centerLeft,
//                         child: Container(
//                           width: 14,
//                           height: 14,
//                           decoration: const BoxDecoration(
//                             color: Colors.white,
//                             shape: BoxShape.circle,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               }),
//               SizedBox(width: SizeConfig.size6),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _openDrawer(BuildContext context) {
//     showDialog(
//       barrierDismissible: true,
//       barrierColor: Colors.black.withValues(alpha: 0.3),
//       useSafeArea: false,
//       context: context,
//       builder: (BuildContext context) {
//         return Align(
//           alignment: Alignment.centerLeft,
//           child: SizedBox(
//             height: double.infinity,
//             child: Drawer(backgroundColor: Colors.transparent, elevation: 0, child: ProfileMenuDrawer()),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _coverIconButton({
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return _GlassPill(
//       onTap: onTap,
//       padding: const EdgeInsets.all(8),
//       shape: BoxShape.circle,
//       dark: true,
//       child: Icon(icon, color: Colors.white, size: 18),
//     );
//   }
//
//
//   /// Inline pencil chip rendered next to the user's name in the profile
//   /// header. Tapping it pushes [UpdateProfileScreen] so the user can edit
//   /// their personal profile (name, username, designation, address, etc.)
//   /// without leaving the Self Employee dashboard.
//   Widget _buildEditProfileChip() {
//     return InkWell(
//       onTap: _openEditProfile,
//       borderRadius: BorderRadius.circular(20),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           color: AppColors.primaryColor.withValues(alpha: 0.08),
//           border: Border.all(
//             color: AppColors.primaryColor.withValues(alpha: 0.3),
//             width: 0.6,
//           ),
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.edit_outlined,
//               size: 14,
//               color: AppColors.primaryColor,
//             ),
//             const SizedBox(width: 4),
//             CustomText(
//               'Edit',
//               fontSize: SizeConfig.extraSmall,
//               color: AppColors.primaryColor,
//               fontWeight: FontWeight.w600,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _openEditProfile() {
//     EditProfileBottomSheet.show(Get.context!);
//   }
//
//   Widget _buildDesignationChip(String designation) {
//     final hasDesignation = designation.trim().isNotEmpty;
//     return InkWell(
//       onTap: () => showProfileDesignationSheet(Get.context!),
//       borderRadius: BorderRadius.circular(20),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
//         decoration: BoxDecoration(
//           color: AppColors.primaryColor.withValues(alpha: 0.08),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: AppColors.primaryColor.withValues(alpha: 0.3),
//             width: 0.5,
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Flexible(
//               child: CustomText(
//                 hasDesignation ? designation : 'Add designation',
//                 color: AppColors.primaryColor,
//                 fontSize: SizeConfig.small,
//                 fontWeight: FontWeight.w500,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             SizedBox(width: SizeConfig.size10),
//             LocalAssets(
//               imagePath: AppIconAssets.editIcon,
//               height: SizeConfig.size12,
//               width: SizeConfig.size12,
//               imgColor: AppColors.primaryColor,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _infoRow(IconData icon, String text) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 16, color: AppColors.secondaryTextColor),
//         const SizedBox(width: 5),
//         Flexible(
//           child: CustomText(
//             text,
//             fontSize: SizeConfig.medium15,
//             color: AppColors.secondaryTextColor,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     );
//   }
//
//   // ============================================================
//   // STATS ROW
//   // ============================================================
//
//   Widget _buildStatsRow() {
//     return CommonCardWidget(
//       cardMargin: 0,
//       padding: 0,
//       child: Obx(() {
//         final followers = _viewCtrl.followersCount.value;
//         final following = _viewCtrl.followingCount.value;
//         final posts = _viewCtrl.postsCount.value;
//
//         return Container(
//           padding: EdgeInsets.symmetric(
//               horizontal: SizeConfig.size14, vertical: SizeConfig.size8),
//           margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
//           decoration: BoxDecoration(
//             color: AppColors.white,
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: Colors.grey.shade200),
//           ),
//           child: Row(
//             children: [
//               Expanded(child: _statItem("Posts", "$posts")),
//               _statDivider(),
//               Expanded(
//                 child: GestureDetector(
//                   onTap: () => Get.to(() => FollowersFollowingPage(
//                       tabIndex: 1, userID: userId)),
//                   child: _statItem("Followers", _formatCount(followers)),
//                 ),
//               ),
//               _statDivider(),
//               Expanded(
//                 child: GestureDetector(
//                   onTap: () => Get.to(() => FollowersFollowingPage(
//                       tabIndex: 0, userID: userId)),
//                   child: _statItem("Following", _formatCount(following)),
//                 ),
//               ),
//             ],
//           ),
//         );
//       }),
//     );
//   }
//
//   Widget _statItem(String label, String value) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         CustomText(value,
//             fontSize: SizeConfig.medium,
//             fontWeight: FontWeight.bold,
//             color: AppColors.mainTextColor),
//         const SizedBox(height: 4),
//         CustomText(label,
//             fontSize: SizeConfig.small,
//             color: AppColors.secondaryTextColor,
//             fontWeight: FontWeight.w400),
//       ],
//     );
//   }
//
//   Widget _statDivider() {
//     return Container(height: 30, width: 1, color: Colors.grey.shade200);
//   }
//
//   // ============================================================
//   // COVER IMAGE EDIT
//   // ============================================================
//
//   Future<void> _onCoverImageEdit(BuildContext context) async {
//     final String? newPath = await SelectProfilePictureDialog.showLogoDialog(
//       context,
//       AppStrings.editCoverPicture,
//       cropAspectRatio: CropAspectRatio(width: 3, height: 1),
//     );
//     if (newPath == null || newPath.isEmpty) return;
//     dynamic dataImage = await multiPartImage(imagePath: newPath);
//     var reqProfile = {ApiKeys.coverpicture: dataImage};
//     await _personalCtrl.updateUserProfileDetails(
//         params: reqProfile, isFromProfileOnly: true);
//   }
// }
//
// /// Frosted-glass pill / circle used for cover-overlay buttons. Uses a
// /// BackdropFilter blur over a translucent white fill so the banner image
// /// peeks through, matching the personal-profile-header mockup.
// class _GlassPill extends StatelessWidget {
//   final Widget child;
//   final VoidCallback onTap;
//   final EdgeInsets padding;
//   final BoxShape shape;
//   final bool dark;
//
//   const _GlassPill({
//     required this.child,
//     required this.onTap,
//     required this.padding,
//     this.shape = BoxShape.rectangle,
//     this.dark = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final borderRadius =
//         shape == BoxShape.circle ? null : BorderRadius.circular(100);
//     final fill = dark
//         ? Colors.black.withValues(alpha: 0.35)
//         : Colors.white.withValues(alpha: 0.35);
//     final border = dark
//         ? Colors.white.withValues(alpha: 0.18)
//         : Colors.white.withValues(alpha: 0.5);
//     return GestureDetector(
//       onTap: onTap,
//       child: ClipPath(
//         clipper: _GlassClipper(shape: shape, borderRadius: borderRadius),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
//           child: Container(
//             padding: padding,
//             decoration: BoxDecoration(
//               color: fill,
//               borderRadius: borderRadius,
//               shape: shape,
//               border: Border.all(color: border, width: 0.6),
//             ),
//             child: child,
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _GlassClipper extends CustomClipper<Path> {
//   final BoxShape shape;
//   final BorderRadius? borderRadius;
//
//   _GlassClipper({required this.shape, this.borderRadius});
//
//   @override
//   Path getClip(Size size) {
//     final rect = Offset.zero & size;
//     if (shape == BoxShape.circle) {
//       return Path()..addOval(rect);
//     }
//     return Path()
//       ..addRRect((borderRadius ?? BorderRadius.circular(100)).toRRect(rect));
//   }
//
//   @override
//   bool shouldReclip(covariant _GlassClipper oldClipper) =>
//       oldClipper.shape != shape || oldClipper.borderRadius != borderRadius;
// }
