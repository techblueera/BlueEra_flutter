import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/food/view/food_details_view_screen.dart';
import 'package:BlueEra/features/common/food/view/widget/km_away_text_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../model/get_food_details_model.dart';

class FoodCardBusiness extends StatefulWidget {
  final GetFoodDetailsModel serviceData;
  final bool isGridView;
  final bool isShowChat;
  final bool isShowEnquiry;
  final bool isShowKM;
  final bool isFromChatCard;
  final String? conversationId;
  final String? businessId;
  final bool isShowBusinessInfo;
  final BusinessProfileDetails? businessData;
  final double? width;

  const FoodCardBusiness({
    Key? key,
    required this.serviceData,
    this.isGridView = false,
    this.isShowChat = true,
    this.isShowKM = false,
    this.isFromChatCard= false,
    this.isShowBusinessInfo = false,
    this.businessData,
    this.width,  this.isShowEnquiry=false, this.conversationId, this.businessId,
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
        width: widget.width,
        // margin: EdgeInsets.only(right:widget.isFromChatCard? 0:20),
        // width: widget.isFromChatCard?SizeConfig.screenWidth*0.68:MediaQuery.of(context).size.width * 0.45,
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
                serviceData?.title ?? AppStrings.na,
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
                            color: (serviceData?.vegType == "veg")
                                ? Colors.green
                                : Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: CustomText("${serviceData?.vegType ?? AppStrings.veg}",
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
                        serviceData?.subCategory ?? AppStrings.na,
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
                "${AppStrings.energyPrefix.tr}${serviceData?.nutritionalSummaryPer100g?.caloriesKcal ?? AppStrings.na.tr} ${AppStrings.Cal100gm.tr}",
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
                      "${AppStrings.pricePrefix.tr}₹ ${serviceData?.singlePrice ?? "0"}",
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
                      "${AppStrings.pricePrefix.tr}₹ ${priceText}",
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
            if (widget.isShowEnquiry)
              InkWell(
                onTap: () async {
                  if (isGuestUser()) {
                    createProfileScreen();

                    return;
                  }
                  final chatViewController = Get.find<ChatViewController>();

                  List<Map<String, String>> urlList =
                      serviceData?.photos?.map((e) => {"url": e}).toList()??[];
                  Map<String, dynamic> data = {
                    ApiKeys.food_id:"${serviceData?.id}",

                    ApiKeys.price: serviceData?.priceType == "single"?
                    "${serviceData?.singlePrice}":"$priceText",
                    ApiKeys.discount: "${serviceData?.discounts}",
                    if ((widget.conversationId ==
                        '' ||
                        widget.conversationId==
                            null))
                      ApiKeys.other_user_id: widget.businessId
                    else
                      ApiKeys.conversation_id: widget.conversationId,
                    ApiKeys.message:
                    "${serviceData?.title}",
                    ApiKeys.message_type : AppConstants.food,
                    ApiKeys.title: serviceData?.title,
                    ApiKeys.veg_type :serviceData?.vegType,
                    ApiKeys.sub_category : serviceData?.subCategory,
                    ApiKeys.calories: serviceData?.nutritionalSummaryPer100g?.caloriesKcal,
                    ApiKeys.url: urlList,
                  };
                  chatViewController.sendProductMessages(data);
                  chatViewController.changeBusinessInsideTab(0);

                },
                child: Container(
                    width: Get.width,
                    padding: EdgeInsets.all(SizeConfig.size5),

                    margin: EdgeInsets.only(
                        left: SizeConfig.size4,
                        right: SizeConfig.size4,
                        bottom: SizeConfig.size2),
                    child: CustomText(
                      "Enquiry",
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: AppColors.primaryColor,)
                  // border: Border.all(color: AppColors.primaryColor)),
                ),
              ),
            SizedBox(height: SizeConfig.size5),
          ],
        ),
      ),
    );
  }
}
