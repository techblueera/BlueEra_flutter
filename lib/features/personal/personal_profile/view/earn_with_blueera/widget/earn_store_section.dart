import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/model/earn_profile_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/view/earn_service_dashboard_view.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
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

  // Rich storefront card for an earn flavour the user has created. Opens
  // the full earn dashboard on tap.
  Widget _buildEarnMadeCard(String type, EarnProfileModel? profile) {
    final meta = _earnTypeMeta(type);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              Get.to(() => EarnServiceDashboardView(earnType: type)),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.07),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _earnCardHero(meta, profile),
                  _earnCardBody(profile),
                ],
              ),
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

  // Hero band — cover image (or a gradient fallback) under a dark scrim,
  // with the earn-type pill, a live/offline status pill, and the logo +
  // store name sitting on the seam.
  Widget _earnCardHero(
      ({IconData icon, String title, String subtitle}) meta,
      EarnProfileModel? profile) {
    final cover = (profile?.coverImage?.isNotEmpty ?? false)
        ? profile!.coverImage!
        : ((profile?.galleryImages.isNotEmpty ?? false)
            ? profile!.galleryImages.first
            : '');
    final name = (profile?.serviceName?.trim().isNotEmpty ?? false)
        ? profile!.serviceName!.trim()
        : meta.title;
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover.isNotEmpty)
            CachedNetworkImage(
              imageUrl: cover,
              fit: BoxFit.cover,
              memCacheWidth: 800,
              placeholder: (_, __) => _earnHeroFallback(meta),
              errorWidget: (_, __, ___) => _earnHeroFallback(meta),
            )
          else
            _earnHeroFallback(meta),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x4D000000),
                  Color(0x00000000),
                  Color(0xD9001626),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: _earnGlassPill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(meta.icon, size: 12, color: Colors.white),
                  const SizedBox(width: 5),
                  CustomText(meta.title,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ],
              ),
            ),
          ),
          Positioned(top: 10, right: 10, child: _earnStatusPill()),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: (profile?.serviceLogo?.isNotEmpty ?? false)
                          ? CachedNetworkImage(
                              imageUrl: profile!.serviceLogo!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _logoFallback(meta),
                            )
                          : _logoFallback(meta),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomText(
                    name,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoFallback(({IconData icon, String title, String subtitle}) meta) {
    return Container(
      color: AppColors.primaryColor.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Icon(meta.icon, color: AppColors.primaryColor, size: 22),
    );
  }

  Widget _earnHeroFallback(
      ({IconData icon, String title, String subtitle}) meta) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue5CAF, AppColors.primaryColor],
        ),
      ),
      child: Center(
        child: Icon(meta.icon,
            size: 46, color: Colors.white.withValues(alpha: 0.25)),
      ),
    );
  }

  Widget _earnGlassPill({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.18), width: 0.6),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _earnStatusPill() {
    final isLive = _viewCtrl.shopStatusOpenClose.value;
    final color =
        isLive ? const Color(0xFF12B76A) : AppColors.secondaryTextColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          CustomText(isLive ? 'Live' : 'Offline',
              fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
        ],
      ),
    );
  }

  // Info zone — address, attribute chips (diet / delivery / monthly
  // payment / gallery count) and a primary "Open Dashboard" CTA.
  Widget _earnCardBody(EarnProfileModel? profile) {
    final address = profile?.address?.trim() ?? '';
    final diet = profile?.foodType?.trim() ?? '';
    final chips = <Widget>[
      if (diet.isNotEmpty) _earnDietChip(diet),
      if (profile?.homeDelivery ?? false)
        _earnInfoChip(Icons.delivery_dining_rounded, 'Home Delivery'),
      if (profile?.monthlyPayment ?? false)
        _earnInfoChip(Icons.event_repeat_rounded, 'Monthly Payment'),
      if ((profile?.galleryImages.length ?? 0) > 0)
        _earnInfoChip(Icons.photo_library_rounded,
            '${profile!.galleryImages.length} Photos'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (address.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_rounded,
                    size: 15, color: AppColors.primaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: CustomText(
                    address,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
          const SizedBox(height: 14),
          Container(
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
                const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _earnInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.16), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryColor),
          const SizedBox(width: 5),
          CustomText(label,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor),
        ],
      ),
    );
  }

  Widget _earnDietChip(String diet) {
    final isVeg = !diet.toLowerCase().contains('non');
    final color = isVeg ? const Color(0xFF1E7D34) : const Color(0xFFC0341D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1.5),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Center(
              child: Container(
                width: 4.5,
                height: 4.5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
          const SizedBox(width: 5),
          CustomText(diet,
              fontSize: 11, fontWeight: FontWeight.w700, color: color),
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
/// individual-profile dashboard's Statics tab. Labeled placeholders for
/// now — real data will be wired in later.
class EarnStatSections extends StatelessWidget {
  const EarnStatSections({super.key});

  static const List<String> _titles = [
    'Home Made Food Statistics',
    'Home Made Products Statistics',
    'Home Service Statistics',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final title in _titles) _section(title),
      ],
    );
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
