import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/service/controller/service_controller.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/common/service/view/service_details_view_screen.dart';
import 'package:BlueEra/features/common/service/view/service_upload_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';

/// Service listing scoped to business & channel providers only (no
/// earn-with-BlueEra / user path). [providerType] must be
/// [ProviderType.business] or [ProviderType.channel].
class BusinessServiceList extends StatefulWidget {
  final ProviderType providerType;
  final String? channelId;
  final bool isShowGrid;
  final bool showScaffold;

  const BusinessServiceList({
    super.key,
    required this.providerType,
    this.channelId,
    this.isShowGrid = true,
    this.showScaffold = false,
  });

  @override
  State<BusinessServiceList> createState() => _BusinessServiceListState();
}

class _BusinessServiceListState extends State<BusinessServiceList> {
  ServiceController serviceController = Get.put(ServiceController());
  final ScrollController scrollController = ScrollController();
  late Map<String, dynamic> queryParams;

  @override
  void initState() {
    super.initState();
    _buildQueryParams();
    // Defer the fetch — getBusinessServices() flips `isServiceDataFirstLoading`
    // and clears `serviceDataList` synchronously, which would notify any Obx
    // already subscribed in the current build frame ("setState during build").
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      serviceController.getBusinessServices(queryParams);
    });
    scrollController.addListener(_scrollListener);
  }

  void _buildQueryParams() {
    queryParams = {
      ApiKeys.all: false,
      ApiKeys.type: AppConstants.service,
      ApiKeys.providerType: widget.providerType.title,
    };

    if (widget.channelId != null) {
      queryParams[ApiKeys.channelId] = widget.channelId;
    }
  }

  /// Detects changes to providerType / channelId and refreshes data
  @override
  void didUpdateWidget(covariant BusinessServiceList oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool shouldRefetch =
        oldWidget.providerType != widget.providerType ||
            oldWidget.channelId != widget.channelId;

    if (shouldRefetch) {
      _buildQueryParams();
      serviceController.getBusinessServices(queryParams);
    }
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      serviceController.getBusinessServices(queryParams, isLoadMore: true);
    }
  }

  void _goToAddService() {
    Get.to(() => ServiceUploadScreen(
          providerType: widget.providerType,
          channelId: widget.channelId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();

    if (!widget.showScaffold) return body;

    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(title: AppStrings.service.tr),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryColor,
        onPressed: _goToAddService,
        icon: const Icon(Icons.add, color: Colors.white),
        label: CustomText(
          AppStrings.service.tr,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: body,
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (serviceController.isServiceDataFirstLoading.isTrue) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if(serviceController.serviceDataList.isNotEmpty){
        return Column(
          children: [
            Expanded(
              child: (widget.isShowGrid)
                  ?  LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = 2;
            final crossSpacing = 10.0;
            final mainSpacing = 10.0;

            // final itemWidth =
            //     (constraints.maxWidth - ((crossAxisCount - 1) * crossSpacing)) /
            //         crossAxisCount;

            final totalHorizontalSpacing = (crossAxisCount - 1) * crossSpacing;
            final itemWidth = (constraints.maxWidth - totalHorizontalSpacing) / crossAxisCount;

            final approximateItemHeight = SizeConfig.size280;

            final childAspectRatio = itemWidth / approximateItemHeight;

            return GridView.builder(
              // crossAxisCount: crossAxisCount,
              // crossAxisSpacing: crossSpacing,
              // mainAxisSpacing: mainSpacing,
              // controller: storesScrollController,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: crossSpacing,
                mainAxisSpacing: mainSpacing,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: serviceController.serviceDataList.length,
              padding: EdgeInsets.only(
                  left: SizeConfig.size8,
                  right: SizeConfig.size8,
                  top: SizeConfig.size15,
                  bottom: kBottomNavigationBarHeight + 40),
              itemBuilder: (context, index) {
                GetServiceModel? serviceData = serviceController.serviceDataList[index];
                Discounts? maxDiscount;
                if ((serviceData.discounts?.length ?? 0) > 0)
                  maxDiscount = serviceData.discounts
                      ?.reduce((a, b) => (a.amountOff ?? 0) > (b.amountOff ?? 0) ? a : b);

                return InkWell(
                  onTap: () {
                    Get.to(()=>
                        ServiceDetailsScreen(
                          service: serviceData,
                        ));
                  },
                  child: Container(
                    width: itemWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: SizeConfig.size150,
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CustomImageSlideshow(
                                  isLoading: false,
                                  width: double.infinity,
                                  height: SizeConfig.size150,
                                  imagePaths: serviceData.photos ?? [],
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: _buildIconBox(
                                  onTap: () async {
                                    await showCommonDialog(
                                    context: context,
                                    text: AppStrings.areYouSureDelete,
                                    confirmText: AppStrings.delete,
                                    cancelText: AppStrings.cancel,
                                    confirmCallback: () {
                                      serviceController.deleteService(
                                          serviceId: serviceData.id ?? '',
                                          isFromEarnWithBlueEra: false
                                      );
                                    },
                                    cancelCallback: () {
                                      Get.back();
                                    },
                                    );
                                  },
                                  Icon(Icons.more_vert, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: SizeConfig.size10,
                              horizontal: SizeConfig.size8,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title & price
                              CustomText(
                              serviceData.title ?? AppStrings.na,
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                color: AppColors.mainTextColor,
                              ),

                              SizedBox(height: SizeConfig.size5),

                              // /// Service Description
                              // Container(
                              //   alignment: Alignment.centerLeft,
                              //   child: CustomText(
                              //     serviceData.description,
                              //     fontSize: SizeConfig.small,
                              //     overflow: TextOverflow.ellipsis,
                              //     maxLines: 2,
                              //   ),
                              // ),

                              /// Service price
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CustomText(
                                        "Price: ",
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor
                                    ),

                                    CustomText(
                                        "₹${serviceData.priceRange?.min} - ₹${serviceData.priceRange?.max}",
                                          fontWeight: FontWeight.w700,
                                          fontSize: SizeConfig.medium,
                                          color: AppColors.primaryColor,
                                          fontFamily: AppConstants.OpenSans,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: SizeConfig.size6),
                                      child: CustomText(
                                      (maxDiscount?.amountOff != null)
                                              ? "${maxDiscount?.amountOff.toString()}% ${AppStrings.off.tr}}"
                                              : "0% ${AppStrings.off.tr}",
                                              fontSize: SizeConfig.small,
                                              color: AppColors.secondaryTextColor,
                                              fontWeight: FontWeight.w400,
                                              decoration: TextDecoration.lineThrough,
                                              fontFamily: AppConstants.OpenSans,
                                      ),
                                    ),
                                    SizedBox(width: SizeConfig.size6),
                                    CustomText(
                                        "₹${serviceData.priceRange?.max}",
                                      fontSize: SizeConfig.small,
                                      color: AppColors.greenShade,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: AppConstants.OpenSans,
                                    ),
                                  ],
                                ),
                              ),

                              // /// Service facilities
                              // Padding(
                              //   padding: const EdgeInsets.symmetric(vertical: 10.0),
                              //   child: Column(
                              //     children: [
                              //       CustomText(
                              //         "${serviceData.facilities?.join(',')}",
                              //         fontSize: 14,
                              //         fontWeight: FontWeight.w600,
                              //         color: AppColors.primaryColor,
                              //         overflow: TextOverflow.ellipsis,
                              //         maxLines: 2,
                              //       ),
                              //     ],
                              //   ),
                              // ),

                              SizedBox(height: SizeConfig.size5),

                              if(serviceData.timings?.isNotEmpty ?? false)
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    children: [
                                      CustomText(
                                        "${AppStrings.open.tr} :",
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w400,
                                        overflow: TextOverflow.ellipsis,
                                        color: AppColors.green00,

                                      ),
                                      CustomText(
                                        "${serviceData.timings?[0].start}",
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w400,
                                        overflow: TextOverflow.ellipsis,
                                        color: AppColors.secondaryTextColor,
                                        maxLines: 1,
                                      ),
                                      CustomText(
                                        ' | ',
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      CustomText(
                                        "${AppStrings.close} :",
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w400,
                                        overflow: TextOverflow.ellipsis,
                                        color: AppColors.redB4,
                                        maxLines: 1,
                                      ),
                                      CustomText(
                                        "${serviceData.timings?[0].end}",
                                        fontSize: SizeConfig.small,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.grayText,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        )
                  : ListView.builder(
                controller: scrollController,
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8, vertical: SizeConfig.size10),
                itemCount: serviceController.serviceDataList.length,
                itemBuilder: (context, index) {
                  GetServiceModel? serviceData = serviceController.serviceDataList[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () {
                        Get.to(()=>
                            ServiceDetailsScreen(
                              service: serviceData,
                            ));
                      },
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 160,
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                    topLeft:
                                    Radius.circular(10),
                                    bottomLeft:Radius.circular(10) ),
                                child: CustomImageSlideshow(
                                  isLoading: false,
                                  width: double.infinity,
                                  height: 220,
                                  imagePaths: serviceData.photos ?? [],
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title & price
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: CustomText(
                                            serviceData.title ?? AppStrings.na,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                        IconButton(
                                            onPressed: () async {
                                              await showCommonDialog(
                                                context: context,
                                                text: AppStrings.areYouSureDelete,
                                                confirmText: AppStrings.delete,
                                                cancelText: AppStrings.cancel,
                                                confirmCallback: () {
                                                  serviceController.deleteService(
                                                      serviceId: serviceData.id ?? '',
                                                      isFromEarnWithBlueEra: false
                                                  );
                                                },
                                                cancelCallback: () {
                                                  Get.back();
                                                },
                                              );
                                            }, icon: Icon(
                                          Icons.more_vert, color: Colors.black, size: 20,
                                        ))
                                      ],
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    alignment: Alignment.centerLeft,
                                    child: CustomText(
                                      serviceData.description,
                                      fontSize: SizeConfig.small,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                    child: Column(
                                      children: [
                                        CustomText(
                                          "${serviceData.facilities?.join(',')}",
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryColor,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                        if(serviceData.timings?.isNotEmpty ?? false)
                                          ...[
                                            SizedBox(height: SizeConfig.size8),
                                            Row(
                                              children: [
                                                CustomText(
                                                  "${AppStrings.open.tr} :",
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  overflow: TextOverflow.ellipsis,
                                                  color: AppColors.green39,

                                                ),
                                                CustomText(
                                                  "${serviceData.timings?[0].start}",
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  overflow: TextOverflow.ellipsis,
                                                  color: AppColors.grayText,
                                                  maxLines: 1,
                                                ),
                                                CustomText(
                                                  ' | ',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  color: AppColors.grayText,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                CustomText(
                                                  "${AppStrings.close} :",
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  overflow: TextOverflow.ellipsis,
                                                  color: AppColors.red,
                                                  maxLines: 1,
                                                ),
                                                CustomText(
                                                  "${serviceData.timings?[0].end}",
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  color: AppColors.grayText,
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ],
                                            ),
                                          ]
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: SizeConfig.size5),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (serviceController.isServiceDataLoadingMore.value)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      }
      else{
        return Center(
          child: Padding(
            padding: EdgeInsets.all(SizeConfig.size20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.miscellaneous_services_outlined,
                    size: 64, color: AppColors.greyAF),
                SizedBox(height: SizeConfig.size12),
                CustomText(
                  AppStrings.noServices.tr,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size16),
                ElevatedButton.icon(
                  onPressed: _goToAddService,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: CustomText(
                    "Add Service",
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.size20,
                        vertical: SizeConfig.size12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

    });
  }

  Widget _buildIconBox(Widget child, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 25,
        width: 25,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          boxShadow: [AppShadows.textFieldShadow],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

}

