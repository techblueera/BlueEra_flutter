import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/map/view/location_service.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_product_model.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductCardBusiness extends StatefulWidget {
  final GetProductData productData;
  final bool isGridView;
  final bool isShowChat;
  final bool isShowKM;
  final bool isShowBusinessInfo;
  final BusinessProfileDetails? businessData;

  const ProductCardBusiness({
    Key? key,
    required this.productData,
    this.isGridView = false,
    this.isShowChat = true,
    this.isShowKM = false,
    this.isShowBusinessInfo = false,
    this.businessData,
  }) : super(key: key);

  @override
  State<ProductCardBusiness> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCardBusiness> {
  final chatViewController = Get.find<ChatViewController>();

  var kmAway;

  @override
  Widget build(BuildContext context) {
    final product = widget.productData.product;
    int discountProduct = calculateDiscount(
      product.sellerClassification?.variants[0].sellingPrice.toString() ?? "0",
      product.sellerClassification?.variants[0].mrp.toString() ?? "0",
    ).toInt();
    if (widget.isShowKM) {
      kmAway = calculateDistanceKm(
          LocationService.lat,
          LocationService.lng,
          product.sellerClassification?.businessLocation?.latitude ?? 0.0,
          product.sellerClassification?.businessLocation?.longitude ?? 0.0);
    }

    final details = product.details;

    if (details == null) {
      return const SizedBox();
    }

    return InkWell(
      onTap: () {
        Get.toNamed(
          RouteHelper.getProductPreviewScreenProductRoute(),
          arguments: {
            ApiKeys.argProductData: widget.productData,
            "isShowBusinessInfo": widget.isShowBusinessInfo,
          },
        );
      },
      child: Container(
        margin: EdgeInsets.only(right: 20),
        width: MediaQuery.of(context).size.width * 0.45,
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
                      imagePaths: product.details?.media ?? [],
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  // if ((product.details?.media.length ?? 0) > 1)
                  Positioned(
                      top: 8,
                      left: 8,
                      child: _buildIconBox(
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CustomText(
                            product.sellerClassification?.variants.length
                                .toString(),
                            color: AppColors.white,
                            fontSize: SizeConfig.medium,
                          ),
                        ),
                      )),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size5),

            // Title & price
            Container(
              height: SizeConfig.size40,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: CustomText(
                product.details?.name,
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            SizedBox(height: SizeConfig.size5),
            // Price Row
            if ((product.sellerClassification?.variants.isNotEmpty ??
                false)) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
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
                          fontSize: SizeConfig.small11,
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.lineThrough,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Flexible(
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(30)),
                          child: CustomText(
                            '${discountProduct}% Off',
                            fontSize: SizeConfig.size10,
                            color: Colors.white,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size5),
            ],

            if (widget.isShowKM && kmAway > 0)
              InkWell(
                onTap: () async {
                  final Uri googleMapUrl = Uri.parse(
                      "https://www.google.com/maps/search/?api=1&query=${widget.productData.product.sellerClassification?.businessLocation?.latitude},${widget.productData.product.sellerClassification?.businessLocation?.longitude}");

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
            if (widget.isShowChat)
              InkWell(
                onTap: () async {
                  final chatViewController = Get.find<ChatViewController>();
                  Map<String, dynamic> detas = {
                    ApiKeys.user_id: widget.businessData?.userId
                  };
                  chatViewController.newVisitContactApiResponse?.value;
                  await chatViewController.checkChatConnection(detas);

                  chatViewController.openAnyOneChatFunction(
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
                      top: SizeConfig.size5,
                      left: SizeConfig.size10,
                      right: SizeConfig.size10,
                      bottom: SizeConfig.size8),
                  child: CustomText(
                    "Chat",
                    fontWeight: FontWeight.bold,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryColor)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _buildIconBox(Widget child) {
  return Container(
    height: 25,
    width: 25,
    decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        boxShadow: [AppShadows.textFieldShadow]),
    alignment: Alignment.center,
    child: child,
  );
}
