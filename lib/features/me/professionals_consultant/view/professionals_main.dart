import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/widgets/home_tab_scaffold.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/widgets/business_share_banner.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/widget/me_tab_back_handler_mixin.dart';
import 'package:BlueEra/features/me/professionals_consultant/widget/professionals_inquiry_tab.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_property_card.dart';
import 'package:BlueEra/features/common/statistics/view/profile_statistics_screen.dart';
import 'package:BlueEra/features/common/visiting_card/view/all_personal_visiting_cards.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/ai_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/view/professionals_service_screen.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_store_section.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/edit_profile_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/profile_designation_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/personal_qrcode_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_bio_card.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_location_card.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Professionals dashboard (v2) â€” mirrors self_employee_screen.dart's
/// shell: floating glassmorphic top bar, custom animated-underline
/// tabs card with a sticky overlay on scroll, and five tab bodies:
///   â€¢ Order    â€” contribution peek
///   â€¢ Overview â€” cover + profile + stats + share/business-card
///   â€¢ Service  â€” [ProfessionalsServiceScreen] (expertise, services,
///                portfolio, certificates, gallery, contact, hours)
///   â€¢ Post     â€” embedded [FeedScreen] filtered to the user's posts
///   â€¢ Statics  â€” chat-click analytics
class ProfessionalsMainScreen extends StatefulWidget {
  const ProfessionalsMainScreen({super.key});

  @override
  State<ProfessionalsMainScreen> createState() => _ProfessionalsMainScreenState();
}

class _ProfessionalsMainScreenState extends State<ProfessionalsMainScreen>
    with SingleTickerProviderStateMixin, MeTabBackHandlerMixin {
  final _ctrl = Get.put(AiProfessionalsController());
  final _personalCtrl = getOrPut(() => PersonalCreateProfileController());
  final _viewCtrl = getOrPut(() => ViewPersonalDetailsController(), permanent: true);

  late final TabController _tabController;

  List<String> get _tabs => [
        AppStrings.order.tr,
        AppStrings.overview.tr,
        AppStrings.service.tr,
        AppStrings.store.tr,
        AppStrings.post.tr,
        AppStrings.proConsultTabStatics.tr,
      ];

  // Drives the inquiry list shown under the Order tab â€” same controller
  // the Connect screen uses, so socket-driven updates land on both.
  final ChatViewController _chatViewController = getOrPut(() => ChatViewController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      initialIndex: 0,
      vsync: this,
    );
    registerMeTabBackHandler(_tabController);
    // No blocking progress dialog on screen entry — load silently.
    _ctrl.professionalsFullDetailsController(showProgress: false);
    _viewCtrl.UserFollowersAndPostsCount(userId);
    // Hydrate the business chat list so the Order tab's inquiry list
    // has data ready when the user switches to it. Mirrors what
    // ConnectMainPage does for its Inquiry tab.
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewCtrl.shopStatusOpenClose.value =
          serviceProviderStatusGlobal.toUpperCase() == AppConstants.OPEN.toUpperCase();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final topBarHeight = topInset + 56;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            HomeTabScaffold(
              controller: _tabController,
              tabLabels: _tabs,
              topBar: _buildTopBar(),
              topBarHeight: topBarHeight,
              tabViews: [
                _tabScroll([
                  ProfessionalsInquiryTab(
                    onAddServices: () => _tabController.animateTo(2),
                  ),
                ]),
                _tabScroll(_buildOverviewTab()),
                _tabScroll(_buildServiceTab()),
                _tabScroll(const [EarnStoreCards()]),
                _tabScroll(_buildPostTab()),
                _tabScroll(_buildStaticsTab()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x42001120),
            blurRadius: 16,
            offset: Offset(0, 0),
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size12,
              topInset + SizeConfig.size8,
              SizeConfig.size12,
              SizeConfig.size10,
            ),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              border: Border.all(color: Colors.white, width: 1.0),
            ),
            child: Row(
              children: [
                _circleIconButton(
                  icon: Icons.menu,
                  onTap: () => _openDrawer(context),
                ),
                SizedBox(width: SizeConfig.size6),
                // Screen-local shadow wrapper lifts the refer pill off the
                // cover image without touching the shared ReferEarnPill widget.
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const ReferEarnPill(),
                  ),
                ),
                const Spacer(),
                _goLivePill(),
                // Notification sits at the very end of the bar.
                if (!isGuestUser()) ...[
                  SizedBox(width: SizeConfig.size6),
                  _circleIconButton(
                    icon: Icons.notifications_none,
                    onTap: () => Navigator.pushNamed(
                      context,
                      RouteHelper.getNotificationScreenRoute(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            // Drop shadow so the circular controls lift off the cover image.
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: CircleBorder()),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: SizeConfig.size36,
              width: SizeConfig.size36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFFC9CDD5),
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 20, color: AppColors.secondaryTextColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _goLivePill() {
    return Obx(
      () => GoLivePill(
        value: _viewCtrl.shopStatusOpenClose.value,
        isUpdating: _viewCtrl.isShopStatusUpdating.value,
        onTap: () => _viewCtrl.toggleShopStatus(),
        label: AppStrings.proConsultGoLive.tr,
      ),
    );
  }

  void _openDrawer(BuildContext context) {
    showDialog(
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      useSafeArea: false,
      context: context,
      builder: (_) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: double.infinity,
          child: Drawer(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: ProfileMenuDrawer(),
          ),
        ),
      ),
    );
  }

  /// Wraps a tab's content list in a scrollable body for the [TabBarView].
  /// The per-tab builders return bounded box widgets, so SingleChildScrollView
  /// + Column reproduces the previous SliverToBoxAdapter + Column layout.
  Widget _tabScroll(List<Widget> children) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: SizeConfig.size10,
        bottom: kBottomNavigationBarHeight + 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  List<Widget> _buildOverviewTab() {
    return [
      _buildIdentityCard(context),
      SizedBox(height: SizeConfig.size12),
      _buildStatsCard(),
      SizedBox(height: SizeConfig.size12),
      // Dedicated bio tile â€” reads as identity content, not secondary
      // detail. Bio used to live inside the identity block; lifting
      // it here gives it a clear edit affordance.
      const ProfileBioCard(),
      SizedBox(height: SizeConfig.size12),
      // _buildRentalCard(),
      const RentalPropertyCard(),
      SizedBox(height: SizeConfig.size12),
      _buildActionRow(),
      SizedBox(height: SizeConfig.size12),
      const ProfileLocationCard(),
      SizedBox(height: SizeConfig.size12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Obx(() => WebsiteOverviewCard(
              websiteUrl: _viewCtrl.website.value,
              onSave: (url) => _personalCtrl.updateUserProfileDetails(
                params: {ApiKeys.website: url},
                isFromProfileOnly: true,
              ),
            )),
      ),
      SizedBox(height: SizeConfig.size12),
      _buildQrCard(),
      SizedBox(height: SizeConfig.size12),
      _buildShareBanner(),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  List<Widget> _buildServiceTab() {
    return [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Obx(() {
          final hasProfile = _ctrl.hasProfile.value;
          final data = _ctrl.getProfessionalServiceRes?.value.data;
          if (hasProfile && data != null) {
            return ProfessionalsServiceScreen();
          }
          return _buildCreateProfessionalCta();
        }),
      ),
    ];
  }

  Widget _buildCreateProfessionalCta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14001120),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.business_center_rounded,
                size: 26,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: SizeConfig.size12),
            Text(
              AppStrings.proConsultCreateProfileTitle.tr,
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size6),
            Text(
              AppStrings.proConsultCreateProfileBody.tr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size16),
            Obx(() {
              final loading = _ctrl.isCreatingProfile.value;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : _onCreateProfessionalProfile,
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  label: Text(
                    loading ? AppStrings.proConsultCreating.tr : AppStrings.proConsultCreateProfessionalProfile.tr,
                    style: TextStyle(
                      fontFamily: AppConstants.OpenSans,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(
                      vertical: SizeConfig.size12,
                      horizontal: SizeConfig.size16,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _onCreateProfessionalProfile() async {
    final user = _viewCtrl.personalProfileDetails.value.user;
    if (user == null) return;
    await _ctrl.createMinimalProfessionalProfile(userProfile: {
      'name': user.name,
      'email': user.email,
      'gender': user.gender,
      'profession': user.profession,
      'designation': user.designation,
      'pincode': user.pincode,
      'address': user.address,
    });
  }

  // Cover banner with the avatar straddling the seam, followed by
  // the professional-specific name / designation / bio / contact
  // rows. Mirrors the layout used by self_employee_screen.dart.
  Widget _buildIdentityCard(BuildContext context) {
    const bannerHeight = 200.0;
    const avatarSize = 88.0;
    const avatarOverlap = avatarSize / 2;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: CustomFormCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            children: [
              SizedBox(
                height: bannerHeight + avatarOverlap,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: bannerHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(child: _bannerImage()),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.18),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: _glassActionPill(
                              icon: Icons.camera_alt_rounded,
                              label: AppStrings.editCover.tr,
                              onTap: () => _onCoverImageEdit(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _avatarFrame(avatarSize),
                          SizedBox(width: SizeConfig.size12),
                          Padding(
                            padding: EdgeInsets.only(bottom: avatarOverlap - 4),
                            child: _memberSincePill(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildIdentityBlock(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bannerImage() {
    return Obx(() {
      final banner = _personalCtrl.coverImagePath?.value ?? '';
      if (banner.isNotEmpty) {
        return Image.network(banner, fit: BoxFit.cover);
      }
      final fallback = _personalCtrl.imagePath?.value ?? '';
      if (fallback.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: fallback,
          fit: BoxFit.cover,
          placeholder: (_, __) => _coverFallback(),
          errorWidget: (_, __, ___) => _coverFallback(),
        );
      }
      return _coverFallback();
    });
  }

  Widget _coverFallback() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor.withValues(alpha: 0.18),
              AppColors.primaryColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );

  Widget _avatarFrame(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Obx(() {
          return CommonProfileImage(
            imagePath: _personalCtrl.imagePath?.value ?? '',
            onImageUpdate: (image) async {
              _personalCtrl.imagePath?.value = image;
              dynamic dataImage = await multiPartImage(imagePath: image);
              var reqProfile = {ApiKeys.profile_image: dataImage};
              await _personalCtrl.updateUserProfileDetails(params: reqProfile, isFromProfileOnly: true);
            },
            dialogTitle: AppStrings.uploadProfilePicture,
            showProfileBorder: false,
          );
        }),
      ),
    );
  }

  Widget _memberSincePill() {
    return Obx(() {
      final createdAt = _viewCtrl.personalProfileDetails.value.user?.createdAt ?? '';
      if (createdAt.isEmpty) return const SizedBox.shrink();
      final since = _formatJoinedDate(createdAt);
      if (since.isEmpty) return const SizedBox.shrink();
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size4,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE4D2A6),
            width: 0.6,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14001120),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 12,
              color: const Color(0xFFB7781F),
            ),
            const SizedBox(width: 4),
            Text(
              '${AppStrings.proConsultMemberPrefix.tr} · $since',
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B3A00),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildIdentityBlock() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        SizeConfig.size8,
        20,
        SizeConfig.size20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final user = _viewCtrl.personalProfileDetails.value.user;
            final profData = _ctrl.getProfessionalServiceRes?.value.data;
            final name = _capitalizeFirst(profData?.basicDetails?.fullName ?? user?.name ?? '');
            final username = user?.username ?? '';
            final designation = profData?.basicDetails?.professionalTitle ?? user?.designation ?? '';
            final bio =
                profData?.basicDetails?.shortTagline ?? profData?.about?.description ?? user?.bio ?? '';
            // Address is rendered in [ProfileLocationCard] now â€” don't
            // duplicate it inside the identity card.
            final dob = user?.dateOfBirth;
            final email = profData?.contact?.email ?? user?.email ?? '';
            final phone = profData?.contact?.phone ?? user?.contactNo ?? '';

            final hasDesignation = designation.trim().isNotEmpty;
            final hasName = name.isNotEmpty;
            final hasUsername = username.isNotEmpty;
            final hasBio = bio.isNotEmpty;
            final hasPhone = phone.isNotEmpty;
            final hasEmail = email.isNotEmpty;
            final hasDob = dob != null && dob.date != null && dob.month != null;
            final hasContact = hasPhone || hasEmail || hasDob;
            final hasAnyIdentity = hasDesignation || hasName || hasUsername || hasBio || hasContact;

            final children = <Widget>[];

            if (hasDesignation) {
              children.add(_designationEyebrow(designation));
            }

            if (hasName) {
              if (children.isNotEmpty) {
                children.add(SizedBox(height: SizeConfig.size6));
              }
              children.add(_nameRow(name));
            } else if (hasAnyIdentity) {
              if (children.isNotEmpty) {
                children.add(SizedBox(height: SizeConfig.size8));
              }
              children.add(
                Align(
                  alignment: Alignment.centerRight,
                  child: _editChip(
                    onTap: () => EditProfileBottomSheet.show(Get.context!),
                    label:AppStrings.edit,
                    icon: Icons.edit_outlined,
                  ),
                ),
              );
            }

            if (hasUsername) {
              children.add(const SizedBox(height: 4));
              children.add(_usernameText(username));
            }

            // Bio rendering has moved to its own [ProfileBioCard]
            // tile in the overview list â€” the identity block no
            // longer carries it. `hasBio` still feeds the
            // `hasAnyIdentity` aggregate so the fallback Edit chip
            // still appears when the user has a bio but no name.

            if (hasContact) {
              children.add(SizedBox(height: SizeConfig.size12));
              children.add(Container(
                height: 1,
                color: const Color(0xFFEDEFF4),
              ));
              children.add(SizedBox(height: SizeConfig.size12));
              if (hasPhone) {
                children.add(_infoRow(Icons.phone_rounded, phone));
              }
              if (hasDob) {
                if (children.last is! SizedBox) {
                  children.add(SizedBox(height: SizeConfig.size8));
                }
                children.add(_infoRow(Icons.cake_rounded, '${AppStrings.proConsultBornPrefix.tr} ${_formatDob(dob)}'));
              }
              if (hasEmail) {
                if (children.last is! SizedBox) {
                  children.add(SizedBox(height: SizeConfig.size8));
                }
                children.add(_infoRow(Icons.alternate_email_rounded, email));
              }
            }

            if (children.isEmpty) {
              return _completeProfileCta();
            }

            return Padding(
              padding: EdgeInsets.only(top: SizeConfig.size12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _designationEyebrow(String designation) {
    return InkWell(
      onTap: () => showProfileDesignationSheet(Get.context!),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 1.5,
            color: AppColors.primaryColor,
          ),
          SizedBox(width: SizeConfig.size8),
          Flexible(
            child: Text(
              designation.toUpperCase(),
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
                letterSpacing: 1.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameRow(String name) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontFamily: AppConstants.OpenSans,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
              height: 1.1,
              letterSpacing: -0.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        _editChip(
          onTap: () => EditProfileBottomSheet.show(Get.context!),
          label: AppStrings.edit,
          icon: Icons.edit_outlined,
        ),
      ],
    );
  }

  Widget _usernameText(String username) {
    return Text(
      '@$username',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryTextColor,
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _completeProfileCta() {
    return Padding(
      padding: EdgeInsets.only(top: SizeConfig.size12),
      child: InkWell(
        onTap: () => EditProfileBottomSheet.show(Get.context!),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14,
            vertical: SizeConfig.size12,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.account_circle_outlined, size: 20, color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: Text(
                  AppStrings.completeProfile.tr,
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editChip({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.primaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: AppColors.primaryColor),
        ),
        SizedBox(width: SizeConfig.size10),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.mainTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _glassActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.30),
                width: 0.6,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€ STATS CARD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: CustomFormCard(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16,
          vertical: SizeConfig.size16,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
        child: Obx(() {
          final followers = _viewCtrl.followersCount.value;
          final following = _viewCtrl.followingCount.value;
          final posts = _viewCtrl.postsCount.value;
          return Row(
            children: [
              Expanded(child: _statTile(label: AppStrings.posts.tr, value: '$posts')),
              _statSeam(),
              Expanded(
                child: _statTile(
                  label: AppStrings.followers.tr,
                  value: _formatCount(followers),
                  onTap: () => Get.to(() => FollowersFollowingPage(tabIndex: 1, userID: userId)),
                ),
              ),
              _statSeam(),
              Expanded(
                child: _statTile(
                  label: AppStrings.following.tr,
                  value: _formatCount(following),
                  onTap: () => Get.to(() => FollowersFollowingPage(tabIndex: 0, userID: userId)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final tile = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppConstants.OpenSans,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            letterSpacing: -0.4,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: AppConstants.OpenSans,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.secondaryTextColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 18,
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
    if (onTap == null) return tile;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: tile,
      ),
    );
  }

  Widget _statSeam() {
    return Container(
      height: 36,
      width: 1,
      color: const Color(0xFFEDEFF4),
    );
  }

  // â”€â”€â”€ ACTION ROW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildActionRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _actionPill(
              icon: Icons.share_outlined,
              label: AppStrings.shareProfile.tr,
              filled: false,
              onTap: _onShareProfile,
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: _actionPill(
              icon: Icons.contact_page_outlined,
              label: AppStrings.personalCards.tr,
              filled: true,
              onTap: () => Get.to(() => AllPersonalVisitingCards(
                    personalDetails: _viewCtrl.personalProfileDetails.value,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionPill({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final fg = filled ? Colors.white : AppColors.primaryColor;
    final bg = filled ? AppColors.primaryColor : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: filled ? 1 : 0.30),
            width: filled ? 0 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: filled ? AppColors.primaryColor.withValues(alpha: 0.30) : const Color(0x14001120),
              blurRadius: filled ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onShareProfile() async {
    // Profile share goes through ShareService so the message body
    // and accountType branching live in one place app-wide.
    final userName = _viewCtrl.personalProfileDetails.value.user?.name ?? '';
    await ShareService.instance.shareProfile(userId: userId, subject: userName);
  }

  // Delegates to [PersonalQrCodeWidget] so the professional QR card
  // matches the business card's UI and behaviour exactly. Prefers
  // the professional-service basic details when available, falling
  // back to the personal profile.
  Widget _buildQrCard() {
    return Obx(() {
      final user = _viewCtrl.personalProfileDetails.value.user;
      final profData = _ctrl.getProfessionalServiceRes?.value.data;
      final name = _capitalizeFirst(profData?.basicDetails?.fullName ?? user?.name ?? 'Profile');
      final designation = profData?.basicDetails?.professionalTitle ?? user?.designation ?? '';
      return PersonalQrCodeWidget(
        userId: userId,
        name: name,
        designation: designation,
        margin: const EdgeInsets.symmetric(horizontal: 20),
      );
    });
  }

  // Reuses the same [BusinessShareBanner] grocery v2 ships, but
  // passes professional/individual overrides so the banner renders
  // with the user's name, profile photo and designation â€” the
  // banner falls back to the registered business profile only when
  // no overrides are supplied.
  Widget _buildShareBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() {
        final user = _viewCtrl.personalProfileDetails.value.user;
        final profData = _ctrl.getProfessionalServiceRes?.value.data;
        final name = _capitalizeFirst(profData?.basicDetails?.fullName ?? user?.name ?? '');
        final photo = (_personalCtrl.imagePath?.value.trim().isNotEmpty ?? false)
            ? _personalCtrl.imagePath?.value
            : user?.profileImage;
        final subCategory = profData?.basicDetails?.professionalTitle ?? user?.designation ?? '';
        return BusinessShareBanner(
          overrideName: name,
          overridePhoto: photo,
          overrideSubCategory: subCategory,
          accountType: AppConstants.individual,
        );
      }),
    );
  }

  List<Widget> _buildPostTab() {
    if (!Get.isRegistered<FeedController>()) {
      Get.put(FeedController());
    }
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        child: _createPostCta(),
      ),
      SizedBox(height: SizeConfig.size12),
      FeedScreen(
        key: const ValueKey('professionals_my_posts'),
        postFilterType: PostType.myPosts,
        id: userId,
        isInParentScroll: true,
        horizontalPaddingChannel: SizeConfig.size12,
      ),
    ];
  }

  Widget _createPostCta() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: _showCreatePostDialog,
        icon: const Icon(Icons.add, size: 18, color: Colors.white),
        label: CustomText(AppStrings.createPost.tr,
            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16, vertical: SizeConfig.size8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _showCreatePostDialog() async {
    final isBusiness = isBusinessUser();
    final entries = <_PostMenuEntry>[
      _PostMenuEntry(
        type: PostCreationMenu.message,
        label: AppStrings.lekha.tr,
        iconAsset: AppIconAssets.message_post,
      ),
      _PostMenuEntry(
        type: PostCreationMenu.symbol,
        label: AppStrings.symbol.tr,
        iconAsset: 'assets/icons/add_symbol_color.png',
      ),
      _PostMenuEntry(
        type: PostCreationMenu.poll,
        label: AppStrings.poll.tr,
        iconAsset: AppIconAssets.qa_ask_questionOutlinedIcon,
      ),
      _PostMenuEntry(
        type: PostCreationMenu.reel,
        label: 'Reel',
        iconAsset: AppIconAssets.video_outline,
      ),
      if (isBusiness)
        _PostMenuEntry(
          type: PostCreationMenu.jobPost,
          label: AppStrings.jobPost.tr,
          iconAsset: AppIconAssets.uilSuitcaseOutlinedIcon,
        ),
    ];
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(AppStrings.createPost.tr,
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.mainTextColor),
              SizedBox(height: SizeConfig.size12),
              for (var i = 0; i < entries.length; i++) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _handlePostMenu(entries[i].type);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size10, horizontal: SizeConfig.size4),
                    child: Row(
                      children: [
                        LocalAssets(imagePath: entries[i].iconAsset, height: 24, width: 24),
                        SizedBox(width: SizeConfig.size12),
                        CustomText(entries[i].label,
                            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.mainTextColor),
                      ],
                    ),
                  ),
                ),
                if (i != entries.length - 1) Divider(height: 1, color: Colors.grey.shade200),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handlePostMenu(PostCreationMenu type) {
    switch (type) {
      case PostCreationMenu.message:
      case PostCreationMenu.poll:
      case PostCreationMenu.reel:
        postVia(context, type);
        break;
      case PostCreationMenu.jobPost:
        Get.toNamed(RouteHelper.getCreateJobPostScreenRoute(), arguments: {
          'isEditMode': false,
          'jobId': '',
          'createJobVia': 'business',
        });
        break;
      case PostCreationMenu.symbol:
        Get.to(() => AddChatSymbolScreen());
        break;
    }
  }

  // â”€â”€â”€ STATICS TAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<Widget> _buildStaticsTab() {
    return [
      ProfileStatisticsScreen(userId: userId),
      SizedBox(height: SizeConfig.size12),
      const EarnStatSections(),
      SizedBox(height: SizeConfig.size16),
    ];
  }

  // â”€â”€â”€ COVER IMAGE EDIT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _onCoverImageEdit(BuildContext context) async {
    final String? newPath = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.editCoverPicture,
      cropAspectRatio: CropAspectRatio(width: 3, height: 2),
    );
    if (newPath == null || newPath.isEmpty) return;
    dynamic dataImage = await multiPartImage(imagePath: newPath);
    var reqProfile = {ApiKeys.coverpicture: dataImage};
    await _personalCtrl.updateUserProfileDetails(params: reqProfile, isFromProfileOnly: true);
  }

  // â”€â”€â”€ TEXT HELPERS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  String _formatJoinedDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return '';
    }
  }

  String _formatDob(DateOfBirth dob) {
    final months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final month = (dob.month != null && dob.month! >= 1 && dob.month! <= 12) ? months[dob.month!] : '';
    final day = dob.date?.toString() ?? '';
    if (month.isEmpty && day.isEmpty) return '';
    return '$day $month'.trim();
  }
}

class _PostMenuEntry {
  final PostCreationMenu type;
  final String label;
  final String iconAsset;

  const _PostMenuEntry({
    required this.type,
    required this.label,
    required this.iconAsset,
  });
}
