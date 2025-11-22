import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/service/controller/service_controller.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/common/service/view/service_details_view_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/view/earn_with_blueera_new_screen.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';

class ViewServiceList extends StatefulWidget {
  final ProductServiceProviderType providerType;
  final EarnWithBlueEraServiceTypes? serviceSubType;
  final String? channelId;
  final bool isShowGrid;

  const ViewServiceList({super.key, required this.providerType, this.serviceSubType, this.channelId, this.isShowGrid = true});

  @override
  State<ViewServiceList> createState() => _ViewServiceListState();
}

class _ViewServiceListState extends State<ViewServiceList> {
  ServiceController serviceController = Get.put(ServiceController());
  final ScrollController scrollController = ScrollController();
  late Map<String, dynamic> queryParams;
  late bool isFromEarnWithBlueEra;

  @override
  void initState() {
    super.initState();
    _initQueryAndFetch();
    scrollController.addListener(_scrollListener);
  }

  /// Refactored to reuse between initState & didUpdateWidget
  void _initQueryAndFetch() {
    isFromEarnWithBlueEra =
        widget.providerType == ProductServiceProviderType.user;

    queryParams = {
      ApiKeys.all: false,
      ApiKeys.type: AppConstants.service,
      ApiKeys.providerType: widget.providerType.title,
    };

    if (isFromEarnWithBlueEra) {
      queryParams[ApiKeys.subType] = widget.serviceSubType?.label;
    }

    if (widget.channelId != null) {
      queryParams[ApiKeys.channelId] = widget.channelId;
    }

    serviceController.getServices(
      queryParams,
      isFromEarnWithBlueEra: isFromEarnWithBlueEra,
    );
  }

  /// Detects changes to serviceSubType or providerType and refreshes data
  @override
  void didUpdateWidget(covariant ViewServiceList oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool shouldRefetch =
        oldWidget.serviceSubType != widget.serviceSubType ||
            oldWidget.providerType != widget.providerType ||
            oldWidget.channelId != widget.channelId;

    if (shouldRefetch) {
      _initQueryAndFetch();
    }
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      serviceController.getServices(
          queryParams,
          isFromEarnWithBlueEra: isFromEarnWithBlueEra,
          isLoadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Obx(() {
      if (serviceController.isServiceDataFirstLoading.isTrue) {
        const Center(
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

            final approximateItemHeight = SizeConfig.size240;

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
                                          isFromEarnWithBlueEra: isFromEarnWithBlueEra
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
                                                      isFromEarnWithBlueEra: isFromEarnWithBlueEra
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
        return Center(child: CustomText(AppStrings.noServices, fontSize: 18));
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

