import 'dart:developer';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../controller/food_upload_controller.dart';
import '../../model/get_food_details_model.dart';

class FoodCardBusiness extends StatefulWidget {
  final GetFoodDetailsModel serviceData;
  final bool isGridView;
  final bool isShowChat;
  final bool isShowKM;
  final bool isShowBusinessInfo;
  final BusinessProfileDetails? businessData;

  const FoodCardBusiness({
    Key? key,
    required this.serviceData,
    this.isGridView = false,
    this.isShowChat = true,
    this.isShowKM = false,
    this.isShowBusinessInfo = false,
    this.businessData,
  }) : super(key: key);

  @override
  State<FoodCardBusiness> createState() => _FoodCardBusinessState();
}

class _FoodCardBusinessState extends State<FoodCardBusiness> {
  final chatViewController = Get.find<ChatViewController>();
  final foodController = Get.put(FoodUploadController());
  GetFoodDetailsModel? serviceData;
  var kmAway;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    serviceData = widget.serviceData;
  }

  @override
  Widget build(BuildContext context) {
    //
    // if (widget.serviceData) {
    //   return const SizedBox();
    // }
    final priceOptions = serviceData?.priceOptions;

    String priceText = "N/A";
    if (priceOptions != null && priceOptions.isNotEmpty) {
      if (priceOptions.length == 1) {
        priceText = "₹${priceOptions.first.price ?? ''}";
      } else {
        final prices = priceOptions.map((e) => e.price ?? 0).toList();
        prices.sort();
        priceText = "₹${prices.first} - ₹${prices.last}";
      }
    }
    if (serviceData?.business?.businessLocation != null &&
        serviceData?.business?.businessLocation?.lat != null &&
        serviceData?.business?.businessLocation?.lon != null) {
      kmAway = calculateDistanceKm(
          LocationService.lat,
          LocationService.lng,
          serviceData?.business?.businessLocation?.lat?.toDouble() ?? 0.0,
          serviceData?.business?.businessLocation?.lon?.toDouble() ?? 0.0);
    }

    return InkWell(
      onTap: ()async {
        
        log("ksdjncksdjncksjdcnsdc ${widget.serviceData.toJson()}");
        Map<String, dynamic> detas = {
          ApiKeys.user_id: widget.serviceData.userId
        };
        bool checkCompleted =
            await chatViewController.checkChatConnection(detas);
        
        if(checkCompleted){
          
         String conversationId = chatViewController
              .newVisitContactApiResponse?.value?.data?.conversationId ??
              '';
          String otherUserId = chatViewController
              .newVisitContactApiResponse?.value?.data?.otherUserId ??
              '';
          log("sldkclskdmlskdcmsdc ${chatViewController
              .newVisitContactApiResponse?.value?.data?.toJson()}");
         Map<String, dynamic> detas = {
           ApiKeys.id: widget.serviceData.id
         };
         foodController.getFoodDetailsFromId(detas, userId: widget.serviceData.id??"");
         chatViewController
             .openAnyOneChatFunction(
           profileImage: chatViewController
               .newVisitContactApiResponse?.value?.data?.sender?.profileImage,
           otherUserId:(conversationId=='')?otherUserId :null,
           businessId: chatViewController
               .newVisitContactApiResponse?.value?.data?.sender?.id,
           type: chatViewController
               .newVisitContactApiResponse?.value?.data?.conversationStatus,
           isInitialMessage: (conversationId=='')?true:false,
           userId: chatViewController
               .newVisitContactApiResponse?.value?.data?.sender?.id,
           conversationId:
           conversationId,
           contactName: chatViewController
               .newVisitContactApiResponse?.value?.data?.sender?.name,
           contactNo: chatViewController
               .newVisitContactApiResponse?.value?.data?.sender?.contact,
         );
        }


      },
      child: Container(
        margin: EdgeInsets.only(right: 20),
        width: MediaQuery.of(context).size.width * 0.45,
        height: 310,
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
          mainAxisSize: MainAxisSize.max,
          children: [
            AspectRatio(
              aspectRatio: 1.1, // square-ish image (adjust if needed)
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                    child: CustomImageSlideshow(
                      isLoading: false,
                      width: double.infinity,
                      height: double.infinity,
                      imagePaths: serviceData?.photos ?? [],
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  // if ((product.details?.media.length ?? 0) > 1)
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size5),

            // Title & price
            Container(
              height: SizeConfig.size20,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: CustomText(
                serviceData?.title ?? "N/A",
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
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
            // Padding(
            //   padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
            //   child: CustomText(
            //     serviceData?.availability ?? "N/A",
            //     fontSize: SizeConfig.small,
            //     fontWeight: FontWeight.w500,
            //     overflow: TextOverflow.ellipsis,
            //     maxLines: 1,
            //   ),
            // ),
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
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: CustomText(
                serviceData?.keyIngredients?.join(",") ?? "N/A",
                fontSize: SizeConfig.small,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            (serviceData?.priceType == "single")
                ? Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                    child: CustomText(
                      "Price : ₹ ${serviceData?.singlePrice ?? "N/A"}",
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      color: Colors.blue,
                    ),
                  )
                : Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                    child: CustomText(
                      "Price : ${priceText}",
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                      color: Colors.blue,
                      maxLines: 1,
                    ),
                  ),
            SizedBox(height: SizeConfig.size5),

            if ((kmAway) != null)
              InkWell(
                onTap: () async {
                  final Uri googleMapUrl = Uri.parse(
                      "https://www.google.com/maps/search/?api=1&query=${serviceData?.business?.businessLocation?.lat?.toDouble() ?? 0.0},${serviceData?.business?.businessLocation?.lon?.toDouble() ?? 0.0}");

                  if (await canLaunchUrl(googleMapUrl)) {
                    await launchUrl(googleMapUrl,
                        mode: LaunchMode.externalApplication);
                  } else {
                    throw "Could not open Google Maps";
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                  child: Row(
                    children: [
                      LocalAssets(
                        imagePath: AppIconAssets.location_new,
                        imgColor: AppColors.primaryColor,
                      ),
                      SizedBox(
                        width: SizeConfig.size5,
                      ),
                      CustomText(
                        "${kmAway.toStringAsFixed(0)} km away from you!",
                        fontSize: SizeConfig.small,
                        maxLines: 1,
                        decoration: TextDecoration.underline,
                        color: AppColors.primaryColor,
                        decorationColor: AppColors.primaryColor,
                        decorationStyle: TextDecorationStyle.solid,
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: SizeConfig.size5),
          ],
        ),
      ),
    );
  }
}
