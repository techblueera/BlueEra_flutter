import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/me/medical/controller/nearest_pharmacies_controller.dart';
import 'package:BlueEra/features/me/medical/view/medical_category_selector_widget.dart';
import 'package:BlueEra/features/common/store/widget/store_live_photos_viewer.dart';
import 'package:BlueEra/features/me/medical/view/medical_pharmacy_detail_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NearestPharmaciesListScreen extends StatefulWidget {
  final String category;
  final String? subCategory;

  const NearestPharmaciesListScreen({
    super.key,
    required this.category,
    this.subCategory,
  });

  @override
  State<NearestPharmaciesListScreen> createState() => _NearestPharmaciesListScreenState();
}

class _NearestPharmaciesListScreenState extends State<NearestPharmaciesListScreen> {
  late final NearestPharmaciesController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => NearestPharmaciesController());
    // Cache-aware on entry: re-entering (or switching back to) the same
    // sub-category within the TTL serves the loaded list instead of re-hitting
    // the API. Pull-to-refresh below is the explicit force-fresh path — the
    // same split grocery's stores screen uses.
    controller.fetchNearestIfNeeded(
      category: widget.category,
      subCategory: widget.subCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Material(
      color: Colors.transparent,
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
        }
        if (controller.error.value.isNotEmpty && controller.pharmacies.isEmpty) {
          return Center(
            child: CustomText(
              controller.error.value,
              fontSize: SizeConfig.medium,
              color: AppColors.red,
            ),
          );
        }
        if (controller.pharmacies.isEmpty) {
          return Center(
            child: CustomText(
              "No pharmacies found",
              fontSize: SizeConfig.medium,
              color: AppColors.grey9B,
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: () =>
              controller.fetchNearest(category: widget.category, subCategory: widget.subCategory),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: SizeConfig.size12,
              left: SizeConfig.size12,
              right: SizeConfig.size12,
              // +70 clears the floating cart stacked over this list, so the
              // last card can still be scrolled clear of it (same allowance
              // the grocery store list makes).
              bottom: SizeConfig.paddingL + 70,
            ),
            itemCount: controller.pharmacies.length,
            // No separator — the card carries its own bottom margin, and `index`
            // drives the alternating teal/violet palette.
            itemBuilder: (context, index) =>
                PharmacyStoreCard(item: controller.pharmacies[index]),
          ),
        );
      }),
    );
  }

  // ignore: unused_element
}

/// A pharmacy in the listing — the same flat white row the grocery, restaurant
/// and product listings use (`assets/grocery_card.jpeg`).
///
/// Its own widget bound to [PharmacyItem] rather than a shared card: this feed
/// is a different shape (a `raw` map off `business/filter`, not
/// `GetAllStoreResModel`), and each vertical is free to diverge.
class PharmacyStoreCard extends StatelessWidget {
  const PharmacyStoreCard({super.key, required this.item});

  final PharmacyItem item;

  static const Color _kCardBorder = AppColors.greyE5;
  static const Color _kPillBorder = Color(0xFFE3E8EF);
  static const double _kRadius = 16;

  /// The one accent on the card — distance and its pin.
  static const Color _kAccent = AppColors.blue5CAF;

  List<String> get _livePhotos {
    final photos = item.raw['live_photos'];
    if (photos is! List) return const [];
    return photos
        .map((p) => p?.toString() ?? '')
        .where((p) => p.trim().isNotEmpty)
        .toList();
  }

  String get _subCategoryName {
    final sub =
        item.raw['sub_category_details'] ?? item.raw['sub_category_Of_Business'];
    final name = sub is Map ? sub['name']?.toString() : null;
    return (name == null || name.isEmpty) ? 'Pharmacy' : name;
  }

  /// Rating printed verbatim, so drop a trailing `.0` on whole numbers.
  String get _ratingLabel =>
      item.rating % 1 == 0 ? '${item.rating.toInt()}' : '${item.rating}';

  /* Only the product count read raw ints, and the box shows distance now —
     restore this alongside [_productsPill].
  int? _rawInt(String key) {
    final value = item.raw[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
  */

  double get _lat {
    final l = item.raw['business_location'];
    return l is Map ? (l['lat'] as num?)?.toDouble() ?? 0.0 : 0.0;
  }

  double get _lng {
    final l = item.raw['business_location'];
    return l is Map ? (l['lon'] as num?)?.toDouble() ?? 0.0 : 0.0;
  }

  String get _heroTag => 'pharmacy_live_${item.id}';

  void _openDetail() =>
      Get.to(() => MedicalPharmacyDetailScreen(businessId: item.id));

  @override
  Widget build(BuildContext context) {
    final photos = _livePhotos;

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kCardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_kRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openDetail,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size14,
              vertical: SizeConfig.size14,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _avatar(context, photos),
                SizedBox(width: SizeConfig.size12),
                Expanded(child: _details(context)),
                SizedBox(width: SizeConfig.size10),
                // _productsPill(),
                _distancePill(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The logo. Ringed and tappable when there are live photos behind it, plain
  /// when there aren't — the ring IS the cue that there is something to open.
  Widget _avatar(BuildContext context, List<String> photos) {
    const double size = 64;
    final avatar = CachedAvatarWidget(
      imageUrl: item.logo,
      size: size,
      borderColor: Colors.white,
      borderRadius: size / 2,
      showProfileOnFullScreen: false,
    );

    if (photos.isEmpty) return avatar;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => StoreLivePhotosViewer.open(
        context,
        images: photos,
        heroTag: _heroTag,
        title: item.name.isNotEmpty ? item.name : 'Pharmacy',
      ),
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Color(0xFF16C47F),
              Color(0xFF00A8E8),
              Color(0xFF8B5CF6),
              Color(0xFFFF7A45),
              Color(0xFFFFC53D),
              Color(0xFF16C47F),
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Hero(tag: _heroTag, child: avatar),
        ),
      ),
    );
  }

  Widget _details(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          item.name.isNotEmpty ? item.name : 'Pharmacy',
          fontSize: 17,
          color: AppColors.mainTextColor,
          fontWeight: FontWeight.w700,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: SizeConfig.size6),
        _ratingRow(),
        SizedBox(height: SizeConfig.size6),
        _locationRow(context),
      ],
    );
  }

  Widget _ratingRow() {
    return Row(
      children: [
        LocalAssets(imagePath: AppIconAssets.star, height: 13, width: 13),
        const SizedBox(width: 4),
        CustomText(
          _ratingLabel,
          fontSize: 13,
          color: AppColors.mainTextColor,
          fontWeight: FontWeight.w700,
        ),
        _divider(),
        Flexible(
          child: CustomText(
            _subCategoryName,
            fontSize: 13,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w400,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// The address; the whole row opens directions.
  Widget _locationRow(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showMapBottomSheet(context),
      child: _locationRowBody(),
    );
  }

  /// The directions sheet for this pharmacy — shared by the address line and
  /// the distance box, which are two ways into the same action.
  void _showMapBottomSheet(BuildContext context) {
    RouteMapBottomSheet.show(
        context: context,
        destinationName: item.name.isNotEmpty ? item.name : 'Pharmacy',
        destinationAddress: item.address,
        destinationLat: _lat,
        destinationLng: _lng,
      livePhotos: _livePhotos,
      visitCallback: _openDetail,
    );
  }

  Widget _locationRowBody() {
    return Row(
      children: [
        LocalAssets(
          imagePath: AppIconAssets.location_outline,
          imgColor: _kAccent,
          height: 13,
          width: 13,
        ),
        const SizedBox(width: 4),
        // Distance moved to the box on the right — printing it here too would
        // put the same number on the card twice. Restore this (and the
        // divider) if the box goes back to the product count.
        // CustomText(
        //   '${_distanceKm.toStringAsFixed(1)} Km',
        //   fontSize: 12.5,
        //   color: _kAccent,
        //   fontWeight: FontWeight.w700,
        // ),
        // _divider(),
        Flexible(
          child: CustomText(
            item.address.isNotEmpty ? item.address : AppStrings.na,
            fontSize: 12.5,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w400,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 12,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: const Color(0xFFDDE3EB),
      );

  /// Straight-line distance from the user to this pharmacy, in km.
  double get _distanceKm => calculateDistanceKm(
        LocationService.lat,
        LocationService.lng,
        _lat,
        _lng,
      );

  /// How far away the pharmacy is, in the outlined box on the right.
  ///
  /// This box used to carry the product count (see the commented-out
  /// [_productsPill] below), which `business/filter` never sends — so it read
  /// as a dash on every card in the list. Distance is known from the
  /// coordinates the listing already carries, and it's what the list is sorted
  /// on.
  ///
  /// Tapping it opens the directions sheet, the same as the address line.
  Widget _distancePill(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showMapBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPillBorder, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.location_outline,
                  imgColor: _kAccent,
                  height: 12,
                  width: 12,
                ),
                const SizedBox(width: 4),
                CustomText(
                  _distanceKm.toStringAsFixed(1),
                  fontSize: 13,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
            const SizedBox(height: 1),
            CustomText(
              'Km away',
              fontSize: 10,
              color: AppColors.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }

  /* Commented out — the box shows distance now (see [_distancePill] above).
  /// The product count, in its own outlined box.
  ///
  /// `business/filter` does not send `total_product_count` yet (see
  /// docs/backend/PHARMACY_CUSTOMER_FLOW_INTEGRATION.md), so this usually reads
  /// as a dash — the honest rendering of "not sent", and the same thing the
  /// other listings show before their counts land. It used to print `0`, which
  /// claimed the pharmacy stocked nothing.
  Widget _productsPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kPillBorder, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LocalAssets(
                imagePath: AppIconAssets.productCartIcon,
                imgColor: _kAccent,
                height: 12,
                width: 12,
              ),
              const SizedBox(width: 4),
              CustomText(
                _formatCount(_rawInt('total_product_count')),
                fontSize: 13,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          const SizedBox(height: 1),
          CustomText(
            'Products',
            fontSize: 10,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  /// A count, or `-` when it isn't known. Null is "not answered", not zero.
  static String _formatCount(int? count) {
    if (count == null) return '-';
    if (count >= 1000000) {
      final v = count / 1000000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}M';
    }
    if (count >= 1000) {
      final v = count / 1000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}K';
    }
    return '$count';
  }
  */
}

class PharmacyDetailsSheet extends StatelessWidget {
  final PharmacyItem item;

  const PharmacyDetailsSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: item.name,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row

            CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceHomeTitleWidget(
                    title: "Inventories",
                  ),

                  SizedBox(height: SizeConfig.size8),
                  // Inventory List
                  ...item.inventories.map((inv) => _buildInventoryCard(inv)).toList(),
                  SizedBox(height: SizeConfig.size8),
                ],
              ),
            ),
            MedicalCategorySelectorWidget(),

            CommonCardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceHomeTitleWidget(
                    title: "Contact Us",
                  ),
                  _ratingRow(item),
                  SizedBox(height: SizeConfig.size8),

                  // Pharmacy Details
                  CommonCardWidget(
                    cardMargin: 0,
                    borderColorColor: AppColors.whiteE5,
                    child: Column(
                      children: [
                        _detailText(
                            "Address", "${item.address.isNotEmpty ? item.address : 'Address not available'}"),
                        _detailText("Timing",
                            "${item.openFrom.isNotEmpty ? item.openFrom : '-'} - ${item.openTill.isNotEmpty ? item.openTill : '-'}"),
                        _detailText("Contact", "${item.phone.isNotEmpty ? item.phone : '-'}"),
                        _detailText("Email", "${item.email.isNotEmpty ? item.email : '-'}"),
                        _detailText("Pincode", "${item.pincode.isNotEmpty ? item.pincode : '-'}"),
                      ],
                    ),
                  ),

                  SizedBox(height: SizeConfig.size16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to keep the build method clean
  Widget _detailText(
    String text,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            "${text} : ",
            // fontSize: SizeConfig.small,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w500,
          ),
          Expanded(
            child: CustomText(
              value,
              // fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(dynamic inv) {
    final Map<String, dynamic> j = inv as Map<String, dynamic>;
    final String pv = j['productVariant']?.toString() ?? '';
    final String city = j['cityName']?.toString() ?? '';
    final String pin = j['pincode']?.toString() ?? '';
    final List batches = (j['batches'] as List?) ?? [];

    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size8),
      child: SizedBox(
        width: Get.width,
        child: CommonCardWidget(
          cardMargin: 0,
          borderColorColor: AppColors.whiteE5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                "Variant: ${pv.isNotEmpty ? pv : '-'}",
                color: AppColors.secondaryTextColor,
              ),
              SizedBox(height: SizeConfig.size4),
              CustomText("City: $city | Pincode: $pin", color: AppColors.secondaryTextColor),
              SizedBox(height: SizeConfig.size6),
              ...batches.map((b) {
                final Map<String, dynamic> bj = b as Map<String, dynamic>;
                return CustomText(
                  "Batch: ${bj['batchNumber'] ?? '-'} | Qty: ${bj['quantity'] ?? 0} | MRP: ${bj['mrp'] ?? 0} | Price: ${bj['sellingPrice'] ?? 0}",
                  color: AppColors.secondaryTextColor,
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  // Note: Ensure _ratingRow is also accessible or moved here
  Widget _ratingRow(PharmacyItem item) {
    // Paste your existing _ratingRow logic here or pass it in
    return Container();
  }
}
