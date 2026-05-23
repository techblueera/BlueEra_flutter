import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/widget/common_generic_left_side_category_list.dart';
import 'package:BlueEra/features/common/rental/widget/list_your_property_screen.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared (common) V2 rental dashboard. Lives under `common/rental` so
/// both personal and business surfaces can land here in the future.
///
/// Layout:
///   • **Left rail** — vertical [CommonGenericLeftSideCategoryList]
///     hosting all six [RentalCategory] values (same pattern Discover
///     uses for nested category browsers). All six are visible at
///     once and scroll if the device is short.
///   • **Right pane** — the listings (or empty-state medallion) for
///     the active category.
///   • **FAB** — a custom [AddListingFab] (gradient pill with an
///     embedded icon disc) opens the 6-tile grid bottom sheet. Each
///     tile pushes [ListYourPropertyScreen] with its matching
///     [RentalCategory].
class RentalServicesDashboardScreenV2 extends StatefulWidget {
  const RentalServicesDashboardScreenV2({super.key});

  @override
  State<RentalServicesDashboardScreenV2> createState() =>
      _RentalServicesDashboardScreenV2State();
}

class _RentalServicesDashboardScreenV2State
    extends State<RentalServicesDashboardScreenV2> {
  // Rx so the left rail (which uses Obx internally) can subscribe.
  final RxInt _selectedChip = 0.obs;

  // Single source of truth: left rail + bottom sheet + step-1 push
  // all consume the same category list, so adding a category in one
  // place adds it everywhere.
  static const _categories = RentalCategory.values;

  // Sample sale listings (chip 0).
  static final _houseSaleSamples = <_ListingSample>[
    (
      image: AppImageAssets.propertyHouseSale,
      title: '3 BHK House for Sale',
      bhk: '3 BHK',
      area: '1,200 sqft',
      price: '₹85,00,000',
      location: 'Gomti Nagar, Lucknow',
      forSale: true,
    ),
    (
      image: AppImageAssets.propertyNewProjectSale,
      title: 'Spacious 2 BHK Apartment',
      bhk: '2 BHK',
      area: '950 sqft',
      price: '₹45,00,000',
      location: 'Indira Nagar, Lucknow',
      forSale: true,
    ),
    (
      image: AppImageAssets.propertyShopOfficeSale,
      title: 'Luxury 4 BHK Villa',
      bhk: '4 BHK',
      area: '2,500 sqft',
      price: '₹2,10,00,000',
      location: 'Hazratganj, Lucknow',
      forSale: true,
    ),
  ];

  // Sample shops & offices for sale (chip 5). Same unit-type tag
  // semantics as the rent variant — single sale price per listing
  // (no range).
  static final _shopsSaleSamples = <_ListingSample>[
    (
      image: AppImageAssets.propertyShopOfficeSale,
      title: 'Corner Shop on High-Street',
      bhk: 'Shop',
      area: '520 sqft',
      price: '₹1.2 Cr',
      location: 'Aminabad, Lucknow',
      forSale: true,
    ),
    (
      image: AppImageAssets.propertyShopOfficeSale,
      title: 'Premium Office Floor',
      bhk: 'Office',
      area: '3,200 sqft',
      price: '₹4.8 Cr',
      location: 'Vibhuti Khand, Lucknow',
      forSale: true,
    ),
    (
      image: AppImageAssets.propertyShopOfficeSale,
      title: 'Multi-Brand Showroom',
      bhk: 'Showroom',
      area: '5,400 sqft',
      price: '₹9.5 Cr',
      location: 'MG Road, Lucknow',
      forSale: true,
    ),
  ];

  // Sample shops & offices for rent (chip 4). `bhk` is repurposed
  // as the unit type tag (Shop / Office / Showroom).
  static final _shopsRentSamples = <_ListingSample>[
    (
      image: AppImageAssets.propertyShopOfficeRent,
      title: 'Ground-Floor Shop on Main Road',
      bhk: 'Shop',
      area: '450 sqft',
      price: '₹38,000/mo',
      location: 'Hazratganj, Lucknow',
      forSale: false,
    ),
    (
      image: AppImageAssets.propertyShopOfficeRent,
      title: 'Furnished Office Space',
      bhk: 'Office',
      area: '1,200 sqft',
      price: '₹65,000/mo',
      location: 'Vibhuti Khand, Lucknow',
      forSale: false,
    ),
    (
      image: AppImageAssets.propertyShopOfficeRent,
      title: 'Showroom in High-Street Market',
      bhk: 'Showroom',
      area: '2,400 sqft',
      price: '₹1,40,000/mo',
      location: 'Sapru Marg, Lucknow',
      forSale: false,
    ),
  ];

  // Sample lands & plots listings (chip 3). `bhk` is repurposed as
  // a plot-type tag (Residential / Commercial / Agricultural); the
  // listing card uses a landscape icon for chip-3 rows instead of
  // the bed icon used for houses.
  static final _landsPlotsSamples = <_ListingSample>[
    (
      image: AppImageAssets.propertyLandPlotSale,
      title: 'Residential Plot in Sushant Golf City',
      bhk: 'Residential',
      area: '1,800 sqft',
      price: '₹45L – ₹65L',
      location: 'Sushant Golf City, Lucknow',
      forSale: true,
    ),
    (
      image: AppImageAssets.propertyLandPlotSale,
      title: 'Commercial Plot on Sitapur Road',
      bhk: 'Commercial',
      area: '4,200 sqft',
      price: '₹1.6 Cr – ₹2.1 Cr',
      location: 'Sitapur Road, Lucknow',
      forSale: true,
    ),
    (
      image: AppImageAssets.propertyLandPlotSale,
      title: 'Agricultural Land Near Highway',
      bhk: 'Agricultural',
      area: '2 acres',
      price: '₹85L – ₹1.1 Cr',
      location: 'Mohanlalganj, Lucknow',
      forSale: true,
    ),
  ];

  // Sample new-project listings (chip 2). Prices are ranges to
  // mirror pre-construction pricing bands.
  static final _newProjectSamples = <_ListingSample>[
    (
      image: AppImageAssets.propertyNewProjectSale,
      title: 'Skyline Heights — Phase 1',
      bhk: '2/3 BHK',
      area: '950–1,450 sqft',
      price: '₹65L – ₹1.2 Cr',
      location: 'Sector 150, Noida',
      forSale: true,
    ),
    (
      image: AppImageAssets.propertyNewProjectSale,
      title: 'Green Meadows Residency',
      bhk: '3/4 BHK',
      area: '1,500–2,200 sqft',
      price: '₹1.1 Cr – ₹2.4 Cr',
      location: 'Whitefield, Bengaluru',
      forSale: true,
    ),
    (
      image: AppImageAssets.propertyNewProjectSale,
      title: 'Riverside Towers',
      bhk: '1/2/3 BHK',
      area: '650–1,650 sqft',
      price: '₹42L – ₹1.5 Cr',
      location: 'Wakad, Pune',
      forSale: true,
    ),
  ];

  // Sample rent listings (chip 1).
  static final _houseRentSamples = <_ListingSample>[
    (
      image: AppImageAssets.propertyHouseRent,
      title: '2 BHK Apartment for Rent',
      bhk: '2 BHK',
      area: '1,050 sqft',
      price: '₹22,000/mo',
      location: 'Indira Nagar, Lucknow',
      forSale: false,
    ),
    (
      image: AppImageAssets.propertyHouseRent,
      title: '3 BHK Duplex for Rent',
      bhk: '3 BHK',
      area: '1,800 sqft',
      price: '₹38,000/mo',
      location: 'Gomti Nagar, Lucknow',
      forSale: false,
    ),
    (
      image: AppImageAssets.propertyHouseRent,
      title: 'Furnished Studio Apartment',
      bhk: '1 BHK',
      area: '600 sqft',
      price: '₹15,000/mo',
      location: 'Alambagh, Lucknow',
      forSale: false,
    ),
  ];

  IconData _iconFor(RentalCategory cat) {
    switch (cat) {
      case RentalCategory.housesSale:
      case RentalCategory.housesRent:
        return Icons.house_outlined;
      case RentalCategory.newProjectsSale:
        return Icons.apartment_outlined;
      case RentalCategory.landsPlotsSale:
        return Icons.landscape_outlined;
      case RentalCategory.shopsOfficesRent:
      case RentalCategory.shopsOfficesSale:
        return Icons.storefront_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.rentalServices.tr),
      floatingActionButton: AddListingFab(
        onPressed: () => _showAddRentalSheet(context),
      ),
      body: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left rail — all six categories visible at once, scrolls
            // inside itself if needed. Same widget Discover uses for
            // nested category navigation so the visual language stays
            // consistent across the app.
            CommonGenericLeftSideCategoryList<RentalCategory>(
              items: _categories,
              getLabel: (c) => c.chipLabel,
              getIcon: (c) => c.headerImage,
              isSelected: (c) => _selectedChip.value == c.index,
              onTap: (c, i) => _selectedChip.value = i,
            ),
            Expanded(
              child: Obx(() {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: SizeConfig.size12,
                    bottom: SizeConfig.size24 + 80,
                  ),
                  child: _bodyForChip(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Body dispatcher — sale, rent, projects, lands, shops-rent and
  // shops-sale chips show their static sample listings; everything
  // else surfaces the medallion empty state.
  Widget _bodyForChip() {
    switch (_selectedChip.value) {
      case 0:
        return _buildListings(_houseSaleSamples);
      case 1:
        return _buildListings(_houseRentSamples);
      case 2:
        return _buildListings(_newProjectSamples);
      case 3:
        return _buildListings(_landsPlotsSamples);
      case 4:
        return _buildListings(_shopsRentSamples);
      case 5:
        return _buildListings(_shopsSaleSamples);
      default:
        return _buildEmptyState();
    }
  }

  // Placeholder empty state — same medallion + CTA as before.
  Widget _buildEmptyState() {
    final active = _categories[_selectedChip.value];
    return Container(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: SizeConfig.size32,
        horizontal: SizeConfig.size20,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryColor.withValues(alpha: 0.22),
                      AppColors.primaryColor.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.85],
                  ),
                ),
              ),
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withValues(alpha: 0.78),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.36),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child:
                    Icon(_iconFor(active), color: Colors.white, size: 36),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size20),
          CustomText(
            '${active.chipLabel} listings are empty',
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            'Tap "+" to add a new rental service.',
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w500,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Listings list — sale or rent, picked by the sample's `forSale`
  // flag so the chip + price formatting flip automatically.
  Widget _buildListings(List<_ListingSample> samples) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        0,
        SizeConfig.size12,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < samples.length; i++) ...[
            _listingCard(samples[i]),
            if (i != samples.length - 1)
              SizedBox(height: SizeConfig.size12),
          ],
        ],
      ),
    );
  }

  Widget _listingCard(_ListingSample sample) {
    final radius = BorderRadius.circular(14);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: radius,
        splashColor: AppColors.primaryColor.withValues(alpha: 0.18),
        highlightColor: AppColors.primaryColor.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: radius,
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 88,
                  height: 88,
                  color: AppColors.primaryColor.withValues(alpha: 0.06),
                  child: LocalAssets(
                    imagePath: sample.image,
                    boxFix: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: CustomText(
                        sample.forSale ? 'FOR SALE' : 'FOR RENT',
                        color: AppColors.primaryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomText(
                      sample.title,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _kvChip(_typeChipIconForChip(), sample.bhk),
                        _kvChip(Icons.square_foot, sample.area),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CustomText(
                      sample.price,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.secondaryTextColor),
                        const SizedBox(width: 3),
                        Expanded(
                          child: CustomText(
                            sample.location,
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                            maxLines: 1,
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
      ),
    );
  }

  // Icon for the first chip in a listing card. `bhk` is reused
  // across categories with different semantics (bedrooms / plot type
  // / unit type), so the icon swaps per chip to stay legible.
  IconData _typeChipIconForChip() {
    switch (_selectedChip.value) {
      case 3:
        return Icons.landscape_outlined;
      case 4:
      case 5:
        return Icons.storefront_outlined;
      default:
        return Icons.bed_outlined;
    }
  }

  Widget _kvChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primaryColor),
          const SizedBox(width: 4),
          CustomText(
            label,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  Future<void> _showAddRentalSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                  child: CustomText(
                    'Add Rental Service',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ),
                SizedBox(height: SizeConfig.size12),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                  child: LayoutBuilder(builder: (ctx, constraints) {
                    const double spacing = 10;
                    const int columns = 3;
                    final double itemWidth =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                            columns;
                    final double itemHeight = itemWidth / 0.72;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: _categories
                          .map((cat) => SizedBox(
                                width: itemWidth,
                                height: itemHeight,
                                child: _sheetTile(cat, () {
                                  Navigator.of(sheetCtx).pop();
                                  Get.to(() => ListYourPropertyScreen(
                                        category: cat,
                                      ));
                                }),
                              ))
                          .toList(),
                    );
                  }),
                ),
                SizedBox(height: SizeConfig.size8),
              ],
            ),
          ),
        );
      },
    );
  }
}

typedef _ListingSample = ({
  String image,
  String title,
  String bhk,
  String area,
  String price,
  String location,
  bool forSale,
});

Widget _sheetTile(RentalCategory category, VoidCallback onTap) {
  final radius = BorderRadius.circular(10);
  return InkWell(
    onTap: onTap,
    borderRadius: radius,
    splashColor: AppColors.primaryColor.withValues(alpha: 0.18),
    highlightColor: AppColors.primaryColor.withValues(alpha: 0.08),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFDDE2EE)),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(6),
                ),
              ),
              child: CustomText(
                category.isSale ? 'FOR SALE' : 'FOR RENT',
                color: AppColors.primaryColor,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: LocalAssets(
                  imagePath: category.headerImage,
                  boxFix: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CustomText(
              category.headerSubtitle.replaceFirst(': ', ':\n'),
              textAlign: TextAlign.center,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              maxLines: 3,
              color: AppColors.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    ),
  );
}

/// Polished primary CTA for the rental dashboard. An extended pill
/// FAB with an embedded translucent-white **icon disc** (the plus
/// nests in its own circle inside the gradient pill) for two-layer
/// depth that reads as crafted, not slapped-together. The shadow
/// stack pairs a wide primary-tinted glow for brand presence with a
/// tight contact shadow for tactility. Pressing scales the pill to
/// 94% with a quick easeOut → easeOutBack rebound so it feels
/// physical without bouncing.
class AddListingFab extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;

  const AddListingFab({
    super.key,
    required this.onPressed,
    this.label = 'Add Listing',
  });

  @override
  State<AddListingFab> createState() => _AddListingFabState();
}

class _AddListingFabState extends State<AddListingFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(32);
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              // Wide brand glow — lifts the FAB off the page.
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.42),
                blurRadius: 28,
                offset: const Offset(0, 12),
                spreadRadius: -6,
              ),
              // Tight contact shadow for tactile grounding.
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: radius,
              splashColor: Colors.white.withValues(alpha: 0.22),
              highlightColor: Colors.white.withValues(alpha: 0.10),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryColor,
                      Color.lerp(
                          AppColors.primaryColor, Colors.black, 0.18)!,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Embedded icon disc — translucent white with a
                      // 1px highlight ring gives the "+" its own
                      // depth layer inside the pill.
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.32),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
