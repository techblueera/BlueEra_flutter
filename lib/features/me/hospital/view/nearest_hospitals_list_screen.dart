import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/controller/nearest_hospitals_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_details_list_res_model.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NearestHospitalsListScreen extends StatefulWidget {
  final String pincode;
  final int radius;

  const NearestHospitalsListScreen({
    super.key,
    required this.pincode,
    required this.radius,
  });

  @override
  State<NearestHospitalsListScreen> createState() =>
      _NearestHospitalsListScreenState();
}

class _NearestHospitalsListScreenState
    extends State<NearestHospitalsListScreen> {
  late final NearestHospitalsController controller;

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => NearestHospitalsController());
    controller.fetchNearest(pin: widget.pincode, rad: widget.radius);
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
        if (controller.error.value.isNotEmpty && controller.hospitals.isEmpty) {
          return Center(
            child: CustomText(
              controller.error.value,
              fontSize: SizeConfig.medium,
              color: AppColors.red,
            ),
          );
        }
        if (controller.hospitals.isEmpty) {
          return Center(
            child: CustomText(
              "No hospitals found",
              fontSize: SizeConfig.medium,
              color: AppColors.grey9B,
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: () =>
              controller.fetchNearest(pin: widget.pincode, rad: widget.radius),
          child: ListView.separated(
            itemCount: controller.hospitals.length,
            separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size12),
            itemBuilder: (context, index) {
              final item = controller.hospitals[index];
              return InkWell(
                onTap: () => _showDetailsBottomSheet(context, item),
                child: _HospitalCard(item: item),
              );
            },
          ),
        );
      }),
    );
  }

  void _showDetailsBottomSheet(
      BuildContext context, HospitalDetailsData item) {
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
          initialChildSize: 0.75,
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
                          item.hospitalName?.isNotEmpty == true
                              ? item.hospitalName!
                              : "Unknown",
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
                  Row(
                    children: [
                      Icon(Icons.star,
                          color: AppColors.yellow, size: SizeConfig.size16),
                      SizedBox(width: SizeConfig.size4),
                      CustomText(
                        (item.averageRating ?? 0).toString(),
                        fontSize: SizeConfig.small,
                        color: AppColors.yellow,
                        fontWeight: FontWeight.w700,
                      ),
                      SizedBox(width: SizeConfig.size4),
                      CustomText(
                        "(${item.numberOfReviews ?? 0} reviews)",
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: AppColors.grey9B, size: SizeConfig.size16),
                      SizedBox(width: SizeConfig.size4),
                      Expanded(
                        child: CustomText(
                          item.address?.isNotEmpty == true
                              ? item.address!
                              : "Address not available",
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: SizeConfig.size8),
                  CustomText(
                    "Emergency: ${item.emergencyNumber?.toString() ?? '-'}",
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(height: SizeConfig.size4),
                  CustomText(
                    "Pincode: ${item.pincode ?? '-'}",
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  CustomText(
                    "Facilities",
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size6),
                  CustomText(
                    (item.facilities == null || item.facilities!.isEmpty)
                        ? "No facilities listed."
                        : item.facilities!.where((e) => e.isNotEmpty).join(", "),
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                  ),
                  SizedBox(height: SizeConfig.size12),
                  CustomText(
                    "Beds",
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size6),
                  ...(item.beds ?? []).map((b) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: SizeConfig.size6),
                      child: SizedBox(
                        width: Get.width,
                        child: CommonCardWidget(
                          cardMargin: 0,
                          borderColorColor: AppColors.whiteE5,

                          child: CustomText(
                            "No: ${b.bedNumber ?? '-'} | ${b.name ?? '-'} | Fees: ${b.fees ?? 0} | Occupied: ${b.isOccupied == true ? 'Yes' : 'No'}",
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  SizedBox(height: SizeConfig.size12),
                  CustomText(
                    "Doctors",
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size6),
                  ...(item.doctors ?? []).map((d) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: SizeConfig.size6),
                      child: SizedBox(
                        width: Get.width,
                        child: CommonCardWidget(
                          cardMargin: 0,
                          borderColorColor: AppColors.whiteE5,
                          child: CustomText(
                            "${d.name ?? '-'} | ${d.specialization ?? '-'} | ${d.availability ?? '-'} | On leave: ${d.isOnLeave == true ? 'Yes' : 'No'}",
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  SizedBox(height: SizeConfig.size12),
                  CustomText(
                    "Emergency Services",
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size6),
                  ...(item.emergencyServices ?? []).map((e) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: SizeConfig.size6),
                      child: SizedBox(
                        width: Get.width,
                        child: CommonCardWidget(
                          cardMargin: 0,
                          borderColorColor: AppColors.whiteE5,
                          child: CustomText(
                            "${e.name ?? '-'} (${e.type ?? '-'}) | Active: ${e.isActive == true ? 'Yes' : 'No'}",
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  SizedBox(height: SizeConfig.size12),
                  CustomText(
                    "Wards",
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size6),
                  ...(item.wards ?? []).map((w) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: SizeConfig.size6),
                      child:SizedBox(
                        width: Get.width,
                        child: CommonCardWidget(
                          cardMargin: 0,
                          borderColorColor: AppColors.whiteE5,
                          child: CustomText(
                            "${w.name ?? '-'} | Type: ${w.type ?? '-'} | Available: ${w.availableBeds ?? 0} | Fees: ${w.fees ?? 0}",
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  SizedBox(height: SizeConfig.size12),
                  CustomText(
                    "Careers",
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size6),
                  ...(item.careers ?? []).map((c) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: SizeConfig.size6),
                      child:SizedBox(
                        width: Get.width,
                        child: CommonCardWidget(
                          cardMargin: 0,
                          borderColorColor: AppColors.whiteE5,
                          child: CustomText(
                            "${c.position ?? '-'} | Active: ${c.isActive == true ? 'Yes' : 'No'} | ${c.description ?? ''}",
                            fontSize: SizeConfig.small,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final HospitalDetailsData item;

  const _HospitalCard({required this.item});

  String _buildFacilitiesText(List<String>? facilities) {
    if (facilities == null || facilities.isEmpty) {
      return "No facilities listed.";
    }
    final joined = facilities.where((e) => e.isNotEmpty).join(", ");
    return joined.isNotEmpty ? joined : "No facilities listed.";
  }

  Widget _ratingRow() {
    final rating = item.averageRating ?? 0;
    final reviews = item.numberOfReviews ?? 0;
    return Row(
      children: [
        Icon(Icons.star, color: AppColors.yellow, size: SizeConfig.size16),
        SizedBox(width: SizeConfig.size4),
        CustomText(
          rating.toString(),
          fontSize: SizeConfig.small,
          color: AppColors.yellow,
          fontWeight: FontWeight.w700,
        ),
        SizedBox(width: SizeConfig.size4),
        CustomText(
          "(${reviews} reviews)",
          fontSize: SizeConfig.small,
          color: AppColors.secondaryTextColor,
        ),
        SizedBox(width: SizeConfig.size8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = (item.logoImage?.isNotEmpty == true)
        ? item.logoImage!
        : ((item.beds?.isNotEmpty == true &&
                    (item.beds?.first.image?.isNotEmpty == true)) ==
                true)
            ? (item.beds!.first.image ?? "")
            : "";

    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
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
                            errorBuilder: (c, e, s) => Icon(Icons.image,
                                color: AppColors.placeHolder,
                                size: SizeConfig.size28),
                          )
                        : Icon(Icons.image,
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
                              item.hospitalName?.isNotEmpty == true
                                  ? item.hospitalName!
                                  : "Unknown",
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mainTextColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Icon(Icons.more_vert,
                          //     color: AppColors.grey9B, size: SizeConfig.size18),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size6),
                      _ratingRow(),
                      SizedBox(height: SizeConfig.size6),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: AppColors.grey9B, size: SizeConfig.size16),
                          SizedBox(width: SizeConfig.size4),
                          Expanded(
                            child: CustomText(
                              item.address ?? "",
                              fontSize: SizeConfig.small,
                              color: AppColors.secondaryTextColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size6),
                      CustomText(
                        _buildFacilitiesText(item.facilities),
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
