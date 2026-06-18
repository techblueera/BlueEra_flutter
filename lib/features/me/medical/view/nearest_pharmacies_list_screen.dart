import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical/controller/nearest_pharmacies_controller.dart';
import 'package:BlueEra/features/me/medical/view/medical_category_selector_widget.dart';
import 'package:BlueEra/features/me/medical/view/medical_pharmacy_detail_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  State<NearestPharmaciesListScreen> createState() =>
      _NearestPharmaciesListScreenState();
}

class _NearestPharmaciesListScreenState
    extends State<NearestPharmaciesListScreen> {
  late final NearestPharmaciesController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => NearestPharmaciesController());
    controller.fetchNearest(category: widget.category, subCategory: widget.subCategory);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Material(
      color: Colors.transparent,
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor));
        }
        if (controller.error.value.isNotEmpty &&
            controller.pharmacies.isEmpty) {
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
          onRefresh: () => controller.fetchNearest(
              category: widget.category, subCategory: widget.subCategory),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              vertical: SizeConfig.size12,
              horizontal: SizeConfig.size12,
            ),
            itemCount: controller.pharmacies.length,
            separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size16),
            itemBuilder: (context, index) {
              final item = controller.pharmacies[index];
              return _PharmacyCard(
                item: item,
                onTap: () => Get.to(
                  () => MedicalPharmacyDetailScreen(
                    businessId: item.id,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }


  // ignore: unused_element
}

class _PharmacyCard extends StatelessWidget {
  final PharmacyItem item;
  final VoidCallback onTap;

  const _PharmacyCard({required this.item, required this.onTap});

  // ── Data helpers (read the richer raw fields the model keeps around) ──
  String get _banner {
    final photos = item.raw['live_photos'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first?.toString() ?? '';
      if (first.isNotEmpty) return first;
    }
    return item.logo;
  }

  String get _location {
    final csp = item.raw['city_state_pincode']?.toString() ?? '';
    if (csp.isNotEmpty) return csp;
    if (item.address.isNotEmpty) return item.address;
    return item.pincode;
  }

  String get _description {
    final desc = item.raw['business_description']?.toString() ?? '';
    return desc.isNotEmpty ? desc : item.address;
  }

  String get _timings {
    if (item.openFrom.isEmpty) return '';
    return item.openTill.isNotEmpty
        ? '${item.openFrom} - ${item.openTill}'
        : item.openFrom;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(SizeConfig.size16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bannerSection(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size12,
                SizeConfig.size10,
                SizeConfig.size12,
                SizeConfig.size12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  SizedBox(height: SizeConfig.size12),
                  _infoRow(
                    icon: Icons.local_pharmacy_outlined,
                    title: AppStrings.overview.tr,
                    body: _description,
                  ),
                  if (_timings.isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size10),
                    _infoRow(
                      icon: Icons.access_time_rounded,
                      title: AppStrings.openTime.tr,
                      body: _timings,
                      bodyColor: AppColors.green00,
                    ),
                  ],
                  SizedBox(height: SizeConfig.size14),
                  _actions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Banner with rating pill + action icons ──
  Widget _bannerSection() {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(SizeConfig.size16),
      ),
      child: Stack(
        children: [
          SizedBox(
            height: SizeConfig.size150,
            width: double.infinity,
            child: _banner.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: _banner,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.liteWhite),
                    errorWidget: (_, __, ___) => _bannerPlaceholder(),
                  )
                : _bannerPlaceholder(),
          ),
          Positioned(
            top: SizeConfig.size10,
            left: SizeConfig.size10,
            child: _ratingPill(),
          ),
          Positioned(
            top: SizeConfig.size10,
            right: SizeConfig.size10,
            child: Row(
              children: [
                _circleIcon(Icons.ios_share_outlined),
                SizedBox(width: SizeConfig.size8),
                _circleIcon(Icons.bookmark_border_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerPlaceholder() {
    return Container(
      color: AppColors.liteWhite,
      alignment: Alignment.center,
      child: Icon(
        Icons.local_pharmacy_outlined,
        color: AppColors.placeHolder,
        size: SizeConfig.size48,
      ),
    );
  }

  Widget _ratingPill() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size8,
        vertical: SizeConfig.size4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(SizeConfig.size20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded,
              color: AppColors.white, size: SizeConfig.size16),
          SizedBox(width: SizeConfig.size4),
          CustomText(
            item.rating.toStringAsFixed(1),
            fontSize: SizeConfig.small,
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      height: SizeConfig.size32,
      width: SizeConfig.size32,
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.mainTextColor, size: SizeConfig.size18),
    );
  }

  // ── Logo + name + location ──
  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _logo(),
        SizedBox(width: SizeConfig.size12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                item.name.isNotEmpty ? item.name : AppStrings.unknown.tr,
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: SizeConfig.size4),
              Row(
                children: [
                  Icon(Icons.location_on,
                      color: AppColors.primaryColor, size: SizeConfig.size16),
                  SizedBox(width: SizeConfig.size4),
                  Expanded(
                    child: CustomText(
                      _location,
                      fontSize: SizeConfig.small,
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

  Widget _logo() {
    return Container(
      height: SizeConfig.size48,
      width: SizeConfig.size48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.whiteEE, width: 1.5),
      ),
      child: ClipOval(
        child: item.logo.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: item.logo,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.liteWhite),
                errorWidget: (_, __, ___) => _logoPlaceholder(),
              )
            : _logoPlaceholder(),
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Container(
      color: AppColors.liteWhite,
      child: Icon(Icons.local_pharmacy,
          color: AppColors.placeHolder, size: SizeConfig.size24),
    );
  }

  // ── Reusable info row (icon chip + title + body) ──
  Widget _infoRow({
    required IconData icon,
    required String title,
    required String body,
    Color? bodyColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: SizeConfig.size32,
          width: SizeConfig.size32,
          decoration: BoxDecoration(
            color: AppColors.skyBlueE4,
            borderRadius: BorderRadius.circular(SizeConfig.size8),
          ),
          child: Icon(icon,
              color: AppColors.primaryColor, size: SizeConfig.size18),
        ),
        SizedBox(width: SizeConfig.size10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                title,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size2),
              CustomText(
                body,
                fontSize: SizeConfig.small,
                color: bodyColor ?? AppColors.secondaryTextColor,
                fontWeight: bodyColor != null ? FontWeight.w600 : null,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Chat + Book Now action row ──
  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              side: const BorderSide(color: AppColors.primaryColor),
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SizeConfig.size12),
              ),
            ),
            icon: Icon(Icons.chat_bubble_outline_rounded,
                size: SizeConfig.size18, color: AppColors.primaryColor),
            label: CustomText(
              AppStrings.chat.tr,
              fontSize: SizeConfig.medium,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: SizeConfig.size12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SizeConfig.size12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  AppStrings.bookNow.tr,
                  fontSize: SizeConfig.medium,
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
                SizedBox(width: SizeConfig.size8),
                Icon(Icons.arrow_forward_rounded,
                    size: SizeConfig.size18, color: AppColors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }
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
                  ...item.inventories
                      .map((inv) => _buildInventoryCard(inv))
                      .toList(),
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
                        _detailText("Address",
                            "${item.address.isNotEmpty ? item.address : 'Address not available'}"),
                        _detailText("Timing",
                            "${item.openFrom.isNotEmpty ? item.openFrom : '-'} - ${item.openTill.isNotEmpty ? item.openTill : '-'}"),
                        _detailText(
                            "Contact", "${item.phone.isNotEmpty ? item.phone : '-'}"),
                        _detailText(
                            "Email", "${item.email.isNotEmpty ? item.email : '-'}"),
                        _detailText("Pincode",
                            "${item.pincode.isNotEmpty ? item.pincode : '-'}"),
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
              CustomText("City: $city | Pincode: $pin",
                  color: AppColors.secondaryTextColor),
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
