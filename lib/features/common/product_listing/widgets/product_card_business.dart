import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/food/view/widget/km_away_text_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductCardBusiness extends StatefulWidget {
  final GetProductData productData;
  final bool isShowChat;
  final bool isShowKM;
  final bool isShowBusinessInfo;
  final BusinessProfileDetails? businessData;
  final double? width;

  const ProductCardBusiness({
    Key? key,
    required this.productData,
    this.isShowChat = true,
    this.isShowKM = false,
    this.isShowBusinessInfo = false,
    this.businessData,
    this.width,
  }) : super(key: key);

  @override
  State<ProductCardBusiness> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCardBusiness> {
  final chatViewController = Get.find<ChatViewController>();

  @override
  Widget build(BuildContext context) {
    final product = widget.productData.product;
    int discountProduct = calculateDiscount(
      product.sellerClassification?.variants[0].sellingPrice.toString() ?? "0",
      product.sellerClassification?.variants[0].mrp.toString() ?? "0",
    ).toInt();

    final details = product.details;

    if (details == null) {
      return const SizedBox();
    }

    return InkWell(
      onTap: () {
        Get.toNamed(
          RouteHelper.getStoreProductPreviewScreenProductRoute(),
          arguments: {
            ApiKeys.argProductData: widget.productData,
            // "isShowBusinessInfo": widget.isShowBusinessInfo,
            ApiKeys.id: widget.productData.product.sellerClassification?.owner?.id,
            ApiKeys.providerType: ProductServiceProviderType.business.title
          },
        );
      },
      child: Container(
        // margin: EdgeInsets.only(right: 10),
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.whiteE5
          ),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black12,
          //     blurRadius: 6,
          //     offset: Offset(0, 3),
          //   ),
          // ],
        ),
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,

          children: [
            SizedBox(height: SizeConfig.size2),
            ClipRRect(
              borderRadius:
              BorderRadius.all( Radius.circular(8)),
              child: CustomImageSlideshow(


                isLoading: false,
                width: double.infinity,
                height: SizeConfig.size134,
                imagePaths: product.details?.media ?? [],
                borderRadius: BorderRadius.zero,
              ),
            ),

            SizedBox(height: SizeConfig.size8),
            // Title & price
            Container(
              height: SizeConfig.size40,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
              child: CustomText(
                product.details?.name,
                fontSize: SizeConfig.size14,
                fontWeight: FontWeight.w600,
                overflow: TextOverflow.ellipsis,
                color: AppColors.secondaryTextColor,
                maxLines: 2,

              ),
            ),
            SizedBox(height: SizeConfig.size8),
           // SizedBox(height: SizeConfig.size6),
            // Price Row
            if ((product.sellerClassification?.variants.isNotEmpty ??
                false)) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
                child: Row(
                  children: [
                    Flexible(
                      child: CustomText(
                        '₹${product.sellerClassification?.variants[0].sellingPrice}',
                        fontWeight: FontWeight.w700,
                        fontSize: SizeConfig.small,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                    SizedBox(width: SizeConfig.size5),
                    if (discountProduct > 0) ...[
                      Flexible(
                        child: CustomText(
                          ' ₹${product.sellerClassification?.variants[0].mrp}',
                          fontSize: SizeConfig.small,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.lineThrough,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 6,
                      ),
                      Flexible(
                        child: CustomText(
                          '${discountProduct}% Off',
                          fontSize: SizeConfig.size10,
                          color: AppColors.greenPro,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
             // SizedBox(height: SizeConfig.size2),
            ],
            SizedBox(height: SizeConfig.size10),
            if (widget.isShowKM)
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: SizeConfig.size4,
                ), margin: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size4
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SizeConfig.size4),
                  color: AppColors.blueShade.withOpacity(0.1),
                  border: Border.all(
                    color: AppColors.blueShade
                  )
                ),
                child: KmAwayTextWidget(
                  isUnderlineShow: false,
                    lat: widget.productData.product.sellerClassification
                            ?.businessLocation?.latitude
                            .toString() ??
                        "",
                    long: widget.productData.product.sellerClassification
                            ?.businessLocation?.longitude
                            ?.toString() ??
                        ""),
              ),
             // SizedBox(height: SizeConfig.size2),
            SizedBox(height: SizeConfig.size10),
            if (widget.isShowChat)
              InkWell(
                onTap: () async {
                  if (isGuestUser()) {
                    createProfileScreen();

                    return;
                  }
                  final chatViewController = Get.find<ChatViewController>();
                  Map<String, dynamic> detas = {
                    ApiKeys.user_id: widget.businessData?.userId
                  };
                  chatViewController.newVisitContactApiResponse?.value;
                  await chatViewController.checkChatConnection(detas);
                  List<Map<String, String>> urlList =
                  product.details?.media.map((e) => {"url": e}).toList()??[];
                  Map<String, dynamic> data = {
                    ApiKeys.product_id:"${product.details?.id}",

                    ApiKeys.price: "${product.sellerClassification?.variants[0].sellingPrice}",
                    ApiKeys.discount: "${discountProduct}",
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
                    ApiKeys.message:
                    "${product.details?.name}",
                    ApiKeys.message_type: "product",
                    ApiKeys.title: product.details?.name,
                    ApiKeys.mrp :product.sellerClassification?.variants[0].mrp,
                    ApiKeys.url: urlList,
                  };
                  chatViewController.openAnyOneChatFunction(
                    shareProductParams: data,
                    isWithProductSend: true,
                    profileImage: widget.businessData?.logo,
                    otherUserId: (chatViewController.newVisitContactApiResponse
                        ?.value?.data?.conversationId ??
                        '') ==
                        ""
                        ? chatViewController.newVisitContactApiResponse?.value
                        ?.data?.otherUserId ??
                        ''
                        : null,
                    businessId: widget.businessData?.id,
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
                    userId: widget.businessData?.userId,
                    conversationId: (chatViewController
                        .newVisitContactApiResponse
                        ?.value
                        ?.data
                        ?.conversationId ??
                        ''),
                    contactName: widget.businessData?.businessName,
                    contactNo: widget
                        .businessData?.businessNumber?.officeMobNo?.number
                        .toString(),
                  );

                },
                child: Container(
                  width: Get.width,
                  padding: EdgeInsets.all(SizeConfig.size5),

                  margin: EdgeInsets.only(
                      left: SizeConfig.size4,
                      right: SizeConfig.size4,
                      bottom: SizeConfig.size2),
                  child: CustomText(
                    "Chat",
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
          ],
        ),
      ),
    );
  }
}

