import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_dashboard_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared "Store" tab body used across the individual-profile dashboards
/// (self-employed / professional / social / gig). Lists all three earn
/// flavours (food / product / service): the flavour the user has created
/// shows a rich storefront card that opens the earn dashboard; the rest
/// show an "Add" card routing to that flavour's create flow.
class EarnStoreCards extends StatefulWidget {
  const EarnStoreCards({super.key});

  @override
  State<EarnStoreCards> createState() => _EarnStoreCardsState();
}

class _EarnStoreCardsState extends State<EarnStoreCards> {
  final _viewCtrl = Get.find<ViewPersonalDetailsController>();
  final _earnProfileCtrl = getOrPut(() => EarnProfileController());
  final _earnServiceCtrl = getOrPut(() => EarnServiceController());

  // The three earn flavours surfaced in the Store tab, in display order.
  static const List<String> _earnTypes = [
    'homeMadeFood',
    'homeMadeProduct',
    'homeService',
  ];

  bool get _hasEarnProfile => _viewCtrl.earnProfileType.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_hasEarnProfile) {
      _earnProfileCtrl.fetchEarnProfile();
      _viewCtrl.shopStatusOpenClose.value =
          serviceProviderStatusGlobal.toUpperCase() ==
              AppConstants.OPEN.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final createdTypes = _viewCtrl.earnProfileType;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final type in _earnTypes)
            createdTypes.contains(type)
                ? _buildEarnMadeCard(type, _earnProfileCtrl.profileOfType(type))
                : _buildEarnAddCard(type),
        ],
      );
    });
  }

  // Storefront card for an earn flavour the user has created — mirrors the
  // Discover store card (hero + logo/name/address + feature strip), but
  // without chat / rating / share. A type badge (Home Made Food / Product /
  // Service) sits on the cover image. Opens the full earn dashboard on tap.
  Widget _buildEarnMadeCard(String type, EarnProfileModel? profile) {
    final meta = _earnTypeMeta(type);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greyE5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.to(() => EarnServiceDashboardView(earnType: type)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _madeHero(meta, profile),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _madeTitleRow(meta, profile),
                      const SizedBox(height: 12),
                      _madeFeatureRow(profile),
                      const SizedBox(height: 12),
                      _madeFooterCta(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // "Add" card for an earn flavour the user hasn't created yet. Routes to
  // that flavour's create flow.
  Widget _buildEarnAddCard(String type) {
    final meta = _earnTypeMeta(type);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onAddEarnProfile(type),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.18),
                      width: 0.8,
                    ),
                  ),
                  child:
                      Icon(meta.icon, color: AppColors.primaryColor, size: 24),
                ),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        meta.title,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mainTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        meta.subtitle,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: SizeConfig.size8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          size: 15, color: Colors.white),
                      const SizedBox(width: 3),
                      CustomText('Add',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onAddEarnProfile(String type) {
    _earnServiceCtrl.handleServiceTap(
      context,
      CollapsibleGridModel(
        name: _earnTypeMeta(type).title,
        slugId: _earnSlug(type),
        icon: '',
      ),
    );
  }

  String _earnSlug(String type) {
    switch (type) {
      case 'homeMadeFood':
        return HOME_MADE_FOOD;
      case 'homeMadeProduct':
        return HOME_MADE_PRODUCTS;
      case 'homeService':
        return HOME_SERVICES;
      default:
        return '';
    }
  }

  // Hero — cover image (or fallback) with a type badge (Home Made Food /
  // Product / Service) top-left. No rating / share.
  Widget _madeHero(
      ({IconData icon, String title, String subtitle}) meta,
      EarnProfileModel? profile) {
    final cover = (profile?.coverImage?.isNotEmpty ?? false)
        ? profile!.coverImage!
        : ((profile?.galleryImages.isNotEmpty ?? false)
            ? profile!.galleryImages.first
            : '');
    return SizedBox(
      height: 170,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover.isNotEmpty)
            CachedNetworkImage(
              imageUrl: cover,
              fit: BoxFit.cover,
              memCacheWidth: 800,
              placeholder: (_, __) => Container(color: AppColors.blue5CFF),
              errorWidget: (_, __, ___) => _madeHeroFallback(meta),
            )
          else
            _madeHeroFallback(meta),
          Positioned(top: 10, left: 10, child: _madeBadge(meta)),
        ],
      ),
    );
  }

  Widget _madeBadge(({IconData icon, String title, String subtitle}) meta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          CustomText(meta.title,
              fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
        ],
      ),
    );
  }

  Widget _madeHeroFallback(
      ({IconData icon, String title, String subtitle}) meta) {
    return Container(
      color: AppColors.blue5CFF,
      alignment: Alignment.center,
      child: Icon(meta.icon,
          size: 54, color: AppColors.primaryColor.withValues(alpha: 0.45)),
    );
  }

  // Logo + name + distance·address row (no map / chat).
  Widget _madeTitleRow(
      ({IconData icon, String title, String subtitle}) meta,
      EarnProfileModel? profile) {
    final km = calculateDistanceKm(
      LocationService.lat,
      LocationService.lng,
      profile?.latitude ?? 0.0,
      profile?.longitude ?? 0.0,
    );
    final name = (profile?.serviceName?.trim().isNotEmpty ?? false)
        ? profile!.serviceName!.trim()
        : meta.title;
    final address = profile?.address?.trim() ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.greyE5, width: 1.5),
          ),
          child: CachedAvatarWidget(
            imageUrl: profile?.serviceLogo ?? '',
            size: 42,
            borderColor: Colors.transparent,
            borderRadius: 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                name,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 13, color: AppColors.primaryColor),
                  const SizedBox(width: 3),
                  CustomText('${km.toStringAsFixed(0)}KM Away',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor),
                  CustomText('  |  ',
                      fontSize: 11.5, color: AppColors.greyE5),
                  Expanded(
                    child: CustomText(
                      address.isNotEmpty ? address : AppStrings.na,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3-column feature strip (delivery / monthly payment / diet-or-verified).
  Widget _madeFeatureRow(EarnProfileModel? profile) {
    const dark = AppColors.secondaryTextColor;
    final diet = (profile?.foodType ?? '').trim();
    final hasDiet = diet.isNotEmpty;
    final isVeg = !diet.toLowerCase().contains('non');
    final dietColor =
        isVeg ? const Color(0xFF1E7D34) : const Color(0xFFC0341D);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyE5),
        color: AppColors.whiteF4,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _featureCol(
                  Icons.delivery_dining_rounded, 'Home Delivery', dark),
            ),
            _vDivider(),
            Expanded(
              child: _featureCol(
                  Icons.currency_rupee_rounded, 'Monthly Payment', dark),
            ),
            _vDivider(),
            Expanded(
              child: hasDiet
                  ? _featureCol(
                      Icons.check_box_rounded,
                      isVeg ? 'Veg Food' : 'Non-Veg',
                      dietColor,
                    )
                  : _featureCol(Icons.verified_rounded, 'Verified',
                      AppColors.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      width: 1,
      color: AppColors.greyE5);

  Widget _featureCol(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 5),
          CustomText(
            label,
            fontSize: 12,
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

  // Primary "Open Dashboard" CTA (no chat).
  Widget _madeFooterCta() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue5CAF, AppColors.primaryColor],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomText('Open Dashboard',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
        ],
      ),
    );
  }

  // Icon + human title + subtitle for each earn flavour. Mirrors the title
  // mapping in EarnServiceDashboardView so labels stay in sync.
  ({IconData icon, String title, String subtitle}) _earnTypeMeta(
      String? earnType) {
    switch (earnType) {
      case 'homeService':
        return (
          icon: Icons.home_repair_service_rounded,
          title: 'Home Service',
          subtitle: 'Offer home services',
        );
      case 'homeMadeProduct':
        return (
          icon: Icons.shopping_bag_rounded,
          title: 'Home Made Product',
          subtitle: 'Sell your home-made products',
        );
      case 'homeMadeFood':
        return (
          icon: Icons.soup_kitchen_rounded,
          title: 'Home Made Food',
          subtitle: 'Sell tiffins & home-made dishes',
        );
      default:
        return (
          icon: Icons.storefront_rounded,
          title: AppStrings.store.tr,
          subtitle: '',
        );
    }
  }
}

/// Per-earn-type statistics shown below the main analytics in each
/// individual-profile dashboard's Statics tab. Only the earn flavours the
/// user has actually created a profile for are shown (keyed off
/// [ViewPersonalDetailsController.earnProfileType]); if they have none, this
/// renders nothing. Labeled placeholders for now — real data wired later.
class EarnStatSections extends StatelessWidget {
  const EarnStatSections({super.key});

  // (earnProfileType key, display title) per earn flavour, in display order.
  static const List<({String type, String title})> _sections = [
    (type: 'homeMadeFood', title: 'Home Made Food Statistics'),
    (type: 'homeMadeProduct', title: 'Home Made Products Statistics'),
    (type: 'homeService', title: 'Home Service Statistics'),
  ];

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ViewPersonalDetailsController>()) {
      return const SizedBox.shrink();
    }
    final viewCtrl = Get.find<ViewPersonalDetailsController>();
    return Obx(() {
      final ownedTypes = viewCtrl.earnProfileType;
      final visible =
          _sections.where((s) => ownedTypes.contains(s.type)).toList();
      if (visible.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final s in visible) _section(s.title)],
      );
    });
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withValues(alpha: 0.45),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                Expanded(
                  child: CustomText(
                    title,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size10),
            CustomText(
              'Statistics coming soon',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
