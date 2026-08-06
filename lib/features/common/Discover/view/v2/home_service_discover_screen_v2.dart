import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/service/controller/service_controller.dart';
import 'package:BlueEra/features/common/Discover/view/v2/home_service_discover_details_screen_v2.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_dashboard_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/home_service_profile_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:BlueEra/features/common/search/model/store_search_config.dart';
import 'package:BlueEra/features/common/search/view/store_search_screen.dart';

/// Home service discover — **v2**.
///
/// Replaces the earn-profile store list with the user's posted **home
/// services**, organised by a category tab strip (Tailor / Beautician /
/// Interior Designer / Digital Marketing — from
/// [ServiceController.serviceCategoryOptions]). Tapping a tab refetches
/// `getBusinessServices` (providerType = **user**) scoped to that category.
class HomeServiceDiscoverScreenV2 extends StatefulWidget {
  const HomeServiceDiscoverScreenV2({super.key, this.initialCategoryName});

  /// Category tab to open on, by display name ('Tailor', 'Beautician', …).
  ///
  /// Set by the Discover folder sheet so tapping a service there lands on that
  /// service rather than on whichever one happens to be first. Null, or a name
  /// this screen doesn't carry, keeps the default.
  final String? initialCategoryName;
  @override
  State<HomeServiceDiscoverScreenV2> createState() =>
      _HomeServiceDiscoverScreenV2State();
}

class _HomeServiceDiscoverScreenV2State
    extends State<HomeServiceDiscoverScreenV2> {
  // Tagged so this screen keeps its own service list, independent of the
  // owner-facing ServiceController instances used elsewhere.
  static const String _ctrlTag = 'homeServiceDiscoverV2';
  static const String _subType = 'homeService';
  static const Color _primary = AppColors.primaryColor;
  static const Color _primaryDeep = AppColors.blue5CAF;

  final controller = getOrPut(() => ServiceController(), tag: _ctrlTag);
  final List<ServiceCategoryOption> _categories =
      ServiceController.serviceCategoryOptions;
  /// Opens on the category the caller named, else the first.
  ///
  /// Matched loosely — case and punctuation stripped from both sides — because
  /// the name arrives from the Discover catalogue, which writes its own labels
  /// and need not spell them exactly as this list does.
  late ServiceCategoryOption _selected = _categories.firstWhere(
    (c) => _normalisedCategory(c.name) == _normalisedCategory(widget.initialCategoryName),
    orElse: () => _categories.first,
  );

  static String _normalisedCategory(String? value) =>
      (value ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  final List<String> _bannerImages = const [
    // Electrical repair, home cleaning, plumbing. Each URL was downloaded and
    // viewed before committing — the freepik links these replace ignored their
    // slugs (the "handyman" one served a beauty portrait) and watermarked
    // whatever they did serve.
    "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=1380&q=80",
    "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=1380&q=80",
    "https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=1380&q=80",
  ];

  @override
  void initState() {
    super.initState();
    // Defer: getBusinessServices() clears the list + flips loading flags
    // synchronously, which would notify an Obx mid-build otherwise.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetch(useCache: true);
    });
  }

  @override
  void dispose() {
    // Keep the tagged controller (and its cached list) alive across re-entry so
    // the freshness guard can skip a redundant refetch within the cache TTL.
    super.dispose();
  }

  /// Earn-service query (`earn-service/services`) for the active category.
  /// providerType is **user** (not business) so only user-posted home services
  /// come back; `all: true` fetches the full set for the subType.
  Map<String, dynamic> _queryParams() => {
        ApiKeys.all: true,
        ApiKeys.type: AppConstants.service,
        ApiKeys.providerType: ProviderType.user.title,
        ApiKeys.subType: _subType,
        ApiKeys.category: _selected.tagId,
      };

  void _fetch({bool isLoadMore = false, bool useCache = false}) {
    if (!isLoadMore && useCache) {
      // Screen (re-)entry: skip the network call if the same category's data is
      // already loaded and still fresh.
      controller.getEarnServicesIfNeeded(_queryParams());
    } else {
      controller.getEarnServices(_queryParams(), isLoadMore: isLoadMore);
    }
  }

  void _onCategoryTap(ServiceCategoryOption category) {
    if (_selected.tagId == category.tagId) return;
    setState(() => _selected = category);
    _fetch();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      _fetch(isLoadMore: true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.blue5CAF.withValues(alpha: 0.1),
                      AppColors.blue5CAF.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    BannerCarousel(
                      images: _bannerImages,
                      onBack: () => Navigator.of(context).pop(),
                      statusBarHeight: statusBarHeight,
                      backgroundColor: Colors.transparent,
                      bottomBorderSide: const BorderSide(
                        color: AppColors.white,
                        width: 2,
                      ),
                    ),
                    SizedBox(height: SizeConfig.size12),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: StickyCategoryHeaderDelegate(
                topPadding: statusBarHeight,
                // The header paints a search bar; this is what it opens —
                // the shared store search, scoped to this vertical by its
                // StoreSearchConfig. Tapping a result opens that profile.
                onSearchTap: () => Get.to(
                    () => StoreSearchScreen(config: StoreSearchConfig.homeServices())),
                categories: _categories
                    .map((c) => StickyCategory(
                          id: c.tagId,
                          name: c.name,
                          imageUrl: c.image,
                        ))
                    .toList(),
                selectedId: _selected.tagId,
                onCategoryTap: (item) {
                  final match = _categories.firstWhere(
                    (c) => c.tagId == item.id,
                    orElse: () => _selected,
                  );
                  _onCategoryTap(match);
                },
                onBack: () => Navigator.of(context).pop(),
                expandedLabelColor: AppColors.white,
                backgroundGradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.blue5CAF.withValues(alpha: 0.1),
                    AppColors.blue5CAF.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ],
          body: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: _buildContent(),
          ),
            ),
            if (isIndividualUser())
              Positioned(
                right: 16,
                bottom: 0,
                child: SafeArea(child: _buildPostFab()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListHeader(),
        Expanded(
          child: Obx(() {
            final services = controller.serviceDataList;
            if (controller.isServiceDataFirstLoading.value &&
                services.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (services.isEmpty) {
              return _buildEmptyState();
            }
            final showMoreSpinner =
                controller.isServiceDataLoadingMore.value;
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size12,
                0,
                SizeConfig.size12,
                kBottomNavigationBarHeight + 20,
              ),
              itemCount: services.length + (showMoreSpinner ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == services.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return _serviceCard(services[index]);
              },
            );
          }),
        ),
      ],
    );
  }

  // ── List header ────────────────────────────────────────────────────────────
  Widget _buildListHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size14,
        SizeConfig.size12,
        SizeConfig.size14,
        SizeConfig.size8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: CustomText(
              '${_selected.name} Services Near You',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
              letterSpacing: 0.2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(height: 1, color: AppColors.mainTextColor),
          ),
        ],
      ),
    );
  }

  // ── Service card ───────────────────────────────────────────────────────────
  Widget _serviceCard(GetServiceModel service) {
    final photo =
        (service.photos?.isNotEmpty ?? false) ? service.photos!.first : '';
    final hasTiming = service.timings?.isNotEmpty ?? false;
    final start = hasTiming ? (service.timings!.first.start ?? '') : '';
    final end = hasTiming ? (service.timings!.first.end ?? '') : '';
    final subtitle = (service.providerDetails?.name?.trim().isNotEmpty ?? false)
        ? service.providerDetails!.name!.trim()
        : ((service.businessName?.trim().isNotEmpty ?? false)
            ? service.businessName!.trim()
            : (service.category ?? '').trim());
    final facilities = (service.facilities ?? const <String>[])
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();
    final priceStr =
        '₹${service.priceRange?.min ?? 0} - ₹${service.priceRange?.max ?? 0}';
    // Provider userId — the details screen resolves the earn-profile "store"
    // from this. Prefer serviceProvider.id, then providerDetails.id, then the
    // top-level userId.
    final providerUserId = (service.serviceProvider?.id ??
            service.providerDetails?.id ??
            service.userId ??
            '')
        .trim();

    return InkWell(
      onTap: providerUserId.isEmpty
          ? null
          : () => Get.to(
              () => HomeServiceDiscoverDetailsScreenV2(service: service)),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: EdgeInsets.only(bottom: SizeConfig.size14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14001120),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image + "open hours" chip
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: photo.isEmpty
                        ? Container(
                            color: const Color(0xFFEDEFF4),
                            child: Icon(
                              Icons.home_repair_service_rounded,
                              size: 42,
                              color: AppColors.secondaryTextColor,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: photo,
                            fit: BoxFit.cover,
                            memCacheWidth: 800,
                            placeholder: (_, __) =>
                                Container(color: const Color(0xFFEDEFF4)),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFFEDEFF4),
                              child: Icon(
                                Icons.home_repair_service_rounded,
                                size: 42,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          ),
                  ),
                ),
                if (hasTiming && (start.isNotEmpty || end.isNotEmpty))
                  Positioned(
                    right: SizeConfig.size12,
                    bottom: SizeConfig.size12,
                    child: _timingPill(start, end),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(SizeConfig.size14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    service.title ?? '-',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    CustomText(
                      subtitle,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (facilities.isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size10),
                    ...facilities.take(3).map(_facilityRow),
                    if (facilities.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: CustomText(
                          '+${facilities.length - 3} more',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                      ),
                  ],
                  SizedBox(height: SizeConfig.size12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            'Starting From',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryTextColor,
                          ),
                          const SizedBox(height: 2),
                          CustomText(
                            priceStr,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _primary,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.30),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            CustomText(
                              'View',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A single facility line — green check + label — shown on the service card.
  Widget _facilityRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 14, color: AppColors.green00),
          const SizedBox(width: 6),
          Expanded(
            child: CustomText(
              text,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timingPill(String start, String end) {
    final label = [start, end].where((t) => t.isNotEmpty).join(' - ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F001120),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 14, color: AppColors.green00),
          const SizedBox(width: 6),
          CustomText(
            'Open | $label',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.green00,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_repair_service_outlined,
                size: 64, color: AppColors.greyAF),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              'No ${_selected.name} services found nearby.',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Floating "Post Service" action — a gradient extended FAB pill, so the add
  /// affordance no longer crowds the banner/category header.
  Widget _buildPostFab() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onPostTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primary, _primaryDeep],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.40),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_business_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              CustomText(
                'Post Service',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                letterSpacing: 0.2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPostTap() {
    if (isGuestUser() || isBusinessUser()) return;
    final viewProfileController =
        Get.isRegistered<ViewPersonalDetailsController>()
            ? Get.find<ViewPersonalDetailsController>()
            : getOrPut(() => ViewPersonalDetailsController(), permanent: true);
    if (viewProfileController.earnProfileType.contains('homeService')) {
      Get.to(() => const EarnServiceDashboardView(earnType: 'homeService'));
    } else {
      Get.to(() => const HomeServiceProfileScreen());
    }
  }
}
