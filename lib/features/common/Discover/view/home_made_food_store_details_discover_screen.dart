import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/chat/auth/service/chat_click_tracker.dart';
import 'package:BlueEra/features/common/Discover/controller/home_made_food_cart_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/home_made_food_store_details_controller.dart';
import 'package:BlueEra/features/common/Discover/view/home_made_food_cart_screen.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_chat_icon.dart';
import 'package:BlueEra/features/me/grocery/widget/discount_badge.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_or_cooking_method.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/food_item_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/floating_cart_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HomeMadeFoodStoreDetailsDiscoverScreen extends StatefulWidget {
  final EarnProfileModel store;

  const HomeMadeFoodStoreDetailsDiscoverScreen({super.key, required this.store});

  @override
  State<HomeMadeFoodStoreDetailsDiscoverScreen> createState() =>
      _HomeMadeFoodStoreDetailsDiscoverScreenState();
}

class _HomeMadeFoodStoreDetailsDiscoverScreenState
    extends State<HomeMadeFoodStoreDetailsDiscoverScreen> {
  static const Color _warm = Color(0xFFE8590C);

  EarnProfileModel get store => widget.store;

  late final HomeMadeFoodStoreDetailsController controller = getOrPut(
    () => HomeMadeFoodStoreDetailsController(profileId: store.id ?? ''),
    tag: store.id ?? store.userId ?? '',
  );

  // Shared cart for the whole home made food flow (registered at the list
  // screen) — found here so adds survive coming back to the list.
  late final HomeMadeFoodCartController cartController =
      getOrPut(() => HomeMadeFoodCartController());

  static const Map<FoodCategoryType, String> _categoryTitles = {
    FoodCategoryType.bakery: 'Bakery',
    FoodCategoryType.namkeens: 'Namkeen',
    FoodCategoryType.sweets: 'Sweets',
    FoodCategoryType.pickles: 'Pickles',
  };

  @override
  void dispose() {
    // Only the details controller is scoped to this screen. The cart
    // controller is shared with the list screen and cleaned up there.
    deleteIfRegistered<HomeMadeFoodStoreDetailsController>(
        tag: store.id ?? store.userId ?? '');
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
        backgroundColor: AppColors.appBackgroundColor,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeatureRow(),
                        _buildContactCard(),
                        const SizedBox(height: 10),
                        _buildMenu(),
                        _buildGallery(),
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
        ),
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
          onTap: () => Get.to(() => HomeMadeFoodCartScreen(store: store)),
        ),
      );
    });
  }

  // ── Immersive hero: cover image + scrim + back + logo + name + diet ──────
  Widget _buildHero() {
    final statusBar = MediaQuery.of(context).padding.top;
    final cover = store.galleryImages.isNotEmpty ? store.galleryImages.first : '';
    final diet = (store.foodType ?? '').trim();

    return SizedBox(
      height: 250 + statusBar,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover.isNotEmpty)
            CachedNetworkImage(
              imageUrl: cover,
              fit: BoxFit.cover,
              memCacheWidth: 1000,
              placeholder: (_, __) => Container(color: const Color(0xFFF5E6C8)),
              errorWidget: (_, __, ___) => _coverFallback(),
            )
          else
            _coverFallback(),

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x73000000),
                  Color(0x00000000),
                  Color(0xE6000000),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Back + chat row.
          Positioned(
            top: statusBar + 8,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: DiscoverChatIcon(
                    userId: store.userId ?? '',
                    name: store.serviceName,
                    profile: store.serviceLogo,
                    businessId: store.id,
                    trackingSource: ChatClickSource.searchResult,
                  ),
                ),
              ],
            ),
          ),

          // Logo + name + pills.
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CachedAvatarWidget(
                    imageUrl: store.serviceLogo ?? '',
                    size: 64,
                    borderColor: Colors.transparent,
                    borderRadius: 32,
                  ),
                ),
                const SizedBox(height: 10),
                CustomText(
                  store.serviceName ?? AppStrings.na,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _heroPill('Home Made Food', Icons.soup_kitchen_rounded),
                    if (diet.isNotEmpty) _dietPill(diet),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.4),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 0.6,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _coverFallback() {
    return Container(
      color: const Color(0xFFF5E6C8),
      alignment: Alignment.center,
      child: Icon(Icons.lunch_dining_rounded,
          size: 56, color: Colors.orange.shade300),
    );
  }

  Widget _heroPill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _warm,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          CustomText(text,
              fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
        ],
      ),
    );
  }

  Widget _dietPill(String text) {
    final isVeg = !text.toLowerCase().contains('non');
    final color = isVeg ? const Color(0xFF1E7D34) : const Color(0xFFC0341D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _vegMark(color),
          const SizedBox(width: 5),
          CustomText(text,
              fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
        ],
      ),
    );
  }

  Widget _vegMark(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  // ── Feature chips (home delivery / monthly payment) ──────────────────────
  Widget _buildFeatureRow() {
    final chips = <Widget>[
      if (store.homeDelivery)
        _featureChip(Icons.delivery_dining_rounded, 'Home Delivery'),
      if (store.monthlyPayment)
        _featureChip(Icons.event_repeat_rounded, 'Monthly Payment'),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _warm.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _warm.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _warm),
          const SizedBox(width: 6),
          CustomText(
            label,
            fontSize: 12,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  // ── Contact & address ────────────────────────────────────────────────────
  Widget _buildContactCard() {
    final lat = store.latitude ?? 0.0;
    final lng = store.longitude ?? 0.0;
    final km = calculateDistanceKm(
        LocationService.lat, LocationService.lng, lat, lng);
    final address = store.address ?? AppStrings.na;
    final house = (store.houseNumber ?? '').trim();
    final phone = (store.alternatePhoneNumber ?? '').trim();
    final hasLoc = !(lat == 0.0 && lng == 0.0);

    return CustomFormCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Contact & Location'),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.location_on_rounded,
            title: hasLoc ? '${km.toStringAsFixed(2)} Km Away' : address,
            subtitle: hasLoc
                ? (house.isNotEmpty ? '$house, $address' : address)
                : (house.isNotEmpty ? house : 'Address'),
            onTap: hasLoc ? _showMapBottomSheet : null,
            trailing: hasLoc
                ? CustomText('View Map',
                    fontSize: 12, color: _warm, fontWeight: FontWeight.w700)
                : null,
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.call_rounded,
              title: phone,
              subtitle: 'Alternate Contact',
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_warm, Color(0xFFF7A23B)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        CustomText(
          text,
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _warm.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: _warm),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                CustomText(
                  subtitle,
                  fontSize: 11,
                  color: AppColors.secondaryTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
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

  // ── Menu (fetched, grouped by category) ──────────────────────────────────
  Widget _buildMenu() {
    return Obx(() {
      if (controller.isFoodLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.hasNoFood) {
        return CustomFormCard(
          padding: const EdgeInsets.all(16),
          child: EmptyStateWidget(
            message:
                '${store.serviceName ?? AppStrings.foodThisShopLabel.tr} hasn\'t listed any food yet.',
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final type in FoodCategoryType.values)
            if ((controller.categoryData[type]?.isNotEmpty ?? false))
              _buildCategorySection(type, controller.categoryData[type]!),
        ],
      );
    });
  }

  Widget _buildCategorySection(
      FoodCategoryType type, List<FoodItemModel> items) {
    return CustomFormCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle(_categoryTitles[type] ?? 'Items'),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _warm.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: CustomText(
                  '${items.length}',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _warm,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 18),
            itemBuilder: (context, index) => _buildFoodItem(items[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(FoodItemModel item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 86,
                height: 86,
                child: item.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey.shade200),
                        errorWidget: (_, __, ___) => _foodFallback(),
                      )
                    : _foodFallback(),
              ),
            ),
            if (item.foodType.isNotEmpty)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: _vegMark(
                    !item.foodType.toLowerCase().contains('non')
                        ? const Color(0xFF1E7D34)
                        : const Color(0xFFC0341D),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                item.foodName,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  CustomText(
                    '${AppConstants.rupeeSymbol}${item.sellingPrice}',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  ),
                  if (item.mrpPrice.isNotEmpty)
                    CustomText(
                      '${AppConstants.rupeeSymbol}${item.mrpPrice}',
                      fontSize: 11,
                      color: AppColors.secondaryTextColor,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.secondaryTextColor,
                    ),
                  if (item.discount.isNotEmpty)
                    DiscountBadge(discountText: item.discount),
                ],
              ),
              if (item.cookingMethod.isNotEmpty) ...[
                const SizedBox(height: 6),
                FoodTypeOrCookingMethod(
                  label: item.cookingMethod,
                  icon: AppIconAssets.boiled,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Obx(() => _buildAddControl(item)),
      ],
    );
  }

  void _onAddTap(FoodItemModel item) {
    if (cartController.isDifferentStore(store)) {
      _confirmReplaceCart(item);
    } else {
      cartController.add(item, store);
    }
  }

  void _confirmReplaceCart(FoodItemModel item) {
    final otherName =
        cartController.store.value?.serviceName ?? 'another kitchen';
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                'Start a new cart?',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
              const SizedBox(height: 10),
              CustomText(
                'Your cart already has items from "$otherName". Ordering from here will clear it.',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.greyE5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: CustomText('Cancel',
                          color: AppColors.secondaryTextColor,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        cartController.clear();
                        cartController.add(item, store);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _warm,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: CustomText('Start New',
                          color: AppColors.white,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddControl(FoodItemModel item) {
    final qty = cartController.qty(item.id);
    if (qty == 0) {
      return InkWell(
        onTap: () => _onAddTap(item),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _warm, width: 1.2),
            color: _warm.withValues(alpha: 0.06),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 14, color: _warm),
              const SizedBox(width: 3),
              CustomText('ADD',
                  fontSize: 12, fontWeight: FontWeight.w800, color: _warm),
            ],
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _warm.withValues(alpha: 0.4)),
        color: _warm.withValues(alpha: 0.06),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _miniStep(qty == 1 ? Icons.delete_outline_rounded : Icons.remove,
              qty == 1 ? AppColors.red : _warm, () => cartController.remove(item)),
          Container(
            constraints: const BoxConstraints(minWidth: 20),
            alignment: Alignment.center,
            child: CustomText('$qty',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor),
          ),
          _miniStep(Icons.add, _warm, () => cartController.add(item, store)),
        ],
      ),
    );
  }

  Widget _miniStep(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Center(child: Icon(icon, size: 15, color: color)),
      ),
    );
  }

  Widget _foodFallback() {
    return Container(
      color: const Color(0xFFF5E6C8),
      child: Icon(Icons.lunch_dining, size: 32, color: Colors.orange.shade300),
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
          _sectionTitle(AppStrings.gallery.tr),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return InkWell(
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
                    placeholder: (_, __) =>
                        Container(color: Colors.grey.shade200),
                    errorWidget: (_, __, ___) => LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
