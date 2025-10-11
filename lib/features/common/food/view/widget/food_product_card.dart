import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/food/view/food_details_view_screen.dart';
import 'package:BlueEra/features/common/food/view/widget/km_away_text_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../model/get_food_details_model.dart';

class FoodCardBusiness extends StatefulWidget {
  final GetFoodDetailsModel serviceData;
  final bool isGridView;
  final bool isShowChat;
  final bool isShowKM;
  final bool isFromChatCard;
  final bool isShowBusinessInfo;
  final BusinessProfileDetails? businessData;

  const FoodCardBusiness({
    Key? key,
    required this.serviceData,
    this.isGridView = false,
    this.isShowChat = true,
    this.isShowKM = false,
    this.isFromChatCard= false,
    this.isShowBusinessInfo = false,
    this.businessData,
  }) : super(key: key);

  @override
  State<FoodCardBusiness> createState() => _FoodCardBusinessState();
}

class _FoodCardBusinessState extends State<FoodCardBusiness> {
  final chatViewController = Get.find<ChatViewController>();

  GetFoodDetailsModel? serviceData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    serviceData = widget.serviceData;
  }

  @override
  Widget build(BuildContext context) {
    final priceOptions = serviceData?.priceOptions;

    String priceText = "N/A";
    if (priceOptions != null && priceOptions.isNotEmpty) {
      if (priceOptions.length == 1) {
        priceText = "${priceOptions.first.price ?? ''}";
      } else {
        final prices = priceOptions.map((e) => e.price ?? 0).toList();
        prices.sort();
        priceText = "${prices.first} - ₹${prices.last}";
      }
    }

    return InkWell(
      onTap: () {
        if(widget.isFromChatCard==false){
          Get.to(FoodDetailsViewScreen(
            productPriceFormat:(serviceData?.priceType == "single")?"${serviceData?.singlePrice ?? "0"}": "$priceText",
            data: serviceData ?? GetFoodDetailsModel(),
          ));
        }
      },
      child: Container(
        margin: EdgeInsets.only(right:widget.isFromChatCard? 0:20),
        width: widget.isFromChatCard?SizeConfig.screenWidth*0.68:MediaQuery.of(context).size.width * 0.45,
        // height: 310,
        // responsive width
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: CustomImageSlideshow(
                isLoading: false,
                width: double.infinity,
                height: 170,
                imagePaths: serviceData?.photos ?? [],
                borderRadius: BorderRadius.zero,
              ),
            ),
            SizedBox(height: SizeConfig.size5),

            // Title & price
            Container(
              height: SizeConfig.size50,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: CustomText(
                serviceData?.title ?? "N/A",
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            SizedBox(height: SizeConfig.size5),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: Row(
                children: [
                  (serviceData?.vegType == null)
                      ? SizedBox()
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: (serviceData?.vegType == "veg" ?? false)
                                ? Colors.green
                                : Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: CustomText("${serviceData?.vegType ?? "veg"}",
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                  (serviceData?.vegType == null)
                      ? SizedBox()
                      : const SizedBox(
                          width: 6,
                        ),
                  Row(
                    children: [
                      Icon(
                        Icons.food_bank_outlined,
                        size: 19,
                      ),
                      CustomText(
                        serviceData?.subCategory ?? "N/A",
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w500,
                        color: AppColors.navy,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: CustomText(
                "Energy : ${serviceData?.nutritionalSummaryPer100g?.caloriesKcal ?? "N/A"} Cal/100gm",
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            (serviceData?.priceType == "single")
                ? Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                    child: CustomText(
                      "Price : ₹ ${serviceData?.singlePrice ?? "0"}",
                      fontSize: SizeConfig.small,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      color: AppColors.primaryColor,
                    ),
                  )
                : Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                    child: CustomText(
                      "Price : ₹ ${priceText}",
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                      color: AppColors.primaryColor,
                      maxLines: 1,
                    ),
                  ),
            SizedBox(height: SizeConfig.size5),

            KmAwayTextWidget(
                lat: serviceData?.business?.businessLocation?.lat.toString() ??
                    "",
                long:
                    serviceData?.business?.businessLocation?.lon?.toString() ??
                        ""),

            SizedBox(height: SizeConfig.size5),
          ],
        ),
      ),
    );
  }
}
