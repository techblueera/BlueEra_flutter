import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical/controller/nearest_pharmacies_controller.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NearestPharmaciesListScreen extends StatefulWidget {
  final String pincode;
  final int radius;
  const NearestPharmaciesListScreen({
    super.key,
    required this.pincode,
    required this.radius,
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
    controller.fetchNearest(pincode: widget.pincode, radius: widget.radius);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Material(
      color: AppColors.appBackgroundColor,
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
              pincode: widget.pincode, radius: widget.radius),
          child: ListView.separated(
            itemCount: controller.pharmacies.length,
            separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size12),
            itemBuilder: (context, index) {
              final item = controller.pharmacies[index];
              return InkWell(
                onTap: () => _showDetailsBottomSheet(context, item),
                child: _PharmacyCard(item: item),
              );
            },
          ),
        );
      }),
    );
  }

  void _showDetailsBottomSheet(BuildContext context, PharmacyItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SizeConfig.size16),
        ),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.all(SizeConfig.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          item.name.isNotEmpty ? item.name : "Unknown",
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.close, color: AppColors.grey9B),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size8),
                  _ratingRow(item),
                  SizedBox(height: SizeConfig.size8),
                  CustomText(
                    item.address.isNotEmpty
                        ? item.address
                        : "Address not available",
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  CustomText(
                    "Timing: ${item.openFrom.isNotEmpty ? item.openFrom : '-'} - ${item.openTill.isNotEmpty ? item.openTill : '-'}",
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  CustomText(
                    "Contact: ${item.phone.isNotEmpty ? item.phone : '-'}",
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(height: SizeConfig.size4),
                  CustomText(
                    "Email: ${item.email.isNotEmpty ? item.email : '-'}",
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(height: SizeConfig.size4),
                  CustomText(
                    "Pincode: ${item.pincode.isNotEmpty ? item.pincode : '-'}",
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(height: SizeConfig.size12),
                  CustomText(
                    "Inventories",
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  ...item.inventories.map((inv) {
                    final Map<String, dynamic> j = inv as Map<String, dynamic>;
                    final String pv = j['productVariant']?.toString() ?? '';
                    final String city = j['cityName']?.toString() ?? '';
                    final String pin = j['pincode']?.toString() ?? '';
                    final List batches = (j['batches'] as List?) ?? [];
                    return Padding(
                      padding:
                          EdgeInsets.only(bottom: SizeConfig.size8),
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
                                fontSize: SizeConfig.small,
                                color: AppColors.secondaryTextColor,
                              ),
                              SizedBox(height: SizeConfig.size4),
                              CustomText(
                                "City: ${city.isNotEmpty ? city : '-'} | Pincode: ${pin.isNotEmpty ? pin : '-'}",
                                fontSize: SizeConfig.small,
                                color: AppColors.secondaryTextColor,
                              ),
                              SizedBox(height: SizeConfig.size6),
                              ...batches.map((b) {
                                final Map<String, dynamic> bj =
                                    b as Map<String, dynamic>;
                                final String bn =
                                    bj['batchNumber']?.toString() ?? '';
                                final int qty = bj['quantity'] ?? 0;
                                final num mrp = bj['mrp'] ?? 0;
                                final num sp = bj['sellingPrice'] ?? 0;
                                return CustomText(
                                  "Batch: ${bn.isNotEmpty ? bn : '-'} | Qty: $qty | MRP: $mrp | Price: $sp",
                                  fontSize: SizeConfig.small,
                                  color: AppColors.secondaryTextColor,
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  SizedBox(height: SizeConfig.size16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _ratingRow(PharmacyItem item) {
    return Row(
      children: [
        Icon(Icons.star, color: AppColors.yellow, size: SizeConfig.size16),
        SizedBox(width: SizeConfig.size4),
        CustomText(
          item.rating.toString(),
          fontSize: SizeConfig.small,
          color: AppColors.yellow,
          fontWeight: FontWeight.w700,
        ),
        SizedBox(width: SizeConfig.size4),
        CustomText(
          "(${item.reviews} reviews)",
          fontSize: SizeConfig.small,
          color: AppColors.secondaryTextColor,
        ),
        SizedBox(width: SizeConfig.size8),
        Icon(Icons.location_on_outlined,
            color: AppColors.grey9B, size: SizeConfig.size16),
        SizedBox(width: SizeConfig.size4),
        CustomText(
          item.pincode,
          fontSize: SizeConfig.small,
          color: AppColors.secondaryTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  final PharmacyItem item;
  const _PharmacyCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final String imageUrl = item.logo;
    return Padding(
      padding:  EdgeInsets.only(right: 10.0),
      child: CommonCardWidget(
        cardMargin: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(SizeConfig.size30),
                  child: Container(
                    width: SizeConfig.size50,
                    height: SizeConfig.size50,
                    color: AppColors.liteWhite,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Icon(Icons.local_pharmacy,
                                color: AppColors.placeHolder,
                                size: SizeConfig.size28),
                          )
                        : Icon(Icons.local_pharmacy,
                            color: AppColors.placeHolder,
                            size: SizeConfig.size28),
                  ),
                ),
                SizedBox(width: SizeConfig.size12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomText(
                              item.name.isNotEmpty ? item.name : "Unknown",
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mainTextColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size6),
                      Row(
                        children: [
                          Icon(Icons.star,
                              color: AppColors.yellow, size: SizeConfig.size16),
                          SizedBox(width: SizeConfig.size4),
                          CustomText(
                            item.rating.toString(),
                            fontSize: SizeConfig.small,
                            color: AppColors.yellow,
                            fontWeight: FontWeight.w700,
                          ),
                          SizedBox(width: SizeConfig.size4),
                          CustomText(
                            "(${item.reviews} reviews)",
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                          ),
                          SizedBox(width: SizeConfig.size8),
                          Icon(Icons.location_on_outlined,
                              color: AppColors.grey9B,
                              size: SizeConfig.size16),
                          SizedBox(width: SizeConfig.size4),
                          CustomText(
                            item.pincode,
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              item.address.isNotEmpty ? item.address : "Address not available",
              fontSize: SizeConfig.small,
              color: AppColors.secondaryTextColor,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              "Open: ${item.openFrom.isNotEmpty ? item.openFrom : '-'}",
              fontSize: SizeConfig.small,
              color: AppColors.green00,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}
