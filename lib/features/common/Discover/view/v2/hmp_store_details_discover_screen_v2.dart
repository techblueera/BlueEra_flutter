import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/chat/auth/service/profile_click_tracker.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/Discover/controller/hmp_cart_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/hmp_store_details_controller.dart';
import 'package:BlueEra/features/common/Discover/view/hmp_cart_screen.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_inventory_bottom_sheet.dart';
import 'package:BlueEra/features/me/product/view/admin/widget/product_preview_eye_button.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/earn_profile_repo.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/floating_cart_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// **v2** home-made-product store details.
///
/// Unlike [HmpStoreDetailsDiscoverScreen] this DOESN'T receive an
/// [EarnProfileModel] — the discover-v2 list only has a product (+ its seller
/// userId). So we take the [userId] and fetch the earn-profile "store" via
/// `fetchEarnProfileByUserId` (same pattern as the home-service v2 details).
/// The product catalogue + cart load off the userId immediately; the store
/// header / gallery / contact fill in once the profile resolves. Everything
/// else is identical to the v1 screen.
class HmpStoreDetailsDiscoverScreenV2 extends StatefulWidget {
  final String userId;

  /// Optional — lets the header show a name/logo instantly while the full
  /// profile is being fetched.
  final String? serviceName;
  final String? serviceLogo;

  const HmpStoreDetailsDiscoverScreenV2({
    super.key,
    required this.userId,
    this.serviceName,
    this.serviceLogo,
  });

  @override
  State<HmpStoreDetailsDiscoverScreenV2> createState() =>
      _HmpStoreDetailsDiscoverScreenV2State();
}

class _HmpStoreDetailsDiscoverScreenV2State
    extends State<HmpStoreDetailsDiscoverScreenV2> {
  // App primary color combination (theme-aligned accent for this flow).
  static const Color _primary = AppColors.primaryColor; // 0xFF0086FF
  static const Color _placeholderBg = AppColors.blue5CFF; // 0xFFEBF5FF
  static const String _profileType = 'homeMadeProduct';

  final _repo = EarnProfileRepo();
  EarnProfileModel? _store;
  bool _loadingStore = true;

  /// The fetched profile, or a minimal stub (from the constructor args) so the
  /// header has a name/logo to show before the network call resolves.
  EarnProfileModel get store =>
      _store ??
      EarnProfileModel(
        userId: widget.userId,
        serviceName: widget.serviceName,
        serviceLogo: widget.serviceLogo,
      );

  // Catalogue + cart key off the seller userId directly — no profile needed.
  late final HmpStoreDetailsController controller = getOrPut(
    () => HmpStoreDetailsController(userId: widget.userId),
    tag: widget.userId,
  );

  late final HmpCartController cartController =
      getOrPut(() => HmpCartController());

  @override
  void initState() {
    super.initState();
    if (widget.userId.trim().isNotEmpty) {
      ProfileClickTracker.track(
        userId: widget.userId,
        source: ChatClickSource.searchResult,
      );
    }
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (widget.userId.trim().isEmpty) {
      setState(() => _loadingStore = false);
      return;
    }
    try {
      final res = await _repo.fetchEarnProfileByUserId(
        userId: widget.userId,
        queryParams: const {'profileType': _profileType},
      );
      final body = res.response?.data;
      // The by-userId endpoint returns a SINGLE object: { success, data: {…} }.
      if (res.isSuccess && body is Map && body['data'] is Map) {
        _store = EarnProfileModel.fromJson(
            Map<String, dynamic>.from(body['data'] as Map));
      }
    } catch (_) {/* swallow — store-only sections simply show the stub / hide */}
    if (mounted) setState(() => _loadingStore = false);
  }

  @override
  void dispose() {
    deleteIfRegistered<HmpStoreDetailsController>(tag: widget.userId);
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
      controller.onScrollEnd();
    }
    return false;
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
        body: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: SingleChildScrollView(
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
                          _buildProducts(),
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
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(child: _buildCartBar()),
            ),
          ],
        ),
      ),
    );
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

          Positioned(
            top: statusBar + 8,
            left: 12,
            child: _circleButton(
              asset: AppIconAssets.back_arrow,
              onTap: () => Navigator.of(context).pop(),
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
      child: Icon(Icons.storefront_rounded,
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
        // White sheet holding everything from the name down.
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
                  _tagPill('Home Made Product'),
                  _ratingChip(),
                ],
              ),
              if (hasLoc || (store.address?.trim().isNotEmpty ?? false)) ...[
                const SizedBox(height: 12),
                _locationPill(km, hasLoc),
              ],
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

  // ── 3-column feature strip (delivery / payment / verified) ───────────────
  Widget _buildFeatureRow() {
    const cellBg = Color(0xFFF6F7F9);
    const dark = AppColors.mainTextColor;

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
                  'Secure Payment', dark, cellBg),
            ),
            _vDivider(),
            Expanded(
              child: _featureCol(
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

  // ── Products — heading + 2-col grid (paginated) ──────────────────────────
  Widget _buildProducts() {
    return Obx(() {
      if (controller.isFirstLoading.value && controller.hasNoProducts) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.hasNoProducts) return const SizedBox.shrink();

      final items = controller.products;
      return CustomFormCard(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeading('Products'),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final cardWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final item in items)
                      SizedBox(width: cardWidth, child: _productCard(item)),
                  ],
                );
              },
            ),
            if (controller.isLoadingMore.value) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      );
    });
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
          onTap: () => Get.to(() => const HmpCartScreen()),
        ),
      );
    });
  }

  // ── Product card — image + name + price, with an add / qty control ───────
  Widget _productCard(GetProductData item) {
    final imageUrl = HmpCartController.imageOf(item);
    final name = HmpCartController.nameOf(item);
    final sp = HmpCartController.sellingPriceOf(item);
    final mrp = HmpCartController.mrpOf(item);
    final discount = _discountText(sp, mrp);
    return GestureDetector(
      onTap: () => ProductInventoryBottomSheet.show(context, product: item),
      child: Container(
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
                child: Obx(() => _addControl(item)),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: ProductPreviewEyeButton(
                  onTap: () =>
                      ProductInventoryBottomSheet.show(context, product: item),
                  size: 26,
                ),
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
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    CustomText(
                      '${AppConstants.rupeeSymbol}${sp.toStringAsFixed(0)}',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                    ),
                    if (mrp > sp && mrp > 0)
                      CustomText(
                        '${AppConstants.rupeeSymbol}${mrp.toStringAsFixed(0)}',
                        fontSize: 11,
                        color: AppColors.secondaryTextColor,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.secondaryTextColor,
                      ),
                    if (discount.isNotEmpty)
                      CustomText(
                        discount,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E7D34),
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

  String _discountText(double selling, double mrp) {
    if (mrp <= 0 || selling <= 0 || selling >= mrp) return '';
    return '${((mrp - selling) / mrp * 100).round()}% Off';
  }

  Widget _cardImageFallback() {
    return Container(
      color: _placeholderBg,
      alignment: Alignment.center,
      child: Icon(Icons.shopping_bag_rounded,
          size: 32, color: _primary.withValues(alpha: 0.45)),
    );
  }

  // Multi-store cart: items from different sellers stack into separate carts
  // (Zomato-style), so adding never prompts to replace another seller's cart.
  void _onAddTap(GetProductData item) {
    cartController.add(item, store);
  }

  // Blue "+" on the image; expands to a − qty + stepper once added.
  Widget _addControl(GetProductData item) {
    final qty = cartController.qty(HmpCartController.idOf(item));
    if (qty == 0) {
      return GestureDetector(
        onTap: () => _onAddTap(item),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, size: 19, color: Colors.white),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(qty == 1 ? Icons.delete_outline_rounded : Icons.remove,
              qty == 1 ? AppColors.red : _primary, () => cartController.remove(item)),
          Container(
            constraints: const BoxConstraints(minWidth: 18),
            alignment: Alignment.center,
            child: CustomText('$qty',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor),
          ),
          _stepBtn(Icons.add, _primary, () => cartController.add(item, store)),
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

  // ── Testimonials — light-blue band + carousel of white quote cards ───────
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
          'Beautifully crafted and great quality every single time. Buying '
              'home-made products here has been a wonderful experience.',
      name: 'Anita Sharma',
      role: 'Verified Buyer',
    ),
  ];

  Widget _buildTestimonials() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.format_quote_rounded,
              size: 32, color: AppColors.secondaryTextColor),
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
          Divider(color: AppColors.greyE5, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFEDEFF4),
                child: Icon(Icons.person_rounded,
                    size: 18, color: AppColors.secondaryTextColor),
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
    if (_loadingStore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final store = _store;
    if (store == null) return const SizedBox.shrink();

    final lat = store.latitude ?? 0.0;
    final lng = store.longitude ?? 0.0;
    final hasLoc = !(lat == 0.0 && lng == 0.0);
    final website = (store.website ?? '').trim();
    final phone = (store.alternatePhoneNumber ?? '').trim();
    final email = (store.email ?? '').trim();
    final address = (store.address ?? '').trim();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  'Home-made products crafted with care — handmade goods and '
                  'more for nearby buyers.',
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
          ],
        ),
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
