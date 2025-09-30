import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/demo-home.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/product_listing/models/product_model.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';

class ProductCardBusiness extends StatefulWidget {
  final ProductData productData;
  final bool isGridView;

  const ProductCardBusiness({
    Key? key,
    required this.productData,
    this.isGridView = false,
  }) : super(key: key);

  @override
  State<ProductCardBusiness> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCardBusiness> {
  int _currentImageIndex = 0;
  final chatViewController = Get.find<ChatViewController>();

  @override
  Widget build(BuildContext context) {
    final product = widget.productData.product;
    if (product == null) return const SizedBox();

    final details = product.details;

    if (details == null) {
      // if (details == null || variants == null || variants.isEmpty) {
      return const SizedBox();
    }

    return Container(
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: CustomImageSlideshow(
                    isLoading: false,
                    width: double.infinity,
                    height: double.infinity,
                    imagePaths: product.details?.media ?? [],
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                if ((product.details?.media?.length ?? 0) > 1)
                  Positioned(
                      top: 8,
                      left: 8,
                      child: _buildIconBox(
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CustomText(
                            product.sellerCalsification?.variants?.length
                                .toString(),
                            color: AppColors.white,
                            fontSize: SizeConfig.medium,
                          ),
                        ),
                      )),
              ],
            ),
          ),

          // Title & price
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SizedBox(height: SizeConfig.size4),

                  CustomText(
                    product.details?.name,
                    fontWeight: FontWeight.w600,
                    fontSize: SizeConfig.small,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // SizedBox(height:SizeConfig.size2),
                  // Price Row
                  if (product.sellerCalsification?.variants?.isNotEmpty ??
                      false) ...[
                    Flexible(
                      child: Row(
                        children: [
                          Flexible(
                            child: CustomText(
                              '₹${product.sellerCalsification?.variants?[0].sellingPrice}',
                              fontWeight: FontWeight.w700,
                              fontSize: SizeConfig.small,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              color: AppColors.mainTextColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: CustomText(
                              '${calculateDiscount(
                                product.sellerCalsification?.variants?[0]
                                        .sellingPrice
                                        .toString() ??
                                    "0",
                                product.sellerCalsification?.variants?[0].mrp
                                        .toString() ??
                                    "0",
                              ).toStringAsFixed(2)}% Off',
                              fontSize: SizeConfig.small11,
                              color: Colors.green[600],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Flexible(
                            child: CustomText(
                              ' ₹${product.sellerCalsification?.variants?[0].mrp}',
                              fontSize: SizeConfig.small11,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.lineThrough,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              final viewBusinessDetailsController = Get.find<ViewBusinessDetailsController>();
              BusinessProfileDetails? businessProfileDetails =
                  viewBusinessDetailsController.visitedBusinessProfileDetails?.data;

              chatViewController.openAnyOneChatFunction(
                profileImage: businessProfileDetails?.logo,
                otherUserId:
                    (viewBusinessDetailsController.conversationId.value == '')
                        ? viewBusinessDetailsController.otherUserId?.value
                        : null,
                businessId: businessProfileDetails?.id,
                type: "business",
                isInitialMessage:
                    (viewBusinessDetailsController.conversationId.value == '')
                        ? true
                        : false,
                userId: businessProfileDetails?.userId,
                conversationId:
                    viewBusinessDetailsController.conversationId.value,
                contactName: businessProfileDetails?.businessName,
                contactNo: businessProfileDetails
                    ?.businessNumber?.officeMobNo?.number
                    .toString(),
              );
            },
            child: Container(
              width: Get.width,
              padding: EdgeInsets.all(SizeConfig.size5),
              margin: EdgeInsets.only(
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
          )
        ],
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
