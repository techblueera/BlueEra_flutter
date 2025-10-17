import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/business_service/controller/service_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../../core/api/apiService/api_keys.dart';
import '../../../../../../core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/business_service/model/get_service_model.dart';
import 'package:BlueEra/features/common/business_service/view/service_details_view_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';

class ViewServiceList extends StatefulWidget {
  final ProductServiceProviderType providerType;
  final String? channelId;
  const ViewServiceList({super.key, required this.providerType, this.channelId});

  @override
  State<ViewServiceList> createState() => _ViewServiceListState();
}

class _ViewServiceListState extends State<ViewServiceList> {
  ServiceController serviceController = Get.put(ServiceController());
  final ScrollController scrollController = ScrollController();
  late Map<String, dynamic> queryParams;

  @override
  void initState() {
    queryParams = {
      ApiKeys.all: false,
      ApiKeys.type: "service",
      ApiKeys.providerType: widget.providerType.title,
    };
    if(widget.channelId!=null) {
      queryParams[ApiKeys.channelId] = widget.channelId;
    }

    serviceController.getServices(queryParams);
    scrollController.addListener(_scrollListener);
    super.initState();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      serviceController.getServices(queryParams, isLoadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (serviceController.isServiceDataFirstLoading.value) {
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
                padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 12),
                itemCount: serviceController.serviceDataList.length,
                itemBuilder: (context, index) {
                  GetServiceModel? serviceData= serviceController.serviceDataList[index];
                  return InkWell(
                    onTap: () {
                      Get.to(ServiceDetailsScreen(
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
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start,
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title & price
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      CustomText(
                                        serviceData.title ?? "N/A",
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: SizeConfig.size6),
                                  Container(
                                    // height: SizeConfig.size20,
                                    alignment: Alignment.centerLeft,
                                    child: CustomText(
                                      serviceData.description,
                                      fontSize: SizeConfig.small,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),

                                  SizedBox(height: SizeConfig.size8),
                                  Container(
                                    // height: SizeConfig.size20,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        CustomText(
                                          "₹${serviceData.priceRange?.min}-${serviceData.priceRange?.max}",
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          overflow: TextOverflow.ellipsis,

                                          maxLines: 2,
                                        ),
                                        CustomText(
                                          "/${serviceData.perUnit}",
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          overflow: TextOverflow.ellipsis,

                                          maxLines: 2,
                                        ),

                                      ],
                                    ),

                                  ),
                                  SizedBox(height: SizeConfig.size8),
                                  CustomText(
                                    "${serviceData.facilities?.join(',')}",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                    overflow: TextOverflow.ellipsis,

                                    maxLines: 2,
                                  ),
                                  SizedBox(height: SizeConfig.size12),
                                  Row(
                                    children: [
                                      CustomText(
                                        "Open :",
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
                                        " Close :",
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        overflow: TextOverflow.ellipsis,
                                        color: AppColors.red,

                                        maxLines: 1,
                                      ), CustomText(
                                        "${serviceData.timings?[0].end}",
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.grayText,
                                        overflow: TextOverflow.ellipsis,

                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: SizeConfig.size5),
                                ],
                              ),
                            ),
                          ),
                        ],
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
      }else{
        return Center(child: Text('No Services', style: TextStyle(fontSize: 18)));
      }

    });
  }
}

