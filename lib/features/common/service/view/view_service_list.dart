import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/service/controller/service_controller.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/features/common/service/view/service_details_view_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/view/earn_with_blueera_new_screen.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:flutter/material.dart';
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

  const ViewServiceList({super.key, required this.providerType, this.serviceSubType, this.channelId});

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
      ApiKeys.type: "service",
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
              child: ListView.builder(
                controller: scrollController,
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15, vertical: SizeConfig.size10),
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
                                                "${AppStrings.open} :",
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
        return Center(child: Text(AppStrings.noServices, style: TextStyle(fontSize: 18)));
      }

    });
  }
}

