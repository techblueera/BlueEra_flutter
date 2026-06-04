import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/service/controller/service_controller.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/common/service/view/service_details_view_screen.dart';
import 'package:BlueEra/features/common/service/view/service_upload_screen.dart';
import 'package:BlueEra/features/common/service/view/business_service_list.dart';
import 'package:BlueEra/features/me/hospital/view/v2/widgets/empty_section_placeholder.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Services tab — surfaces the user's posted services with a horizontal
/// preview list and a manage/add CTA. Empty state uses the shared b&w
/// placeholder so the user can jump straight into the upload flow.
class OtherServicesTabV2 extends StatefulWidget {
  const OtherServicesTabV2({super.key});

  @override
  State<OtherServicesTabV2> createState() => _OtherServicesTabV2State();
}

class _OtherServicesTabV2State extends State<OtherServicesTabV2> {
  final _serviceController = getOrPut(() => ServiceController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _serviceController.getBusinessServices({
        ApiKeys.all: false,
        ApiKeys.type: AppConstants.service,
        ApiKeys.providerType: ProviderType.business.title,
        ApiKeys.subType: 'homeService',
      });
    });
  }

  void _onAddServiceTap() {
    if (accountTypeGlobal == AppConstants.individual) {
      if (userProfessionGlobal.trim().isEmpty ||
          userDesignationGlobal.toString().trim().isEmpty) {
        commonSnackBar(message: AppStrings.kindlyAddServicesProfession.tr);
        return;
      }
    } else {
      if (businessCategoryGlobal.trim().isEmpty ||
          businessSubCategoryGlobal.trim().isEmpty) {
        commonSnackBar(message: AppStrings.kindlyAddServicesCategory.tr);
        return;
      }
    }
    Get.to(() => ServiceUploadScreen(providerType: ProviderType.business));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size12),
          CommonCardWidget(
            cardMargin: 0,
            padding: 10,
            child: Obx(() {
              final services = _serviceController.serviceDataList.toList();
              final hasServices = services.isNotEmpty;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ServiceHomeTitleWidget(title: AppStrings.ourServices.tr),
                      InkWell(
                        onTap: () => Get.to(
                          () => BusinessServiceList(
                            providerType: ProviderType.business,
                            showScaffold: true,
                          ),
                        ),
                        child: CustomText(
                          hasServices ? AppStrings.otherManage.tr : AppStrings.viewAll.tr,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (hasServices)
                    _ServicesList(services: services.take(5).toList())
                  else
                    EmptySectionPlaceholder(
                      imageAsset: 'assets/images/other_service_add.png',
                      ctaLabel: AppStrings.addService.tr,
                      ctaIcon: Icons.add_business_outlined,
                      onTap: _onAddServiceTap,
                    ),
                ],
              );
            }),
          ),
          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      ),
    );
  }
}

class _ServicesList extends StatelessWidget {
  final List<GetServiceModel> services;
  const _ServicesList({required this.services});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = services[i];
          final firstPhoto =
              (s.photos?.isNotEmpty ?? false) ? s.photos!.first : '';
          return InkWell(
            onTap: () => Get.to(() => ServiceDetailsScreen(service: s)),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10)),
                    child: SizedBox(
                      height: 100,
                      width: 160,
                      child: firstPhoto.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: firstPhoto,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Container(color: Colors.grey[300]),
                              placeholder: (_, __) =>
                                  Container(color: Colors.grey[200]),
                            )
                          : Container(color: Colors.grey[300]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          s.title ?? AppStrings.na,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                          '₹${s.priceRange?.min ?? 0} - ₹${s.priceRange?.max ?? 0}',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
