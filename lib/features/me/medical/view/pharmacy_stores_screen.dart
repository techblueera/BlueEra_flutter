import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/common/auth/model/get_categories_model.dart';
import 'package:BlueEra/features/me/medical/controller/medical_cart_controller.dart';
import 'package:BlueEra/features/me/medical/model/pharmacy_sub_categories.dart';
import 'package:BlueEra/features/me/medical/view/medical_cart_screen.dart';
import 'package:BlueEra/features/me/medical/view/nearest_pharmacies_list_screen.dart';
import 'package:BlueEra/features/me/medical/widget/medical_floating_cart.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:BlueEra/features/common/search/model/store_search_config.dart';
import 'package:BlueEra/features/common/search/view/store_search_screen.dart';

/// Standalone pharmacy listing — banner + sticky sub-category tabs over the
/// pharmacy cards, the same shape as the grocery stores screen.
///
/// Opened from the Discover Pharmacy section: the tapped sub-category arrives
/// as [initialSubCategoryId] and starts selected, and the tabs let the user
/// move between sub-categories without going back.
///
/// Carries the floating cart, so a cart built on a pharmacy's detail screen
/// stays reachable after backing out to this list — the same reason grocery
/// puts its cart on both the stores list and the store detail.
class PharmacyStoresScreen extends StatefulWidget {
  /// Sub-category `_id` to open on. Null lands on the leading "All Pharmacy"
  /// tab, which lists every pharmacy unfiltered.
  final String? initialSubCategoryId;

  const PharmacyStoresScreen({super.key, this.initialSubCategoryId});

  @override
  State<PharmacyStoresScreen> createState() => _PharmacyStoresScreenState();
}

class _PharmacyStoresScreenState extends State<PharmacyStoresScreen> {
  /// Currently selected sub-category `_id`, sent to `business/filter` as
  /// `subCategory`. Null → the "All Pharmacy" tab, which sends no filter and
  /// lists every pharmacy.
  String? _selectedSubId;

  late final List<SubCategories> _subCategories;

  /// Sentinel id for the leading "All Pharmacy" tab. [StickyCategory] keys off a
  /// String id and a real sub-category id can't be null, so it needs its own.
  static const String _kAllTabId = '__all__';

  final _cart = getOrPut(() => MedicalCartController(), permanent: true);

  // TODO: swap for pharmacy-specific artwork — these are the healthcare
  // banners, reused so the screen ships with images known to load.
  final List<String> _bannerImages = const [
    "https://img.freepik.com/free-photo/doctor-with-his-patient_1098-603.jpg?w=1380",
    "https://img.freepik.com/free-photo/front-view-covid-recovery-center-young-patient-with-medical-mask_23-2148856202.jpg?w=1380",
    "https://img.freepik.com/free-photo/team-young-specialist-doctors-standing-corridor-hospital_1303-21202.jpg?w=1380",
  ];

  @override
  void initState() {
    super.initState();
    // Read once: the onboarding categories are already loaded by the time
    // Discover can route here, and a stable list keeps the tabs from
    // reshuffling under the user mid-session.
    _subCategories = PharmacySubCategories.all();
    // No incoming sub-category → land on "All" (null) rather than silently
    // pre-filtering to whichever sub-category happens to be first.
    _selectedSubId = widget.initialSubCategoryId;
  }

  /// Every exit from this screen (system back, banner back, sticky-header back)
  /// funnels through here. The cart is in-memory only and is NOT tied to this
  /// route, but leaving is the point of no return in the UI — so warn rather
  /// than let a built-up cart quietly strand. Mirrors the grocery stores screen.
  void _handleBack() {
    if (_cart.isEmpty) {
      Get.back();
      return;
    }
    _showCartWarningDialog();
  }

  void _showCartWarningDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.remove_shopping_cart_rounded,
                  color: AppColors.primaryColor, size: 56),
              const SizedBox(height: 16),
              CustomText(
                'Leave without ordering?',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              CustomText(
                'Your cart still has items. Place the order now, or leave and come back to it later.',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      // Pops the dialog, then the screen.
                      onPressed: () {
                        Get.back();
                        Get.back();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.greyE5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(
                        'Leave',
                        color: AppColors.secondaryTextColor,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MedicalCartScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: CustomText(
                        'Place Order',
                        color: AppColors.white,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w800,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return PopScope(
      // canPop:false + the callback routes the system back gesture through the
      // same warning as the on-screen back buttons.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
                    child: BannerCarousel(
                      images: _bannerImages,
                      onBack: _handleBack,
                      statusBarHeight: statusBarHeight,
                      backgroundColor:
                          AppColors.blue5CAF.withValues(alpha: 0.1),
                      bottomBorderSide: const BorderSide(
                        color: AppColors.white,
                        width: 2,
                      ),
                    ),
                  ),
                  // Sub-category tabs. Skipped entirely if the categories
                  // haven't loaded — better no strip than an empty one.
                  if (_subCategories.isNotEmpty)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: StickyCategoryHeaderDelegate(
                        topPadding: statusBarHeight,
                        // The header paints a search bar; this is what it opens —
                        // the shared store search, scoped to this vertical by its
                        // StoreSearchConfig. Tapping a result opens that profile.
                        onSearchTap: () => Get.to(
                            () => StoreSearchScreen(config: StoreSearchConfig.pharmacy())),
                        singleLineLabel: false,
                        categories: [
                          // Leading tab — every pharmacy, no sub-category
                          // filter. Labelled off the API's own category name
                          // ("Pharmacy"), so it reads "All Pharmacy" and stays
                          // right if the backend ever renames the category.
                          StickyCategory(
                            id: _kAllTabId,
                            name: 'All ${PharmacySubCategories.title()}',
                            imageUrl: PharmacySubCategories.fallbackIcon,
                          ),
                          ..._subCategories.map((sub) => StickyCategory(
                                id: sub.sId ?? '',
                                name: sub.name ?? '',
                                imageUrl: PharmacySubCategories.iconFor(sub),
                              )),
                        ],
                        // Null selection = "All", so map it back to the sentinel
                        // or no chip would look selected.
                        selectedId: _selectedSubId ?? _kAllTabId,
                        onCategoryTap: (item) {
                          final id = item.id == _kAllTabId ? null : item.id;
                          if (id == _selectedSubId) return;
                          setState(() => _selectedSubId = id);
                        },
                        onBack: _handleBack,
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
                // Re-keying on the selection tears down the list's State so its
                // initState refetches with the new `subCategory`.
                body: NearestPharmaciesListScreen(
                  key: ValueKey('pharmacy_${_selectedSubId ?? 'all'}'),
                  category: PHARMACY,
                  subCategory: _selectedSubId,
                ),
              ),
              // Same floating cart as the pharmacy detail screen, so a cart
              // built there survives backing out to this list. Self-hides when
              // empty and carries its own SafeArea.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MedicalFloatingCart(controller: _cart),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
