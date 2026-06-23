import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/controller/hmf_cart_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/hmf_store_details_controller.dart';
import 'package:BlueEra/features/common/Discover/view/hmf_cart_screen.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_or_cooking_method.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_item_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/tiffin_meal_model.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/floating_cart_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HmfStoreDetailsDiscoverScreen extends StatefulWidget {
  /// Store owner user id — drives both the home-foods (profile + items) and
  /// tiffins calls (backend resolves the store by userId).
  final String userId;

  const HmfStoreDetailsDiscoverScreen({super.key, required this.userId});

  @override
  State<HmfStoreDetailsDiscoverScreen> createState() =>
      _HmfStoreDetailsDiscoverScreenState();
}

class _HmfStoreDetailsDiscoverScreenState
    extends State<HmfStoreDetailsDiscoverScreen> {
  // App primary color combination (theme-aligned accent for this flow).
  static const Color _primary = AppColors.primaryColor; // 0xFF0086FF
  static const Color _placeholderBg = AppColors.blue5CFF; // 0xFFEBF5FF
  // Add-to-cart accent — the veg/food green already used on this screen for the
  // diet badge + discount, reused so the "Add" action reads as food-positive.
  static const Color _addGreen = Color(0xFF1E7D34);

  late final HmfStoreDetailsController controller = getOrPut(
    () => HmfStoreDetailsController(userId: widget.userId),
    tag: widget.userId,
  );

  /// The loaded store profile. Only read inside the loaded subtree — `build`
  /// gates on a non-null store before any of these helpers run, so the `!`
  /// is safe.
  EarnProfileModel get store => controller.store.value!;

  // Shared cart for the whole home made food flow (registered at the list
  // screen) — found here so adds survive coming back to the list.
  late final HmfCartController cartController =
      getOrPut(() => HmfCartController());

  // Selected Home Made Food category tab (index into availableCategories).
  final RxInt _selectedCat = 0.obs;

  static const Map<FoodCategoryType, String> _categoryTitles = {
    FoodCategoryType.bakery: 'Bakery',
    FoodCategoryType.namkeens: 'Namkeen',
    FoodCategoryType.sweets: 'Sweets',
    FoodCategoryType.pickles: 'Pickles',
  };

  @override
  void initState() {
    super.initState();
    // Track the profile visit (fire-and-forget). Home-made-food profiles are
    // individual accounts, so fall back to userId when the business id is
    // absent — same key the chat tracker / chat open uses for this store.
    final id = widget.userId.trim();
    if (id.isNotEmpty) {
      ProfileClickTracker.track(
        userId: id,
        source: ChatClickSource.searchResult,
      );
    }
  }

  @override
  void dispose() {
    // Only the details controller is scoped to this screen. The cart
    // controller is shared with the list screen and cleaned up there.
    deleteIfRegistered<HmfStoreDetailsController>(tag: widget.userId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // The home-foods call returns the store profile + items; gate the whole
        // screen on the profile. While it loads → shimmer skeleton; if it fails
        // (profile still null) → store error. Per-section APIs (tiffins, menu)
        // self-hide on failure instead of erroring the whole screen.
        body: Obx(() {
          if (controller.store.value == null) {
            return controller.isFoodLoading.value
                ? _buildStoreShimmer()
                : _buildStoreError();
          }
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    _buildIdentity(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTiffinSection(),
                          _buildMenu(),
                          _buildGallery(),
                          _buildTestimonials(),
                          _buildContactCard(),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(child: _buildCartBar()),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Loading skeleton (shimmer) — mirrors the real store layout ───────────
  Widget _buildStoreShimmer() {
    final statusBar = MediaQuery.of(context).padding.top;
    Widget block(double h, {double? w, double r = 10}) =>
        shimmerContainer(height: h, width: w, radius: r);

    return Stack(
      children: [
        SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: buildLoadingShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero cover
                block(200 + statusBar, r: 0),
                const SizedBox(height: 16),
                // Identity: logo + name lines, location bar, feature row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          block(62, w: 62, r: 31),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                block(20, w: 180),
                                const SizedBox(height: 8),
                                block(14, w: 120),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      block(42, r: 10), // location bar
                      const SizedBox(height: 14),
                      block(66, r: 12), // feature row
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Menu: heading + tab pills + 2-col card grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      block(18, w: 150),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          block(30, w: 72, r: 20),
                          const SizedBox(width: 8),
                          block(30, w: 72, r: 20),
                          const SizedBox(width: 8),
                          block(30, w: 72, r: 20),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 12.0;
                          final cardWidth =
                              (constraints.maxWidth - spacing) / 2;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: List.generate(
                              4,
                              (_) => SizedBox(
                                width: cardWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    block(94, r: 12),
                                    const SizedBox(height: 8),
                                    block(12, w: cardWidth * 0.7),
                                    const SizedBox(height: 6),
                                    block(12, w: cardWidth * 0.4),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _backButtonOverlay(statusBar),
      ],
    );
  }

  // ── Store error — only when the home-foods (profile) call fails ──────────
  Widget _buildStoreError() {
    final statusBar = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_outlined,
                    size: 48, color: AppColors.secondaryTextColor),
                const SizedBox(height: 12),
                CustomText(
                  AppStrings.somethingWentWrong,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: controller.fetchFoodItems,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomText('Retry',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        _backButtonOverlay(statusBar),
      ],
    );
  }

  Widget _backButtonOverlay(double statusBar) {
    return Positioned(
      top: statusBar + 8,
      left: 8,
      child: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: AppColors.mainTextColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  // ── Floating cart bar ────────────────────────────────────────────────────
  Widget _buildCartBar() {
    return Obx(() {
      // ignore: unused_local_variable
      final _ = cartController.quantities.length; // subscribe to changes
      if (cartController.isEmpty) return const SizedBox.shrink();
      final count = cartController.totalItems;
      return Center(
        child: FloatingCartWidget(
          itemCount: count,
          displayImages: cartController.previewImages,
          cartLabel: 'View Cart',
          itemLabel:
              '$count ${count == 1 ? 'item' : 'items'}  •  ${AppConstants.rupeeSymbol}${cartController.totalPrice.toStringAsFixed(0)}',
          onTap: () => Get.to(() => const HmfCartScreen()),
        ),
      );
    });
  }

  // ── Hero cover image with back / save / share top bar ────────────────────
  Widget _buildHero() {
    final statusBar = MediaQuery.of(context).padding.top;
    final cover = store.galleryImages.isNotEmpty ? store.galleryImages.first : '';

    return SizedBox(
      height: 210 + statusBar,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover.isNotEmpty)
            CachedNetworkImage(
              imageUrl: cover,
              fit: BoxFit.cover,
              memCacheWidth: 1000,
              placeholder: (_, __) => Container(color: _placeholderBg),
              errorWidget: (_, __, ___) => _coverFallback(),
            )
          else
            _coverFallback(),

          // Light top scrim so the status bar icons stay legible.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x40000000), Color(0x00000000)],
                stops: [0.0, 0.35],
              ),
            ),
          ),

          // Back (left) · save + share (right).
          Positioned(
            top: statusBar + 8,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleButton(
                  asset: AppIconAssets.back_arrow,
                  onTap: () => Navigator.of(context).pop(),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _circleButton(
                        asset: AppIconAssets.star_rounded, onTap: () {}),
                    const SizedBox(width: 10),
                    _circleButton(
                        asset: AppIconAssets.reelShare, onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required String asset, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.25), width: 0.6),
        ),
        child: LocalAssets(
          imagePath: asset,
          width: 18,
          height: 18,
          imgColor: Colors.white,
        ),
      ),
    );
  }

  Widget _coverFallback() {
    return Container(
      color: _placeholderBg,
      alignment: Alignment.center,
      child: Icon(Icons.lunch_dining_rounded,
          size: 56, color: _primary.withValues(alpha: 0.45)),
    );
  }

  // ── Identity: logo (overlapping) + name + Chat + tags + rating + location ─
  Widget _buildIdentity() {
    final lat = store.latitude ?? 0.0;
    final lng = store.longitude ?? 0.0;
    final km = calculateDistanceKm(
        LocationService.lat, LocationService.lng, lat, lng);
    final hasLoc = !(lat == 0.0 && lng == 0.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // White sheet holding everything from the name down to Veg Food.
        // Full-bleed width with only the top corners rounded over the hero.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                store.serviceName ?? AppStrings.na,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _tagPill('Home Made Food'),
                  _ratingChip(),
                ],
              ),
              const SizedBox(height: 12),
              _locationPill(km, hasLoc),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFEDEFF4)),
              const SizedBox(height: 14),
              _buildFeatureRow(),
            ],
          ),
        ),

        // Logo straddling the sheet's top-left edge.
        Positioned(
          left: 16,
          top: -14,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CachedAvatarWidget(
              imageUrl: store.serviceLogo ?? '',
              size: 62,
              borderColor: Colors.transparent,
              borderRadius: 31,
            ),
          ),
        ),

        // Chat — top-right, aligned with the logo.
        Positioned(
          right: 16,
          top: 6,
          child: _chatPill(),
        ),
      ],
    );
  }

  Widget _chatPill() {
    return GestureDetector(
      onTap: _openChat,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.30),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(
              imagePath: AppIconAssets.chat,
              width: 15,
              height: 15,
              imgColor: Colors.white,
            ),
            const SizedBox(width: 6),
            CustomText('Chat',
                fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _tagPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: CustomText(text,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryTextColor),
    );
  }

  // NOTE: placeholder rating — the model has no rating field yet.
  Widget _ratingChip() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LocalAssets(
          imagePath: AppIconAssets.fill_star,
          width: 14,
          height: 14,
          imgColor: AppColors.yellow,
        ),
        const SizedBox(width: 3),
        CustomText('4.8',
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor),
        const SizedBox(width: 3),
        CustomText('(48 reviews)',
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor),
      ],
    );
  }

  Widget _locationPill(double km, bool hasLoc) {
    return GestureDetector(
      onTap: hasLoc ? _showMapBottomSheet : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, size: 15, color: _primary),
            const SizedBox(width: 6),
            if (hasLoc) ...[
              CustomText('${km.toStringAsFixed(0)} KM',
                  fontSize: 12, fontWeight: FontWeight.w800, color: _primary),
              CustomText('  |  ', fontSize: 12, color: AppColors.greyE5),
            ],
            Expanded(
              child: CustomText(
                store.address ?? AppStrings.na,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat() {
    final uid = store.userId ?? '';
    if (uid.trim().isEmpty) return;
    if (isGuestUser()) {
      createProfileScreen();
      return;
    }
    final bId = store.id?.trim();
    if (bId != null && bId.isNotEmpty) {
      ChatClickTracker.track(
          userId: bId, source: ChatClickSource.searchResult);
    }
    final chatViewController = getOrPut(() => ChatViewController());
    chatViewController.checkChatConnectionAndOpenChat(
      userId: uid,
      name: store.serviceName,
      profile: store.serviceLogo,
      route: AppConstants.route_discover,
    );
  }

  // ── 3-column feature strip (delivery / payment / diet) ───────────────────
  Widget _buildFeatureRow() {
    const cellBg = Color(0xFFF6F7F9);
    const dark = AppColors.mainTextColor;
    final diet = (store.foodType ?? '').trim();
    final hasDiet = diet.isNotEmpty;
    final isVeg = !diet.toLowerCase().contains('non');
    final dietColor =
        isVeg ? const Color(0xFF1E7D34) : const Color(0xFFC0341D);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _featureCol(Icons.delivery_dining_rounded,
                  'Home Delivery', dark, cellBg),
            ),
            _vDivider(),
            Expanded(
              child: _featureCol(Icons.currency_rupee_rounded,
                  'Monthly Payment', dark, cellBg),
            ),
            _vDivider(),
            Expanded(
              child: hasDiet
                  ? _featureCol(
                      Icons.check_box_rounded,
                      isVeg ? 'Veg Food' : 'Non-Veg',
                      dietColor,
                      dietColor.withValues(alpha: 0.08),
                    )
                  : _featureCol(
                      Icons.verified_rounded, 'Verified', _primary, cellBg),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, color: AppColors.greyE5);

  Widget _featureCol(IconData icon, String label, Color color, Color bg) {
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          CustomText(
            label,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: color,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Testimonials ─────────────────────────────────────────────────────────
  // ── Testimonials — centered heading + a soft pink quote card ─────────────
  // NOTE: placeholder content — no testimonials data on the model yet.
  static const List<({String text, String name, String role})> _testimonials = [
    (
      text:
          'Qorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc '
              'vulputate libero et velit interdum, ac aliquet odio mattis. '
              'Class aptent taciti sociosqu ad litora torquent.',
      name: 'Dr. Ramesh Gupta',
      role: 'Managing Director',
    ),
    (
      text:
          'Fresh, home-made and delicious every single time. Ordering tiffin '
              'here has been a wonderful experience for my whole family.',
      name: 'Anita Sharma',
      role: 'Verified Buyer',
    ),
  ];

  // ── Testimonials — white band + carousel of soft blue-tinted quote cards ──
  Widget _buildTestimonials() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyE5),
      ),
      child: Column(
        children: [
          Center(child: _sectionHeading('Testimonials')),
          const SizedBox(height: 14),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _testimonials.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(
                width: SizeConfig.screenWidth * 0.78,
                child: _testimonialCard(_testimonials[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _testimonialCard(({String text, String name, String role}) t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        // Soft blue tint so the quote card lifts off the white section while
        // staying in the screen's blue family.
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.format_quote_rounded, size: 32, color: _primary),
          const SizedBox(height: 6),
          Expanded(
            child: Center(
              child: CustomText(
                t.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Divider(color: _primary.withValues(alpha: 0.15), height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFE3ECF7),
                child: Icon(Icons.person_rounded, size: 18, color: _primary),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText('-${t.name}',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor),
                  CustomText(t.role,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Contact Us — heading + bordered card (logo, name, desc, rows, map) ───
  Widget _buildContactCard() {
    final lat = store.latitude ?? 0.0;
    final lng = store.longitude ?? 0.0;
    final hasLoc = !(lat == 0.0 && lng == 0.0);
    final website = (store.website ?? '').trim();
    final phone = (store.alternatePhoneNumber ?? '').trim();
    final email = (store.email ?? '').trim();
    final address = (store.address ?? '').trim();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.greyE5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeading('Contact Us'),
                const SizedBox(height: 12),
                ClipOval(
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: (store.serviceLogo?.isNotEmpty ?? false)
                        ? CachedNetworkImage(
                            imageUrl: store.serviceLogo!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _logoFallback(),
                          )
                        : _logoFallback(),
                  ),
                ),
                const SizedBox(height: 10),
                CustomText(
                  store.serviceName ?? AppStrings.na,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                CustomText(
                  'Home-made food made fresh daily — tiffins, snacks and more, '
                  'served with care for nearby foodies.',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryTextColor,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                if (website.isNotEmpty)
                  _contactRow(Icons.language_rounded, website, isLink: true),
                if (email.isNotEmpty) _contactRow(Icons.email_outlined, email),
                if (phone.isNotEmpty) _contactRow(Icons.call_rounded, phone),
                if (address.isNotEmpty)
                  _contactRow(Icons.location_on_rounded, address, maxLines: 2),
                if (hasLoc) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BusinessLocationMapWidget(
                      latitude: lat,
                      longitude: lng,
                      businessName: store.serviceName ?? AppStrings.na,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _showMapBottomSheet,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: _primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_rounded,
                              size: 16, color: _primary),
                          const SizedBox(width: 6),
                          CustomText('Get Directions',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: _primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoFallback() {
    return Container(
      color: _placeholderBg,
      alignment: Alignment.center,
      child: Icon(Icons.storefront_rounded,
          size: 26, color: _primary.withValues(alpha: 0.5)),
    );
  }

  Widget _contactRow(IconData icon, String text,
      {int maxLines = 1, bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.secondaryTextColor),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText(
              text,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isLink ? _primary : AppColors.mainTextColor,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showMapBottomSheet() {
    RouteMapBottomSheet.show(
      context: context,
      destinationName: store.serviceName ?? AppStrings.na,
      destinationAddress: store.address ?? '',
      destinationLat: store.latitude ?? 0.0,
      destinationLng: store.longitude ?? 0.0,
      livePhotos: store.galleryImages,
    );
  }

  // ── Section heading (plain bold title) ───────────────────────────────────
  Widget _sectionHeading(String text) {
    return CustomText(
      text,
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: AppColors.mainTextColor,
      letterSpacing: 0.2,
    );
  }

  // ── Tiffin — horizontal cards, shown only when the store has tiffins ──────
  Widget _buildTiffinSection() {
    return Obx(() {
      if (controller.tiffins.isEmpty) return const SizedBox.shrink();
      final tiffins = controller.tiffins;
      return CustomFormCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeading('Tiffin'),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < tiffins.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    SizedBox(
                      width: SizeConfig.screenWidth * 0.44,
                      child: _tiffinCard(tiffins[i]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Home Made Food — category tabs + 2-col grid ──────────────────────────
  Widget _buildMenu() {
    return Obx(() {
      if (controller.isFoodLoading.value && controller.hasNoFood) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final cats = controller.availableCategories;
      if (cats.isEmpty) return const SizedBox.shrink();

      final sel = _selectedCat.value.clamp(0, cats.length - 1);
      final type = cats[sel];
      final items = controller.categoryData[type] ?? <FoodItemModel>[];

      return CustomFormCard(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeading('Home Made Food'),
            const SizedBox(height: 12),
            HorizontalTabSelector<FoodCategoryType>(
              tabs: cats,
              selectedIndex: sel,
              labelBuilder: (t) => _categoryTitles[t] ?? '',
              horizontalPadding: 16,
              verticalPadding: 7,
              horizontalMargin: 0,
              verticalMargin: 0,
              unSelectedBackgroundColor: AppColors.white,
              unSelectedBorderColor: AppColors.greyE5,
              onTabSelected: (index, _) => _selectedCat.value = index,
            ),
            const SizedBox(height: 12),
            // Wrap with LayoutBuilder so each card sizes to its own content
            // height (no fixed grid extent → no wasted vertical space).
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final cardWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final item in items)
                      SizedBox(width: cardWidth, child: _foodCard(item)),
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
  }

  // ── Cards ─────────────────────────────────────────────────────────────────
  Widget _foodCard(FoodItemModel item) {
    return _itemCard(
      imageUrl: item.imageUrl,
      name: item.foodName,
      cookingMethod: item.cookingMethod,
      sellingPrice: item.sellingPrice,
      mrpPrice: item.mrpPrice,
      cartItem: item,
      isTiffin: false,
    );
  }

  Widget _tiffinCard(TiffinMealModel meal) {
    return _itemCard(
      imageUrl: meal.imageUrl,
      name: meal.tiffinName,
      cookingMethod: meal.selectedCookingMethod,
      sellingPrice: meal.sellingPrice,
      mrpPrice: meal.mrpPrice,
      cartItem: _tiffinAsFood(meal),
      isTiffin: true,
    );
  }

  /// Maps a tiffin onto the cart's [FoodItemModel] so both share one cart.
  FoodItemModel _tiffinAsFood(TiffinMealModel meal) => FoodItemModel(
        id: meal.id,
        categoryType: FoodCategoryType.bakery,
        foodName: meal.tiffinName,
        images: meal.images,
        mrpPrice: meal.mrpPrice,
        sellingPrice: meal.sellingPrice,
        foodType: meal.selectedFoodType,
        cookingMethod: meal.selectedCookingMethod,
        isLive: meal.isLive,
      );

  Widget _itemCard({
    required String? imageUrl,
    required String name,
    required String cookingMethod,
    required String sellingPrice,
    required String mrpPrice,
    required FoodItemModel cartItem,
    required bool isTiffin,
  }) {
    final discount = _discountText(sellingPrice, mrpPrice);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 94,
                width: double.infinity,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey.shade200),
                        errorWidget: (_, __, ___) => _cardImageFallback(),
                      )
                    : _cardImageFallback(),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Obx(() => _addControl(cartItem, isTiffin)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  name,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (cookingMethod.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  FoodTypeOrCookingMethod(
                    label: cookingMethod,
                    icon: AppIconAssets.boiled,
                  ),
                ],
                const SizedBox(height: 8),
                PriceRow(
                  sellingPrice: '${AppConstants.rupeeSymbol}$sellingPrice',
                  mrp: mrpPrice.isNotEmpty
                      ? '${AppConstants.rupeeSymbol}$mrpPrice'
                      : '',
                  discount: discount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _discountText(String sellingStr, String mrpStr) {
    final s = double.tryParse(sellingStr) ?? 0;
    final m = double.tryParse(mrpStr) ?? 0;
    if (m <= 0 || s <= 0 || s >= m) return '';
    return '${((m - s) / m * 100).round()}% Off';
  }

  // Multi-store cart: items from different kitchens stack into separate carts
  // (Zomato-style). Tiffin and food, however, can't share a cart — if the
  // cart already holds the other type, prompt to start a new one.
  void _onAddTap(FoodItemModel item, bool isTiffin) {
    if (cartController.wouldMix(isTiffin)) {
      _showSwitchCartDialog(item, isTiffin);
      return;
    }
    cartController.add(item, store, isTiffin: isTiffin);
  }

  /// "Start a new cart?" prompt shown when the user adds an item of a type
  /// different from what's already in the cart (tiffin vs food). Confirming
  /// clears the current cart and adds the new item.
  void _showSwitchCartDialog(FoodItemModel item, bool isTiffin) {
    final currentIsTiffin = cartController.cartIsTiffin ?? false;
    final currentLabel = currentIsTiffin ? 'tiffin' : 'food';
    Get.dialog(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: CustomText('Start a new cart?',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor),
        content: CustomText(
          'Your cart has $currentLabel items. Tiffin and food are ordered '
          'separately, so adding this will clear your cart and start a new one.',
          fontSize: 13,
          color: AppColors.secondaryTextColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: CustomText('Cancel',
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w700),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              cartController.clear();
              cartController.add(item, store, isTiffin: isTiffin);
              Get.back();
            },
            child: CustomText('New cart',
                color: AppColors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // Green "Add" button on the image; expands to a − qty + stepper once added.
  Widget _addControl(FoodItemModel item, bool isTiffin) {
    final qty = cartController.qty(item.id);
    if (qty == 0) {
      return GestureDetector(
        onTap: () => _onAddTap(item, isTiffin),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _addGreen,
            // Same pill radius as the qty stepper so the control keeps its
            // shape across the add → quantity transition.
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _addGreen.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 3),
              CustomText('Add',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ],
          ),
        ),
      );
    }
    // Solid green stepper (matches the green "Add"): reads far better on the
    // food photo than a washed-out white pill, and keeps the same pill shape.
    return Container(
      decoration: BoxDecoration(
        color: _addGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _addGreen.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(qty == 1 ? Icons.delete_outline_rounded : Icons.remove,
              Colors.white, () => cartController.remove(item)),
          Container(
            constraints: const BoxConstraints(minWidth: 18),
            alignment: Alignment.center,
            child: CustomText('$qty',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
          _stepBtn(Icons.add, Colors.white,
              () => cartController.add(item, store, isTiffin: isTiffin)),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Center(child: Icon(icon, size: 15, color: color)),
      ),
    );
  }

  Widget _cardImageFallback() {
    return Container(
      color: _placeholderBg,
      alignment: Alignment.center,
      child: Icon(Icons.lunch_dining,
          size: 32, color: _primary.withValues(alpha: 0.45)),
    );
  }

  // ── Gallery ──────────────────────────────────────────────────────────────
  Widget _buildGallery() {
    final images =
        store.galleryImages.where((p) => p.trim().isNotEmpty).toList();
    if (images.isEmpty) return const SizedBox.shrink();

    return CustomFormCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(AppStrings.gallery.tr),
          const SizedBox(height: 10),
          _buildGalleryLayout(images),
        ],
      ),
    );
  }

  // 1 image → full-width banner · 2 images → side-by-side · 3+ → 2-col grid.
  Widget _buildGalleryLayout(List<String> images) {
    if (images.length == 1) {
      return _galleryTile(images, 0, height: 190);
    }
    if (images.length == 2) {
      return Row(
        children: [
          Expanded(child: _galleryTile(images, 0, height: 140)),
          const SizedBox(width: 10),
          Expanded(child: _galleryTile(images, 1, height: 140)),
        ],
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.3,
      ),
      itemCount: images.length,
      itemBuilder: (_, index) => _galleryTile(images, index),
    );
  }

  Widget _galleryTile(List<String> images, int index, {double? height}) {
    final tile = InkWell(
      onTap: () => navigatePushTo(
        context,
        ImageViewScreen(
          appBarTitle: store.serviceName ?? AppStrings.gallery.tr,
          subTitle: AppStrings.imageViewer.tr,
          imageUrls: images,
          initialIndex: index,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: images[index],
          fit: BoxFit.cover,
          width: double.infinity,
          height: height,
          placeholder: (_, __) => Container(color: Colors.grey.shade200),
          errorWidget: (_, __, ___) => LocalAssets(
            imagePath: AppIconAssets.place_holder_image,
            boxFix: BoxFit.cover,
          ),
        ),
      ),
    );
    return height != null ? SizedBox(height: height, child: tile) : tile;
  }

}
