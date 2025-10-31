import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/get_food_details_model.dart';

class FoodDetailsViewScreen extends StatelessWidget {
  final GetFoodDetailsModel data;
  final String productPriceFormat;

  const FoodDetailsViewScreen(
      {super.key, required this.data, required this.productPriceFormat});

  @override
  Widget build(BuildContext context) {
    final item = data;
    final business = item.business;
    final priceOptions = item.priceOptions;
    final keyIngredients = item.keyIngredients ?? [];
    final nutrition = item.nutritionalSummaryPer100g;
    final photos = item.photos ?? [];

    bool isSelfService = false;
    if(data.serviceProvider?.type?.toLowerCase()
        == ProductServiceProviderType.user.name.toLowerCase() ||
        data.serviceProvider?.type?.toLowerCase() == ProductServiceProviderType.business.name.toLowerCase()){
      isSelfService = data.serviceProvider?.id == userId;
    } else if(data.serviceProvider?.type?.toLowerCase() == ProductServiceProviderType.channel.name.toLowerCase()){
      isSelfService = data.serviceProvider?.id == channelId;
    }

    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Details",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- IMAGE ----
              InkWell(
                onTap: (){
                  navigatePushTo(
                    Get.context!,
                    ImageViewScreen(
                      subTitle: item.title,
                      appBarTitle: 'Food Service',
                      imageUrls: photos,
                      initialIndex: 0,
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomImageSlideshow(
                    isLoading: false,
                    width: double.infinity,
                    height: 220,
                    imagePaths: photos,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size16),
                if(!isSelfService)
              ...[
              if (item.business != null &&
                  item.business?.businessName != null &&
                  business?.userId != null)
                CustomFormCard(
                  margin: EdgeInsets.zero,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey,
                        backgroundImage: item.business?.logo != null
                            ? NetworkImage(item.business?.logo ?? "")
                            : null,
                        child: item.business?.logo == null
                            ? CustomText(
                                getInitials(item.business?.businessName),
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
                                  item.business?.businessName
                                          ?.capitalizeFirst ??
                                      "NA",
                                  fontSize: SizeConfig.large18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mainTextColor,
                                  maxLines: 2,
                                ),
                                CustomText(
                                  item.business?.categoryOfBusiness?.name ??
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
                          if (isGuestUser()) {
                            createProfileScreen();

                            return;
                          }
                          final chatViewController =
                              Get.find<ChatViewController>();
                          Map<String, dynamic> detas = {
                            ApiKeys.user_id: business?.userId
                          };
                          chatViewController.newVisitContactApiResponse?.value;
                          await chatViewController.checkChatConnection(detas);
                          List<Map<String, String>> urlList =
                              photos.map((e) => { ApiKeys.url: e}).toList();
                          Map<String, dynamic> data = {
                           ApiKeys.food_id: "${item.id}",
                            ApiKeys.price: "${productPriceFormat}",
                            ApiKeys.discount : "",
                            if ((chatViewController.newVisitContactApiResponse
                                        ?.value?.data?.conversationId ==
                                    '' ||
                                chatViewController.newVisitContactApiResponse
                                        ?.value?.data?.conversationId ==
                                    null))
                              ApiKeys.other_user_id: (chatViewController
                                      .newVisitContactApiResponse
                                      ?.value
                                      ?.data
                                      ?.otherUserId ??
                                  '')
                            else
                              ApiKeys.conversation_id: (chatViewController
                                      .newVisitContactApiResponse
                                      ?.value
                                      ?.data
                                      ?.conversationId ??
                                  ''),
                            ApiKeys.message :
                                "${item.title}",
                            ApiKeys.message_type : AppConstants.food,
                            ApiKeys.title: item.title,
                            ApiKeys.veg_type :item.vegType,
                            ApiKeys.sub_category : item.subCategory,
                            ApiKeys.calories: item.nutritionalSummaryPer100g?.caloriesKcal,
                            // ApiKeys.variant : "string",
                            // ApiKeys.mrp : "string"
                            ApiKeys.url: urlList,
                          };
                          chatViewController.isChatFromBusinessProfile(true);
                          chatViewController.openAnyOneChatFunction(
                            shareProductParams: data,
                            isWithProductSend: true,
                            profileImage: business?.logo,
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
                            businessId: business?.id,
                            type: AppConstants.chatMsgBusinessType,
                            isInitialMessage: (chatViewController
                                            .newVisitContactApiResponse
                                            ?.value
                                            ?.data
                                            ?.conversationId ??
                                        '') ==
                                    ""
                                ? true
                                : false,
                            userId: business?.userId,
                            conversationId: (chatViewController
                                    .newVisitContactApiResponse
                                    ?.value
                                    ?.data
                                    ?.conversationId ??
                                ''),
                            contactName: business?.businessName,
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
                              border:
                                  Border.all(color: AppColors.primaryColor)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ---- TITLE ----
              Container(
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
                    CustomText(item.title ?? "",
                        fontSize: SizeConfig.size18,
                        fontWeight: FontWeight.bold),

                    SizedBox(height: SizeConfig.size8),

                    // ---- CATEGORY ----
                    Wrap(
                      spacing: 8,
                      children: [
                        if (item.vegType != null)
                          Chip(
                            label: CustomText(
                              item.vegType?.toUpperCase(),
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            backgroundColor: item.vegType == "veg"
                                ? Colors.green
                                : Colors.red,
                            padding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.size8,
                                vertical: SizeConfig.size4),
                          ),
                        _buildChip(item.category, Colors.blue.shade100),
                        _buildChip(item.subCategory, Colors.green.shade100),
                        // _buildChip(item.vegType?.toUpperCase(), ),
                      ],
                    ),

                    SizedBox(height: SizeConfig.size10),

                    // ---- DESCRIPTION ----
                    CustomText("      ${item.description ?? " "}",
                        fontSize: SizeConfig.size15, color: Colors.black87),
                  ],
                ),
              ),

              // ---- PRICE OPTIONS ----
              if (priceOptions?.isNotEmpty ?? false) ...[
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
                      CustomText("Price Options",
                          fontSize: SizeConfig.size18,
                          fontWeight: FontWeight.bold),
                      SizedBox(height: SizeConfig.size8),
                      Column(
                        children: priceOptions?.map((opt) {
                              return Container(
                                width: Get.width,
                                margin: EdgeInsets.only(top: SizeConfig.size10),
                                // padding: EdgeInsets.all(SizeConfig.size15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                      color: AppColors.whiteE5, width: 0.5),
                                ),

                                child: ListTile(
                                  title: CustomText("₹${opt.price}"),
                                  subtitle: CustomText("${opt.label} ml"),
                                  trailing: const Icon(Icons.local_offer,
                                      color: Colors.redAccent),
                                ),
                              );
                            }).toList() ??
                            [],
                      ),
                    ],
                  ),
                ),
              ],

              // ---- INGREDIENTS ----
              if (keyIngredients.isNotEmpty) ...[
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
                      CustomText("Key Ingredients",
                          fontSize: SizeConfig.size18,
                          fontWeight: FontWeight.bold),
                      SizedBox(height: SizeConfig.size8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: keyIngredients
                            .map((e) => _buildChip(e, Colors.blue.shade100))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],

              // ---- NUTRITION ----
              if (nutrition != null) ...[
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
                      CustomText("Nutritional Summary (per 100g)",
                          fontSize: SizeConfig.size18,
                          fontWeight: FontWeight.bold),
                      SizedBox(height: SizeConfig.size8),
                      _nutritionRow("Calories", nutrition.caloriesKcal),
                      _nutritionRow("Protein", nutrition.proteinG),
                      _nutritionRow("Carbs", nutrition.carbsG),
                      _nutritionRow(
                        "Fat",
                        nutrition.fatG,
                      ),
                    ],
                  ),
                ),
              ],
              if (business != null) ...[
                // ---- BUSINESS INFO ----
                InkWell(
                  onTap: () {
                    canGoogleMapOpen(
                        latitude:
                            business.businessLocation?.lat?.toDouble() ?? 0.0,
                        longitude:
                            business.businessLocation?.lon?.toDouble() ?? 0.0);
                  },
                  child: Container(
                    width: Get.width,
                    padding: EdgeInsets.all(SizeConfig.size15),
                    margin: EdgeInsets.only(top: SizeConfig.size10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.secondaryTextColor.withValues(alpha: 0.1),
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
                            Icon(
                              Icons.directions,
                              color: AppColors.primaryColor,
                            ),
                          ],
                        ),
                        Divider(
                          color: AppColors.secondaryTextColor,
                          thickness: 0.5,
                        ),
                        SizedBox(height: SizeConfig.size8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              business.businessName ?? "",
                              fontSize: SizeConfig.size16,
                              fontWeight: FontWeight.bold,
                            ),
                            SizedBox(
                              height: SizeConfig.size5,
                            ),
                            CustomText(business.address ?? ""),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size50),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String? label, Color color) {
    if (label == null || label.isEmpty) return const SizedBox();

    return Chip(
      label: CustomText(label, fontWeight: FontWeight.w500),
      backgroundColor: color,
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8, vertical: SizeConfig.size4),
    );
  }

  Widget _nutritionRow(String name, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(name, fontSize: SizeConfig.size15),
          CustomText(value ?? "-", fontWeight: FontWeight.w600),
        ],
      ),
    );
  }
}
