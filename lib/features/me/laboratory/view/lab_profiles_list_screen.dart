import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical/controller/nearest_pharmacies_controller.dart';
import 'package:BlueEra/features/me/medical/view/medical_pharmacy_detail_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LabProfilesListScreen extends StatefulWidget {
  final String category;
  final String? subCategory;

  const LabProfilesListScreen({
    super.key,
    required this.category,
    this.subCategory,
  });

  @override
  State<LabProfilesListScreen> createState() => _LabProfilesListScreenState();
}

class _LabProfilesListScreenState extends State<LabProfilesListScreen> {
  late final NearestPharmaciesController controller;

  @override
  void initState() {
    super.initState();
    controller =
        getOrPut(() => NearestPharmaciesController(), tag: 'lab_profiles');
    controller.fetchNearest(
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
        if (controller.isLoading.value && controller.pharmacies.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }
        if (controller.error.value.isNotEmpty &&
            controller.pharmacies.isEmpty) {
          return Center(
            child: CustomText(
              AppStrings.failedToLoadData.tr,
              fontSize: SizeConfig.medium,
              color: AppColors.red,
            ),
          );
        }
        if (controller.pharmacies.isEmpty) {
          return Center(
            child: CustomText(
              AppStrings.noLaboratoriesFound.tr,
              fontSize: SizeConfig.medium,
              color: AppColors.grey9B,
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: () => controller.fetchNearest(
            category: widget.category,
            subCategory: widget.subCategory,
          ),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              vertical: SizeConfig.size10,
              horizontal: SizeConfig.size8,
            ),
            itemCount: controller.pharmacies.length,
            separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size12),
            itemBuilder: (context, index) {
              final item = controller.pharmacies[index];
              return InkWell(
                onTap: () => Get.to(
                  () => MedicalPharmacyDetailScreen(businessId: item.id),
                ),
                child: _LabCard(item: item),
              );
            },
          ),
        );
      }),
    );
  }
}

class _LabCard extends StatelessWidget {
  final PharmacyItem item;

  const _LabCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return CommonCardWidget(
      cardMargin: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _logo(),
          SizedBox(width: SizeConfig.size12),
          Expanded(child: _details()),
        ],
      ),
    );
  }

  Widget _logo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(SizeConfig.size12),
      child: Container(
        width: SizeConfig.size60,
        height: SizeConfig.size60,
        color: AppColors.liteWhite,
        child: item.logo.isNotEmpty
            ? Image.network(
                item.logo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.image,
                  color: AppColors.placeHolder,
                  size: SizeConfig.size32,
                ),
              )
            : Icon(
                Icons.image,
                color: AppColors.placeHolder,
                size: SizeConfig.size32,
              ),
      ),
    );
  }

  Widget _details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          item.name.isNotEmpty ? item.name : AppStrings.unknown.tr,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w700,
          color: AppColors.mainTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: SizeConfig.size6),
        if (item.address.isNotEmpty)
          ExpandableText(
            text: item.address,
            trimLines: 1,
            isReadMoreNewLine: false,
            expandMode: ExpandMode.dialog,
            style: TextStyle(
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w400,
              fontFamily: AppConstants.OpenSans,
            ),
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
                color: AppColors.grey9B, size: SizeConfig.size16),
            SizedBox(width: SizeConfig.size4),
            Expanded(
              child: CustomText(
                item.pincode,
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (item.openFrom.isNotEmpty) ...[
          SizedBox(height: SizeConfig.size6),
          CustomText(
            "${AppStrings.openTime.tr}: ${item.openFrom}",
            fontSize: SizeConfig.small,
            color: AppColors.green00,
            fontWeight: FontWeight.w600,
          ),
        ],
      ],
    );
  }
}
