import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/service/controller/service_controller.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/common/service/view/business_service_list.dart';
import 'package:BlueEra/features/common/service/view/service_details_view_screen.dart';
import 'package:BlueEra/features/common/service/view/service_upload_screen.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
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
      _fetchServices();
    });
  }

  /// Re-fetches the business services list. Called on first mount AND
  /// after any navigation that can add / edit / delete a service
  /// returns, because the create flow ends with `Get.close(2)` back to
  /// this tab without touching [ServiceController.serviceDataList] — so
  /// without this refetch the new service never appears until the whole
  /// screen is rebuilt from scratch.
  void _fetchServices() {
    _serviceController.getBusinessServices({
      ApiKeys.all: false,
      ApiKeys.type: AppConstants.service,
      ApiKeys.providerType: ProviderType.business.title,
      ApiKeys.subType: 'homeService',
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
    Get.to(() => ServiceUploadScreen(
          providerType: ProviderType.business,
          enableBankingHints: true,
        ))?.then((_) => _fetchServices());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: SizeConfig.size12),
          // Contribution / Bank / Refer deck. No catalog card here: this tab IS
          // the add surface and carries its own add masthead, so a card pointing
          // at the screen you are already on would be noise.
          OrderActionsCarousel(),
          SizedBox(height: SizeConfig.size12),
          Obx(() {
            final services = _serviceController.serviceDataList.toList();
            final hasServices = services.isNotEmpty;
            // Gate: same validation pattern the school overview uses (see
            // [_QuickInfoRequiredBanner] in school_overview_tab_v2.dart) —
            // when the section has no data yet, replace the whole card
            // with a full-width banner that pushes into the add flow, so
            // the "profile incomplete" message reads at first glance
            // instead of being tucked under a title row.
            if (!hasServices) {
              return _ServiceRequiredBanner(onTap: _onAddServiceTap);
            }
            return CommonCardWidget(
              cardMargin: 0,
              padding: 10,
              child: Column(
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
                            // Opt-in so the "+ Add Service" CTA inside the
                            // manage screen also swaps to banking hints for
                            // Financial-Services businesses.
                            enableBankingHints: true,
                          ),
                        )?.then((_) => _fetchServices()),
                        child: CustomText(
                          'Manage',
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ServicesList(services: services.take(5).toList()),
                ],
              ),
            );
          }),
          SizedBox(height: kBottomNavigationBarHeight + 10),
        ],
      ),
    );
  }
}

/// Profile-completion gate. Mirrors [_QuickInfoRequiredBanner] in
/// `school_overview_tab_v2.dart`: a full-width bordered card with a
/// centered icon, heading, message and primary CTA. Surfaces when the
/// user is registered as one of the service-eligible business types
/// (Consultant / Beautician / IT Digital Services / etc.) but hasn't
/// added a single service yet — without at least one service the
/// public profile has nothing for customers to discover.
class _ServiceRequiredBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _ServiceRequiredBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LocalAssets(
              imagePath: AppIconAssets.emptyIcon,
              height: 60,
              width: 60,
            ),
            SizedBox(height: SizeConfig.size16),
            CustomText(
              'Add your services to complete your profile',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            SizedBox(height: SizeConfig.size8),
            CustomText(
              // Category examples match the eight service-eligible business
              // types listed in `business_enquiry_sheet.dart` — kept short
              // so the two most recognisable ones anchor the message and
              // the "etc." covers the rest.
              'Add at least one service so customers can '
              'discover your business — the rest of your profile can only '
              'go live once a service has been added.',
              fontSize: 13,
              color: AppColors.secondaryTextColor,
              textAlign: TextAlign.center,
              maxLines: 6,
            ),
            SizedBox(height: SizeConfig.size16),
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16,
                  vertical: SizeConfig.size10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_business_outlined,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    CustomText(
                      'Add Service',
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
