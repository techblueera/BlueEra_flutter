import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart' show getInitials, canGoogleMapOpen;
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/business_service/model/get_service_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final GetServiceModel service;

  const ServiceDetailsScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: CommonBackAppBar(
        title: service.title ?? "Service Details",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Image Slider ---
              if (service.photos != null && service.photos!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomImageSlideshow(
                    isLoading: false,
                    width: double.infinity,
                    height: 220,
                    imagePaths: service.photos ?? [],
                    borderRadius: BorderRadius.zero,
                  ),
                ),

              SizedBox(height: SizeConfig.size20),
              CustomFormCard(
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey,
                      backgroundImage: service.business?.logo != null
                          ? NetworkImage(service.business?.logo ?? "")
                          : null,
                      child: service.business?.logo == null
                          ? CustomText(
                              getInitials(service.business?.businessName),
                              fontSize: SizeConfig.size18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: SizeConfig.size10),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                service.business?.businessName?.capitalizeFirst ??
                                    "NA",
                                fontSize: SizeConfig.large18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.mainTextColor,
                                maxLines: 2,
                              ),
                              CustomText(
                                service.business?.categoryOfBusiness?.name ??
                                    "NA",
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w500,
                                color: AppColors.mainTextColor,
                                maxLines: 1,
                              ),
                            ]),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        Discounts? maxDiscount;
                        if ((service.discounts?.length ?? 0) > 0)
                          maxDiscount = service.discounts
                              ?.reduce((a, b) => (a.amountOff ?? 0) > (b.amountOff ?? 0) ? a : b);

                        final chatViewController = Get.find<ChatViewController>();
                        Map<String, dynamic> detas = {
                          ApiKeys.user_id: service.userId
                        };
                        chatViewController.newVisitContactApiResponse?.value;
                        await chatViewController.checkChatConnection(detas);
                        List<Map<String, String>> urlList = service.photos?.map((e) => {"url": e}).toList()??[];
                        Map<String,dynamic> data={
                          // "food_id": "${item.id}",
                          // "product_id": "string",
                          "service_id": "${service.id}",
                          "price": "${service.priceRange?.min} - ${service.priceRange?.max} per ${service.perUnit ?? ''}",
                          "discount": "${(maxDiscount?.amountOff != null)
                              ? "${maxDiscount?.amountOff.toString()}% Off"
                              : "0% Off"}",
                          if((chatViewController.newVisitContactApiResponse?.value?.data?.conversationId==''||chatViewController.newVisitContactApiResponse?.value?.data?.conversationId==null))
                            ApiKeys.other_user_id: (chatViewController
                                .newVisitContactApiResponse
                                ?.value
                                ?.data
                                ?.otherUserId ??
                                '')
                          else
                            ApiKeys.conversation_id:(chatViewController
                                .newVisitContactApiResponse
                                ?.value
                                ?.data
                                ?.conversationId ??
                                ''),
                          "message": "${service.title}.${service.business?.categoryOfBusiness?.name ?? "N/A"}.${service.business?.businessName ?? "N/A"}",
                          "message_type": "service",
                          "url": urlList,
                        };
                        chatViewController.openAnyOneChatFunction(
                          shareProductParams:data,
                          isWithProductSend: true,
                          profileImage: service.business?.logo,
                          otherUserId: (chatViewController
                                          .newVisitContactApiResponse
                                          ?.value
                                          ?.data
                                          ?.conversationId ??
                                      '') ==
                                  ""
                              ? chatViewController.newVisitContactApiResponse
                                      ?.value?.data?.otherUserId ??
                                  ''
                              : null,
                          businessId: service.business?.id,
                          type: "business",
                          isInitialMessage: (chatViewController
                                          .newVisitContactApiResponse
                                          ?.value
                                          ?.data
                                          ?.conversationId ??
                                      '') ==
                                  ""
                              ? true
                              : false,
                          userId: service.userId,
                          conversationId: (chatViewController
                                  .newVisitContactApiResponse
                                  ?.value
                                  ?.data
                                  ?.conversationId ??
                              ''),
                          contactName: service.business?.businessName,
                          contactNo: "",
                        );
                      },
                      child: Container(
                        // width: Get.width,
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size15,
                            vertical: SizeConfig.size5),
                        margin: EdgeInsets.only(
                            top: SizeConfig.size5,
                            left: SizeConfig.size10,
                            // right: SizeConfig.size5,
                            bottom: SizeConfig.size8),
                        child: CustomText(
                          "Chat",
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: AppColors.primaryColor)),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Title & Price Range ---
              Container(
                width: Get.width,
                margin: EdgeInsets.only(top: SizeConfig.size10),
                padding: EdgeInsets.all(SizeConfig.size15),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondaryTextColor.withValues(alpha: 0.1),
                        spreadRadius: 0.5,
                        blurRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      service.title ?? "",
                      fontSize: SizeConfig.size18,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      children: [
                        Icon(Icons.currency_rupee,
                            color: Colors.green.shade700,
                            size: SizeConfig.size20),
                        CustomText(
                          "${service.priceRange?.min} - ${service.priceRange?.max} per ${service.perUnit ?? ''}",
                          fontSize: SizeConfig.size16,
                          color: Colors.grey.shade700,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: Get.width,
                margin: EdgeInsets.only(top: SizeConfig.size10),
                padding: EdgeInsets.all(SizeConfig.size15),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondaryTextColor.withValues(alpha: 0.1),
                        spreadRadius: 0.5,
                        blurRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Description ---
                    CustomText(
                      "Description",
                      fontSize: SizeConfig.size18,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    CustomText(
                      "      ${service.description ?? " "}",
                      fontSize: SizeConfig.size15,
                      color: Colors.grey.shade800,
                    ),
                  ],
                ),
              ),

              // --- Facilities ---
              if (service.facilities != null && service.facilities!.isNotEmpty)
                Container(
                  width: Get.width,
                  margin: EdgeInsets.only(top: SizeConfig.size10),
                  padding: EdgeInsets.all(SizeConfig.size15),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondaryTextColor.withValues(alpha: 0.1),
                          spreadRadius: 0.5,
                          blurRadius: 1,
                          offset: Offset(0, 1),
                        ),
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "Facilities",
                        fontSize: SizeConfig.size18,
                        fontWeight: FontWeight.w600,
                      ),
                      SizedBox(height: SizeConfig.size10),
                      Wrap(
                        spacing: SizeConfig.size8,
                        runSpacing: SizeConfig.size8,
                        children: service.facilities!
                            .map(
                              (f) => Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.size12,
                                  vertical: SizeConfig.size8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius:
                                      BorderRadius.circular(SizeConfig.size20),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        color: Colors.blue,
                                        size: SizeConfig.size18),
                                    SizedBox(width: SizeConfig.size6),
                                    CustomText(
                                      f,
                                      color: Colors.blue.shade800,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: SizeConfig.size20),

              // --- Business Info ---
              InkWell(
                onTap: (){
                  canGoogleMapOpen(
                      latitude:
                      service.business?.businessLocation?.lat?.toDouble() ??
                          0.0,
                      longitude:
                      service.business?.businessLocation?.lon?.toDouble() ??
                          0.0);
                },
                child: Container(
                  width: Get.width,
                  margin: EdgeInsets.only(top: SizeConfig.size10),
                  padding: EdgeInsets.all(SizeConfig.size15),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondaryTextColor.withValues(alpha: 0.1),
                          spreadRadius: 0.5,
                          blurRadius: 1,
                          offset: Offset(0, 1),
                        ),
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText("Business Location",
                              fontSize: SizeConfig.size18,
                              fontWeight: FontWeight.bold),
                          Icon(Icons.directions,color: AppColors.primaryColor,),

                        ],
                      ),
                      Divider(color: AppColors.secondaryTextColor,thickness: 0.5,),

                      SizedBox(height: SizeConfig.size12),
                      _businessCard(context),


                    ],
                  ),
                ),
              ),

              // --- Timing ---
              if (service.timings != null && service.timings!.isNotEmpty)
                Container(
                  width: Get.width,
                  padding: EdgeInsets.all(SizeConfig.size15),
                  margin: EdgeInsets.only(top: SizeConfig.size10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondaryTextColor.withValues(alpha: 0.1),
                          spreadRadius: 0.5,
                          blurRadius: 1,
                          offset: Offset(0, 1),
                        ),
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "Service Timings",
                        fontSize: SizeConfig.size18,
                        fontWeight: FontWeight.w600,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      ...service.timings!.map(
                        (t) => CustomText(
                          "${t.start} - ${t.end}",
                          fontSize: SizeConfig.size15,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: SizeConfig.size50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _businessCard(BuildContext context) {
    final business = service.business;
    if (business == null) return SizedBox.shrink();

    return Row(
      children: [

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                business.businessName ?? "",
                fontSize: SizeConfig.size16,
                fontWeight: FontWeight.w600,
              ),
              CustomText(
                business.address ?? "",
                color: Colors.grey.shade700,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
