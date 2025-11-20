import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/service/controller/service_controller.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShareServiceScreen extends StatefulWidget {
  final String serviceId;
  const ShareServiceScreen({super.key, required this.serviceId});

  @override
  State<ShareServiceScreen> createState() => _ShareServiceScreenState();
}

class _ShareServiceScreenState extends State<ShareServiceScreen> {
  final ServiceController controller = Get.put(ServiceController());

  @override
  void initState() {
    controller.fetchSingleServiceDataApi(serviceId: widget.serviceId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        onBackTap: ()=> Get.back(),
        // onBackTap: ()=> _openNextScreen(),
      ),
      body: Obx(()=> controller.isSingleServiceLoading.isTrue
          ? Center(child: CircularProgressIndicator())
          : ServiceCard()
      ),
    );
  }

  Widget ServiceCard(){

    GetServiceModel? singleServiceData = controller.singleServiceData.value;

    return Container(
      color: AppColors.whiteFE,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Images
          InkWell(
            onTap: (){
              if(singleServiceData?.photos?.isEmpty??false){
                return;
              }

              navigatePushTo(
                context,
                ImageViewScreen(
                  appBarTitle: singleServiceData?.title ?? AppStrings.na,
                  subTitle: singleServiceData?.description,
                  imageUrls: singleServiceData!.photos!,
                  initialIndex: 0,
                ),
              );
            },
            child: AspectRatio(
              aspectRatio: 1.2, // square-ish image (adjust if needed)
              child:
              (singleServiceData?.photos?.isNotEmpty??false)
              ? CustomImageSlideshow(
                isLoading: false,
                width: double.infinity,
                height: double.infinity,
                imagePaths: singleServiceData?.photos ?? [],
                borderRadius: BorderRadius.zero,
              ) : LocalAssets(
                imagePath:
                AppIconAssets.place_holder_image,
                boxFix: BoxFit.fill,
              ),
            ),
          ),

          // Product Details
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & price
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child:  CustomText(
                    singleServiceData?.title ?? AppStrings.na,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  alignment: Alignment.centerLeft,
                  child: CustomText(
                    singleServiceData?.description,
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
                        "${singleServiceData?.facilities?.join(',')}",
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      if(singleServiceData?.timings?.isNotEmpty ?? false)
                        ...[
                          SizedBox(height: SizeConfig.size8),
                          Row(
                            children: [
                              CustomText(
                               '${AppStrings.open.tr} : ',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                overflow: TextOverflow.ellipsis,
                                color: AppColors.green39,

                              ),
                              CustomText(
                                "${singleServiceData?.timings?[0].start}",
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
                                "${AppStrings.close} : ",
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                overflow: TextOverflow.ellipsis,
                                color: AppColors.red,
                                maxLines: 1,
                              ),
                              CustomText(
                                "${singleServiceData?.timings?[0].end}",
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
              ],
            ),
          ),
        ],
      ),
    );
  }

}
