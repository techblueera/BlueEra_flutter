import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/food/controller/food_upload_controller.dart';
import 'package:BlueEra/features/common/food/model/get_food_details_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShareFoodScreen extends StatefulWidget {
  final String foodServiceId;
  const ShareFoodScreen({super.key, required this.foodServiceId});

  @override
  State<ShareFoodScreen> createState() => _ShareFoodScreenState();
}

class _ShareFoodScreenState extends State<ShareFoodScreen> {
  final FoodUploadController controller = Get.put(FoodUploadController());

  @override
  void initState() {
    controller.fetchSingleFoodDataApi(serviceId: widget.foodServiceId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        onBackTap: ()=> Get.back(),
        // onBackTap: ()=> _openNextScreen(),
      ),
      body: Obx(()=> controller.isSingleFoodServiceLoading.isTrue
          ? Center(child: CircularProgressIndicator())
          : FoodCard()
      ),
    );
  }

  Widget FoodCard(){
    final GetFoodDetailsModel? singleFoodData = controller.singleFoodServiceData.value;

    final priceOptions = singleFoodData?.priceOptions;
    String priceText = AppStrings.na;
    if (priceOptions != null && priceOptions.isNotEmpty) {
      if (priceOptions.length == 1) {
        priceText = "${priceOptions.first.price ?? ''}";
      } else {
        final prices = priceOptions.map((e) => e.price ?? 0).toList();
        prices.sort();
        priceText = "${prices.first} - ₹${prices.last}";
      }
    }

    return Container(
      color: AppColors.whiteFE,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Product Image
          InkWell(
            onTap: (){
              if(singleFoodData?.photos?.isEmpty??false){
                return;
              }

              navigatePushTo(
                context,
                ImageViewScreen(
                  appBarTitle: singleFoodData?.title ?? AppStrings.na,
                  subTitle: singleFoodData?.description,
                  imageUrls: singleFoodData!.photos!,
                  initialIndex: 0,
                ),
              );
            },
            child: AspectRatio(
              aspectRatio: 1.2, // square-ish image (adjust if needed)
              child: Stack(
                children: [
                  (singleFoodData?.photos?.isNotEmpty??false)
                      ? CustomImageSlideshow(
                      isLoading: false,
                      width: double.infinity,
                      height: double.infinity,
                      imagePaths: singleFoodData?.photos ?? [],
                      borderRadius: BorderRadius.zero,
                    ) : LocalAssets(
                        imagePath:
                        AppIconAssets.place_holder_image,
                        boxFix: BoxFit.fill,
                    ),
                ],
              ),
            ),
          ),

          // CONTENT SECTION
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + menu button
                Padding(
                  padding: const EdgeInsets.only(
                    left: 10.0,
                  ),
                  child: CustomText(
                    singleFoodData?.title ?? AppStrings.na,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Veg label + category
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: controller.getFoodTypeColor(singleFoodData?.vegType),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              singleFoodData?.vegType ?? "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            singleFoodData?.category ?? "",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Description
                      Text(
                        singleFoodData?.description ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),

                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: (singleFoodData?.priceType == "single")
                            ? CustomText(
                          "${AppStrings.pricePrefix.tr}₹ ${singleFoodData?.singlePrice ?? "0"}",
                          fontSize: SizeConfig.small,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          color: AppColors.primaryColor,
                        )
                            : CustomText(
                          "${AppStrings.pricePrefix.tr}₹${priceText}",
                          fontWeight: FontWeight.w600,
                          overflow: TextOverflow.ellipsis,
                          color: AppColors.primaryColor,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Discount
                      if (singleFoodData?.discounts != null &&
                          (singleFoodData?.discounts?.isNotEmpty??false))
                        Text(
                          singleFoodData?.discounts?.first,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                      const SizedBox(height: 6),

                      // Add-ons
                      if (
                      singleFoodData!= null &&
                          singleFoodData.addOns != null &&
                          singleFoodData.addOns!.isNotEmpty)
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: singleFoodData.addOns!
                              .map((addon) => InkWell(
                            onTap: () {},
                            child: Text(
                              addon,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ))
                              .toList(),
                        )
                    ],
                  ),
                )

              ],
            ),
          ),
        ],
      ),
    );
  }

}
