import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/common/service/controller/add_service_controller.dart';
import 'package:BlueEra/features/common/service/controller/service_controller.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/common/service/view/add_services_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/controller/earn_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_contact_map_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_gallery_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_qr_code_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/widget/earn_service_testimonial_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeServiceHomePage extends StatefulWidget {
  const HomeServiceHomePage({super.key});

  @override
  State<HomeServiceHomePage> createState() => _HomeServiceHomePageState();
}

class _HomeServiceHomePageState extends State<HomeServiceHomePage> {
  late final EarnProfileController earnProfileController;
  late final ServiceController serviceController;

  @override
  void initState() {
    super.initState();
    earnProfileController = getOrPut(() => EarnProfileController());
    serviceController = getOrPut(() => ServiceController());
    _fetchHomeServices();
  }

  void _fetchHomeServices() {
    serviceController.getEarnServices(
      {
        ApiKeys.all: false,
        ApiKeys.type: AppConstants.service,
        ApiKeys.providerType: ProviderType.user.title,
        ApiKeys.subType: 'homeService',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      child: Column(
        children: [
          _buildServiceSection(),
          Obx(() => EarnServiceGalleryCard(
                gallery:
                    earnProfileController.earnProfile.value?.galleryImages,
                onAddImage: _pickAndUploadGalleryImage,
                onRemoveImage: earnProfileController.removeGalleryImage,
              )),
          EarnServiceTestimonialCard(testimonials: const []),
          EarnServiceContactMapCard(controller: earnProfileController),
          EarnServiceQrCodeWidget(controller: earnProfileController),
          SizedBox(height: 4 * kBottomNavigationBarHeight),
        ],
      ),
    );
  }

  // ─── Service Section ───
  Widget _buildServiceSection() {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  'Home Service',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainTextColor,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          Obx(() {
            if (serviceController.isServiceDataFirstLoading.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final services = serviceController.serviceDataList;
            if (services.isEmpty) {
              return _buildEmptyServiceState();
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: services.length,
              separatorBuilder: (_, __) =>
                  SizedBox(height: SizeConfig.size10),
              itemBuilder: (_, i) => _buildServiceCard(services[i]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildServiceCard(GetServiceModel service) {
    final photo =
        (service.photos != null && service.photos!.isNotEmpty)
            ? service.photos!.first
            : null;
    final min = service.priceRange?.min;
    final max = service.priceRange?.max;
    final priceLabel = (min == null && max == null)
        ? null
        : '₹${_formatPrice(min)}-${_formatPrice(max)}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.greyE5, width: 0.5),
        ),
        child: Stack(
          children: [
            // Background image (or grey fallback) fills the whole card.
            if (photo != null)
              CachedNetworkImage(
                imageUrl: photo,
                height: SizeConfig.size265,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: SizeConfig.size265,
                  color: AppColors.greyE5,
                ),
                errorWidget: (_, __, ___) => Container(
                  height: SizeConfig.size265,
                  color: AppColors.greyE5,
                  alignment: Alignment.center,
                  child: Icon(Icons.image_not_supported_outlined,
                      color: AppColors.secondaryTextColor),
                ),
              )
            else
              Container(
                height: SizeConfig.size265,
                width: double.infinity,
                color: AppColors.greyE5,
              ),


            // Bottom overlay: frosted-glass bar with all service info.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12.0),
                  bottomRight: Radius.circular(12.0),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    padding: EdgeInsets.all(SizeConfig.size12),
                    color: const Color(0x80000000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          service.title ?? '',
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                        if ((service.description ?? '').isNotEmpty) ...[
                          SizedBox(height: SizeConfig.size6),
                          CustomText(
                            service.description!,
                            fontSize: SizeConfig.small,
                            color: AppColors.white.withValues(alpha: 0.85),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        SizedBox(height: SizeConfig.size10),
                        Row(
                          children: [
                            if (priceLabel != null) ...[
                              CustomText(
                                priceLabel,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                              SizedBox(width: SizeConfig.size6),
                              CustomText(
                                'Range',
                                fontSize: SizeConfig.small,
                                color: AppColors.white.withValues(alpha: 0.75),
                              ),
                            ],
                            const Spacer(),
                            InkWell(
                              onTap: () => _onEditService(service),
                              borderRadius: BorderRadius.circular(10.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 6.0),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(
                                      color: AppColors.primaryColor,
                                      width: 1.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryColor
                                          .withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    LocalAssets(
                                      imagePath: AppIconAssets.pen_line,
                                      imgColor: AppColors.primaryColor,
                                      height: 14,
                                      width: 14,
                                    ),
                                    SizedBox(width: SizeConfig.size6),
                                    CustomText(
                                      AppStrings.edit,
                                      fontSize: SizeConfig.small,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int? value) {
    if (value == null) return '';
    if (value >= 1000) {
      final k = value / 1000;
      final fixed = k == k.truncateToDouble()
          ? k.toStringAsFixed(0)
          : k.toStringAsFixed(1);
      return '${fixed}K';
    }
    return value.toString();
  }

  void _onEditService(GetServiceModel service) async {
    final addCtrl = getOrPut(() => AddServiceController());
    // Stash-then-navigate keeps the tap responsive. Populate happens on
    // the next screen's initState, not on the current frame.
    addCtrl.stashEdit(
      service: service,
      providerType: ProviderType.user,
      serviceSubType: 'homeService',
    );
    final result = await Get.to(() => const AddServicesScreenNew());
    if (result == true) {
      _fetchHomeServices();
    }
  }

  Widget _buildEmptyServiceState() {
    return InkWell(
      onTap: _onAddServiceTap,
      child: Container(
        height: SizeConfig.size200,
        width: SizeConfig.screenWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          image: DecorationImage(
            image: AssetImage(AppImageAssets.homeMadeFoodBanner),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: AppColors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LocalAssets(
                  imagePath: AppImageAssets.noMeContent,
                  height: SizeConfig.size80,
                  width: SizeConfig.size80,
                ),
                const SizedBox(height: 6.0),
                CustomText(
                  'You Have Not Added Any Service',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: AppColors.primaryColor,
                        border: Border.all(color: AppColors.primaryColor),
                      ),
                      child: CustomText(
                        'Add Home Service',
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAddServiceTap() async {
    // Await the full add flow (ServiceUploadScreen → AddServicesScreenNew).
    // createServiceApi() pops back here via Get.close(2), so on return we
    // re-fetch the list — same refresh-on-return contract as the edit flow.
    await Get.toNamed(
      RouteHelper.getAddServicesScreenRoute(),
      arguments: {
        ApiKeys.id: userId,
        ApiKeys.providerType: ProviderType.user,
      },
    );
    _fetchHomeServices();
  }

  Future<void> _pickAndUploadGalleryImage() async {
    final path = await CommonImageUploadTile.pickImage(
      context: context,
      title: 'Upload Photo',
    );
    if (path == null || path.isEmpty) return;
    await earnProfileController.addGalleryImage(File(path));
  }
}
