import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/features/common/Discover/view/discover_school_home_screen.dart';
import 'package:BlueEra/features/common/Discover/view/healthcare/discover_hospital_home_screen.dart';
import 'package:BlueEra/features/common/Discover/view/others_service_detail_screen.dart';
import 'package:BlueEra/features/common/Discover/view/self_employee_view_discover_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/discover_professionals_view_screen.dart';
import 'package:BlueEra/features/common/profile_share_preview/model/share_profile_overview_response.dart';
import 'package:BlueEra/features/common/profile_share_preview/repo/share_profile_overview_repo.dart';
import 'package:BlueEra/features/me/food/view/customer/visit_food_store_details_screen.dart';
import 'package:BlueEra/features/me/grocery/view/customer/grocery_via_self_pickup/visit_grocery_store_screen.dart';
import 'package:BlueEra/features/me/medical/view/medical_pharmacy_detail_screen.dart';
import 'package:BlueEra/features/me/product/view/customer/visit_product_store_details_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Landing screen reached from the public share deep links
/// `https://beapp.in/app/profile/{userId}` and
/// `https://beapp.in/app/business/{userId}`. Fetches the trimmed share-card
/// overview and renders a polished preview — identity hero, stats ribbon,
/// bio / objective / skills / experiences / projects / social links — plus a
/// sticky "Open Profile" CTA that hands off to the full in-app profile.
class ProfileSharePreviewScreen extends StatefulWidget {
  final String userId;

  /// Optional hint from the deep-link path ("BUSINESS" / "INDIVIDUAL"). The
  /// API response is the source of truth; this just primes the pill while the
  /// fetch is in flight.
  final String? accountTypeHint;

  const ProfileSharePreviewScreen({
    super.key,
    required this.userId,
    this.accountTypeHint,
  });

  @override
  State<ProfileSharePreviewScreen> createState() => _ProfileSharePreviewScreenState();
}

class _ProfileSharePreviewScreenState extends State<ProfileSharePreviewScreen> {
  ShareProfileOverviewResponse? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ResponseModel res = await ShareProfileOverviewRepo().getShareProfileOverview(widget.userId);
    if (!mounted) return;
    if (res.isSuccess && res.response?.data is Map<String, dynamic>) {
      final parsed = ShareProfileOverviewResponse.fromJson(res.response!.data as Map<String, dynamic>);
      setState(() {
        _data = parsed;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = AppStrings.noDataFound.tr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      extendBodyBehindAppBar: true,
      bottomNavigationBar: _data?.user == null ? null : _buildBottomBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data?.user == null
              ? _buildErrorState()
              : _buildContent(_data!),
      appBar: _loading || _data?.user == null
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.mainTextColor),
            )
          : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off_outlined, size: 48, color: AppColors.secondaryTextColor),
          SizedBox(height: SizeConfig.size8),
          CustomText(
            _error ?? AppStrings.noDataFound.tr,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size12),
          TextButton(
            onPressed: _fetch,
            child: CustomText(
              'Retry',
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ShareProfileOverviewResponse data) {
    final user = data.user!;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: SizeConfig.size16),
      child: Column(
        children: [
          _buildHero(context, user),
          _buildIdentity(user),
          Padding(
            padding: EdgeInsets.fromLTRB(SizeConfig.size12, SizeConfig.size12, SizeConfig.size12, 0),
            child: Column(
              children: _joinWithGap(
                _sections(data),
                gap: SizedBox(height: SizeConfig.size12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _sections(ShareProfileOverviewResponse data) {
    final user = data.user!;
    return [
      _buildStatsRibbon(data),
      if ((user.bio ?? '').trim().isNotEmpty)
        _section(
          icon: Icons.info_outline,
          title: 'About',
          child: ExpandableText(
            text: user.bio!.trim(),
            trimLines: 4,
            expandMode: ExpandMode.dialog,
            style: TextStyle(
              color: AppColors.secondaryTextColor,
              fontFamily: AppConstants.OpenSans,
              fontWeight: FontWeight.w400,
              fontSize: SizeConfig.medium,
              height: 1.5,
            ),
          ),
        ),
      if ((user.objective ?? '').trim().isNotEmpty)
        _section(
          icon: Icons.flag_outlined,
          title: 'Objective',
          child: CustomText(
            user.objective!.trim(),
            fontSize: SizeConfig.medium,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      if (user.skills.isNotEmpty)
        _chipsCard(
          icon: Icons.psychology_outlined,
          title: 'Skills',
          items: user.skills,
        ),
      if (user.experiences.isNotEmpty)
        _bulletCard(
          icon: Icons.work_outline_rounded,
          title: AppStrings.workExperience.tr,
          items: user.experiences,
        ),
      if (user.projects.isNotEmpty)
        _bulletCard(
          icon: Icons.folder_open_rounded,
          title: 'Projects',
          items: user.projects,
          checked: true,
        ),
      if (user.socialLinks.hasAny)
        _section(
          icon: Icons.link_rounded,
          title: 'Connect',
          child: _socialLinks(user.socialLinks),
        ),
    ];
  }

  // ── Hero ─────────────────────────────────────────────────────────────
  Widget _buildHero(BuildContext context, ShareUser user) {
    final profileImage = (user.profileImage ?? '').trim();
    final topInset = MediaQuery.of(context).padding.top;
    const coverHeight = 200.0;

    return SizedBox(
      height: coverHeight + topInset + 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: coverHeight + topInset,
            width: double.infinity,
            child: profileImage.isEmpty
                ? _coverFallback()
                : CachedNetworkImage(
                    imageUrl: profileImage,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _coverFallback(),
                    errorWidget: (_, __, ___) => _coverFallback(),
                  ),
          ),
          Positioned.fill(
            bottom: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.34),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.28),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: topInset + 6,
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            child: Row(
              children: [
                _glassButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                _glassButton(
                  icon: Icons.ios_share_rounded,
                  onTap: () async {
                    await ShareService.instance.shareProfile(
                      userId: widget.userId,
                      subject: user.name,
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            left: SizeConfig.size16,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CachedAvatarWidget(
                imageUrl: profileImage.isEmpty ? null : profileImage,
                size: SizeConfig.size80,
                borderColor: Colors.transparent,
                borderRadius: SizeConfig.size40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverFallback() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.blue5CAF, AppColors.primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );

  Widget _glassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }

  // ── Identity block ──────────────────────────────────────────────────
  Widget _buildIdentity(ShareUser user) {
    final name = (user.name ?? '').trim();
    final username = (user.username ?? '').trim();
    final accountType = (user.accountType ?? widget.accountTypeHint ?? '').trim().toUpperCase();

    return Padding(
      padding: EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size10, SizeConfig.size16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (accountType.isNotEmpty)
            Text(
              accountType,
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
                letterSpacing: 1.4,
              ),
            ),
          if (accountType.isNotEmpty) SizedBox(height: SizeConfig.size4),
          if (name.isNotEmpty)
            Text(
              name,
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                letterSpacing: -0.4,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (username.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size4),
            CustomText(
              '@$username',
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ],
          if (user.totalRatings > 0) ...[
            SizedBox(height: SizeConfig.size8),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFB400), size: 18),
                const SizedBox(width: 4),
                CustomText(
                  user.avgRating.toStringAsFixed(1),
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(width: 4),
                CustomText(
                  '(${user.totalRatings})',
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Stats ribbon: posts / followers / following ──────────────────────
  Widget _buildStatsRibbon(ShareProfileOverviewResponse data) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size14, vertical: SizeConfig.size14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.primaryColor.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: const Color(0xFFEDEFF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F001022),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _stat(
              icon: Icons.article_outlined,
              color: AppColors.primaryColor,
              value: data.totalPosts.toString(),
              label: 'POSTS'),
          _divider(),
          _stat(
              icon: Icons.people_alt_outlined,
              color: const Color(0xFF16A34A),
              value: data.followersCount.toString(),
              label: AppStrings.followers.tr.toUpperCase()),
          _divider(),
          _stat(
              icon: Icons.person_add_alt_1_outlined,
              color: AppColors.blue5CAF,
              value: data.followingCount.toString(),
              label: AppStrings.following.tr.toUpperCase()),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 44,
        margin: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
        color: AppColors.greyE5,
      );

  Widget _stat({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          SizedBox(height: SizeConfig.size6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: CustomText(
              value,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
          ),
          const SizedBox(height: 2),
          CustomText(
            label,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.secondaryTextColor,
            letterSpacing: 0.6,
          ),
        ],
      ),
    );
  }

  // ── Card shell ──────────────────────────────────────────────────────
  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDEFF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F001022),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(SizeConfig.size16, SizeConfig.size14, SizeConfig.size14, SizeConfig.size16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.18)),
                  ),
                  child: Icon(icon, size: 17, color: AppColors.primaryColor),
                ),
                SizedBox(width: SizeConfig.size10),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppConstants.OpenSans,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                      letterSpacing: 0.7,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _chipsCard({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return _section(
      icon: icon,
      title: title,
      child: Wrap(
        spacing: SizeConfig.size8,
        runSpacing: SizeConfig.size8,
        children: items
            .map((e) => Container(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.18)),
                  ),
                  child: CustomText(
                    e,
                    fontSize: SizeConfig.small,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _bulletCard({
    required IconData icon,
    required String title,
    required List<String> items,
    bool checked = false,
  }) {
    return _section(
      icon: icon,
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : SizeConfig.size10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (checked)
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, size: 12, color: AppColors.primaryColor),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(top: 7.0),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  SizedBox(width: SizeConfig.size10),
                  Expanded(
                    child: CustomText(
                      items[i],
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _socialLinks(ShareSocialLinks links) {
    final entries = <_SocialEntry>[
      if (_nonEmpty(links.website)) _SocialEntry(Icons.public, 'Website', links.website!),
      if (_nonEmpty(links.youtube)) _SocialEntry(Icons.play_circle_outline, 'YouTube', links.youtube!),
      if (_nonEmpty(links.instagram)) _SocialEntry(Icons.camera_alt_outlined, 'Instagram', links.instagram!),
      if (_nonEmpty(links.twitter)) _SocialEntry(Icons.alternate_email, 'Twitter', links.twitter!),
      if (_nonEmpty(links.linkedin))
        _SocialEntry(Icons.business_center_outlined, 'LinkedIn', links.linkedin!),
    ];
    return Wrap(
      spacing: SizeConfig.size8,
      runSpacing: SizeConfig.size8,
      children: entries
          .map((e) => GestureDetector(
                onTap: () async {
                  final uri = Uri.tryParse(e.url);
                  if (uri == null) return;
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12, vertical: SizeConfig.size8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(e.icon, size: 14, color: AppColors.primaryColor),
                      SizedBox(width: SizeConfig.size6),
                      CustomText(
                        e.label,
                        fontSize: SizeConfig.small,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  /// Routes the "Open Profile in App" CTA to the matching Discover detail
  /// screen based on `accountType` and the user's category/profession.
  ///
  /// Falls back to the generic [redirectToProfileScreen] when:
  ///   - the share response didn't include `business_category` /
  ///     `profession_type` (backend hasn't extended the payload yet);
  ///   - the category requires rich data we can't synthesise from a
  ///     userId alone (Hotel needs `HotelServiceData`, Vehicle needs a
  ///     `vehicleId` distinct from the user share id).
  void _openDetailScreen() {
    final user = _data?.user;
    final accountType =
        (user?.accountType ?? widget.accountTypeHint ?? '').toUpperCase();

    if (user == null) {
      _fallbackToProfile(accountType);
      return;
    }

    if (accountType == AppConstants.individual) {
      _openIndividualDetail(user, accountType);
    } else if (accountType == AppConstants.business) {
      _openBusinessDetail(user, accountType);
    } else {
      _fallbackToProfile(accountType);
    }
  }

  void _openIndividualDetail(ShareUser user, String accountType) {
    // Individual accounts have two specialised detail screens. The
    // distinction by `profession_type` mirrors the values used by the
    // onboarding flow (skilled work vs. consultant). Consultant-style
    // professions open the dedicated Professionals view; everything
    // else (skilled work, generic self-employed) falls into the
    // Self-Employee view.
    final type = (user.professionType ?? '').trim().toLowerCase();
    final isConsultant = type == AppConstants.consultant.toLowerCase() ||
        type.contains('consult') ||
        type.contains('professional');

    if (isConsultant) {
      Get.to(() => DiscoverProfessionalsViewScreen(userId: widget.userId));
    } else {
      Get.to(() => SelfEmployeeViewDiscoverScreen(userId: widget.userId));
    }
  }

  void _openBusinessDetail(ShareUser user, String accountType) {
    final category = (user.businessCategory ?? '').trim().toLowerCase();
    if (category.isEmpty) {
      _fallbackToProfile(accountType);
      return;
    }

    // Grocery store
    if (category.contains('grocery')) {
      Get.to(() => VisitGroceryStoreScreen(
            visitBusinessId: widget.userId,
            userId: widget.userId,
          ));
      return;
    }
    // Food / restaurant
    if (category.contains('food') ||
        category.contains('restaurant') ||
        category.contains('dhaba') ||
        category.contains('bakery')) {
      Get.to(() => VisitFoodStoreDetailsScreen(visitBusinessId: widget.userId));
      return;
    }
    // Medical / pharmacy
    if (category.contains('pharmacy') ||
        category == AppConstants.medical ||
        category.contains('medical store') ||
        category.contains('chemist')) {
      Get.to(() => MedicalPharmacyDetailScreen(businessId: widget.userId));
      return;
    }
    // Hospital sector (hospitals, clinics, diagnostic centres). The
    // hospital screen reads its state from a controller — relying on the
    // caller to seed it. Until that fetch is wired here, fall back to
    // the generic redirect so the user always lands on *something*.
    if (category.contains('hospital') ||
        category.contains('clinic') ||
        category.contains('diagnostic') ||
        category.contains('healthcare')) {
      // TODO: trigger HospitalController fetch by businessId, then
      //       Get.to(() => const DiscoverHospitalHomeScreen()).
      _fallbackToProfile(accountType);
      return;
    }
    // Hotel / stay — needs a fully fetched HotelServiceData. No
    // server-side path to construct that from just a userId on this
    // surface, so fall back for now.
    if (category.contains('hotel') ||
        category.contains('stay') ||
        category.contains('hostel') ||
        category.contains('lodge')) {
      // TODO: fetch HotelServiceData by businessId, then
      //       Get.to(() => HotelDiscoverHomeScreen(data: fetched)).
      _fallbackToProfile(accountType);
      return;
    }
    // School / education
    if (category.contains('school') ||
        category.contains('education') ||
        category.contains('coaching') ||
        category.contains('college')) {
      // DiscoverSchoolHomeScreen reads its state from
      // SchoolAboutUsController. A future improvement: seed the
      // controller here before navigating. Direct nav still works
      // (empty state) but the fallback is friendlier today.
      Get.to(() => DiscoverSchoolHomeScreen());
      return;
    }
    // Vehicle — vehicle detail takes a vehicleId, not a user/business
    // id. A profile share doesn't map to one specific vehicle, so we
    // can't open VehicleDetailScreen from here.
    if (category.contains('vehicle') || category.contains('automotive')) {
      // TODO: route to a "vehicles by this seller" listing instead.
      _fallbackToProfile(accountType);
      return;
    }
    // Generic product store (furniture, fashion, electronics, jewellery,
    // sports, toys, books, pet, construction, etc.). The shared
    // VisitProductStoreDetailsScreen is the customer-facing store view
    // for any business whose category is a "Store" or general "Product"
    // sub-type. Kept above the services catch-all because "Store" can
    // co-occur with the literal word "Service" in some category labels.
    if (category.contains('store') ||
        category.contains('product') ||
        category.contains('shop') ||
        category.contains('retail') ||
        category.contains('furniture') ||
        category.contains('fashion') ||
        category.contains('electronic') ||
        category.contains('jewel') ||
        category.contains('sports') ||
        category.contains('toys') ||
        category.contains('books') ||
        category.contains('stationery') ||
        category.contains('pet') ||
        category.contains('construction')) {
      Get.to(() => VisitProductStoreDetailsScreen(visitUserId: widget.userId));
      return;
    }
    // Generic services (consulting, IT, beauty, home, etc.) → the
    // shared "other services" detail.
    if (category.contains('service') ||
        category.contains('consulting') ||
        category.contains('beauty') ||
        category.contains('logistics') ||
        category.contains('financial') ||
        category.contains('event') ||
        category.contains('media') ||
        category.contains('travel') ||
        category.contains('tour')) {
      Get.to(() => OthersServiceDetailScreen(visitUserId: widget.userId));
      return;
    }

    _fallbackToProfile(accountType);
  }

  void _fallbackToProfile(String accountType) {
    redirectToProfileScreen(
      accountType: accountType,
      profileId: widget.userId,
      screenName: AppConstants.deepLinkScreen,
    );
  }

  // ── Sticky bottom CTA ───────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size12,
        SizeConfig.size16,
        SizeConfig.size14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.greyE5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: _openDetailScreen,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.blue5CAF, AppColors.primaryColor],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: CustomText(
            'Open Profile in App',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  List<Widget> _joinWithGap(List<Widget> items, {required Widget gap}) {
    if (items.isEmpty) return const [];
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) result.add(gap);
      result.add(items[i]);
    }
    return result;
  }
}

class _SocialEntry {
  final IconData icon;
  final String label;
  final String url;
  const _SocialEntry(this.icon, this.label, this.url);
}

bool _nonEmpty(String? s) => s != null && s.trim().isNotEmpty;
