import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/widget/banner_carousel.dart';
import 'package:BlueEra/features/common/Discover/widget/sticky_category_header_delegate.dart';
import 'package:BlueEra/features/me/vehicle/v3/controller/vehicle_buyer_controller_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/model/vehicle_listing_draft_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/customer/vehicle_trim_listings_screen_v3.dart';
import 'package:BlueEra/features/me/vehicle/v3/view/widgets/vehicle_trim_card_v3.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Buyer entry point for vehicles — what a Discover "New/Old Vehicle Sales"
/// tile now opens.
///
/// Structurally the grocery stores screen: banner carousel, a pinned category
/// strip, then an infinite list. What it lists is different, and that comes
/// straight from §6 of the integration guide — `/products/user/search` starts
/// from **live listings** and rolls them up into trim cards carrying
/// `listingCount` and `priceFrom`. So the buyer browses "Swift VXi — from
/// ₹5.2L, 4 available near you", not a wall of individual listings, and every
/// card is guaranteed to have stock behind it.
///
/// It replaces the old `VehicleListingScreen`, which read the removed
/// `/vehicles` API.
class VehicleDiscoverScreenV3 extends StatefulWidget {
  /// NEW / USED, from the tile the buyer tapped — the Discover automotive
  /// card splits one catalog category into a new and an old tile, and this is
  /// how that choice survives the jump. Null browses both.
  final String? initialCondition;

  const VehicleDiscoverScreenV3({super.key, this.initialCondition});

  @override
  State<VehicleDiscoverScreenV3> createState() =>
      _VehicleDiscoverScreenV3State();
}

class _VehicleDiscoverScreenV3State extends State<VehicleDiscoverScreenV3> {
  final VehicleBuyerControllerV3 _controller =
      getOrPut(() => VehicleBuyerControllerV3());
  final ScrollController _scrollController = ScrollController();

  /// Sentinel for the leading "All" tab — clears the category filter.
  static const String _allTypesId = 'ALL_VEHICLE_TYPES';

  /// Repaints the pinned strip when the category call lands.
  ///
  /// The strip is built in [NestedScrollView.headerSliverBuilder], which is
  /// OUTSIDE any [Obx] — a sliver can't be wrapped in one — so reading the
  /// `categories` RxList there registers no listener. The header was therefore
  /// built once, while the fetch was still in flight, and kept the only entry
  /// it had: "All". Every real vehicle type arrived milliseconds later into a
  /// list nothing was watching, which is why the strip showed a single tab even
  /// though the catalog had stocked types.
  late final Worker _categoriesWorker;

  /// One image per level-0 vehicle type the catalog sells: a car, a
  /// two-wheeler, a commercial truck.
  ///
  /// These replace three freepik hotlinks whose slugs read like cars but whose
  /// numeric ids resolved to a monkey with a guitar, a bowl of dried fruit and
  /// a purple flower — freepik ignores the slug and serves whatever the id
  /// points at, and it stamps hotlinked images with a watermark. Every URL
  /// below was fetched and eyeballed before being committed; if one is ever
  /// swapped, check the replacement the same way rather than trusting the slug.
  final List<String> _bannerImages = const [
    'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?w=1380&q=80',
    'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=1380&q=80',
    'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?w=1380&q=80',
  ];

  @override
  void initState() {
    super.initState();
    // NEW / USED is decided on the previous screen and never changes here, so
    // it is set once and then only ever travels as a query parameter on the
    // search — see [_body] and the controller's `_searchTrims`.
    _controller.conditionFilter.value = widget.initialCondition;
    _categoriesWorker = ever(_controller.categories, (_) {
      if (mounted) setState(() {});
    });
    // Re-entry doesn't refetch unless the filters or the user's location
    // moved — same discipline as the grocery stores screen.
    _controller.loadDiscoverIfNeeded();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _controller.loadMoreTrims();
      }
    });
  }

  @override
  void dispose() {
    _categoriesWorker.dispose();
    _scrollController.dispose();
    super.dispose();
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
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: BannerCarousel(
                images: _bannerImages,
                onBack: () => Get.back(),
                statusBarHeight: statusBarHeight,
                backgroundColor: AppColors.blue5CAF.withValues(alpha: 0.1),
                bottomBorderSide: const BorderSide(
                  color: AppColors.white,
                  width: 2,
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: StickyCategoryHeaderDelegate(
                topPadding: statusBarHeight,
                categories: _stickyCategories(),
                selectedId:
                    _controller.selectedCategoryId.value ?? _allTypesId,
                onCategoryTap: (item) {
                  _controller.selectCategory(
                      item.id == _allTypesId ? null : item.id);
                  setState(() {});
                },
                onBack: () => Get.back(),
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
          // No condition strip: the buyer already answered new-vs-old on the
          // Discover tile that opened this screen, so re-asking it here was a
          // second control for a decision already made. The answer lives on
          // `conditionFilter` and travels as a query parameter on every search
          // — it needs no UI of its own.
          body: _body(),
        ),
      ),
    );
  }

  /// Label for the leading tab. It clears the CATEGORY filter but not the
  /// condition — new-vs-old came from the tile that opened this screen and
  /// holds for every tab — so a bare "All" overstated what it does. It now says
  /// which side of that split the buyer is on.
  String get _allTabLabel {
    switch (_controller.conditionFilter.value) {
      case VehicleListingCondition.isNew:
        return 'All New Vehicle';
      case VehicleListingCondition.used:
        return 'All Old Vehicle';
      default:
        return 'All Vehicles';
    }
  }

  /// "All …" plus the vehicle catalog's level-0 categories — the same list the
  /// seller's add flow browses, see [VehicleBuyerControllerV3.fetchCategories].
  List<StickyCategory> _stickyCategories() {
    return [
      StickyCategory(id: _allTypesId, name: _allTabLabel),
      ..._controller.categories.map(
        (c) => StickyCategory(
          id: c.id,
          name: c.name,
          imageUrl: c.image.isEmpty ? null : c.image,
        ),
      ),
    ];
  }

  Widget _body() {
    return Obx(() {
      if (_controller.locationMissing.value) return _locationPrompt();

      // The brand strip stays put while the results scroll — it is a filter,
      // not content, and scrolling it away hides the reason the list is short.
      return Column(
        children: [
          _brandStrip(),
          Expanded(child: _results()),
        ],
      );
    });
  }

  /// Level-1 of the vehicle catalog — brands, scoped to the type tab above.
  /// Deliberately much smaller than the icon tabs: this is a refinement of the
  /// choice already made up there, not a peer of it.
  ///
  /// Reads observables, so it must be built inside [_body]'s [Obx].
  Widget _brandStrip() {
    final brands = _controller.subCategories;
    if (brands.isEmpty) return const SizedBox.shrink();
    final selected = _controller.selectedSubCategoryId.value;
    return Container(
      height: SizeConfig.size32,
      margin: EdgeInsets.only(top: SizeConfig.size8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
        itemCount: brands.length + 1,
        separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size6),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _brandPill(
              label: 'All',
              isActive: selected == null,
              onTap: () => _controller.selectSubCategory(null),
            );
          }
          final brand = brands[i - 1];
          return _brandPill(
            label: brand.name,
            isActive: selected == brand.id,
            onTap: () => _controller.selectSubCategory(brand.id),
          );
        },
      ),
    );
  }

  Widget _brandPill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryColor : AppColors.white,
          borderRadius: BorderRadius.circular(SizeConfig.size16),
          border: Border.all(
            color: isActive ? AppColors.primaryColor : AppColors.greyE5,
          ),
        ),
        child: CustomText(
          label,
          fontSize: SizeConfig.extraSmall,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          color: isActive ? AppColors.white : AppColors.secondaryTextColor,
          maxLines: 1,
        ),
      ),
    );
  }

  /// The trim list itself, plus its loading and empty states.
  Widget _results() {
    final loading = _controller.trimsStatus.value == Status.LOADING ||
        _controller.trimsStatus.value == Status.INITIAL;
    final trims = _controller.trims;

    if (loading && trims.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (trims.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          message: 'No vehicles listed near you yet.',
        ),
      );
    }

    return RefreshIndicator(
      // A deliberate pull means "ask the server" — it skips the category cache.
      onRefresh: () => _controller.loadDiscover(force: true),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size12,
          SizeConfig.size10,
          SizeConfig.size12,
          SizeConfig.size24,
        ),
        itemCount: trims.length + (_controller.isLoadingMore.value ? 1 : 0),
        separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
        itemBuilder: (_, i) {
          if (i >= trims.length) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return VehicleTrimCardV3(
            trim: trims[i],
            onTap: () => Get.to(
              () => VehicleTrimListingsScreenV3(trim: trims[i]),
            ),
          );
        },
      ),
    );
  }

  /// The buyer search is location-scoped by contract, so with neither
  /// coordinates nor a pincode there is nothing to ask for — prompt instead
  /// of showing an empty list the user can't act on.
  Widget _locationPrompt() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.size24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: 44, color: AppColors.secondaryTextColor),
            SizedBox(height: SizeConfig.size12),
            CustomText(
              'Turn on location to see vehicles near you',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size12),
            ElevatedButton(
              onPressed: () async {
                await LocationService.ensureUsableLocation();
                await _controller.loadDiscover();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Enable location',
                style: TextStyle(color: Colors.white, fontFamily: 'OpenSans'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
