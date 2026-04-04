import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/food/view/widget/km_away_text_widget.dart';
import 'package:BlueEra/features/me/grocery/widget/price_row.dart';
import 'package:BlueEra/features/me/product/model/get_product_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductCardBusiness extends StatefulWidget {
  final GetProductData productData;
  final bool isShowChat;
  final bool isShowEnquiry;
  final bool isShowKM;
  final bool isShowBusinessInfo;
  final String? conversationId;
  final String? businessId;
  final BusinessProfileDetails? businessData;
  final double? width;

  const ProductCardBusiness({
    Key? key,
    required this.productData,
    this.isShowChat = true,
    this.isShowKM = false,
    this.isShowBusinessInfo = false,
    this.businessData,
    this.width, this.isShowEnquiry=false, this.conversationId, this.businessId,
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
            ApiKeys.providerType: ProviderType.business.title
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
                child: PriceRow(
                  sellingPrice: '${AppConstants.rupeeSymbol}${product.sellerClassification?.variants[0].sellingPrice}',
                  mrp: '${AppConstants.rupeeSymbol}${product.sellerClassification?.variants[0].mrp}',
                  discount: '${discountProduct}% ${AppStrings.offCaps.tr}',
                ),
              ),
              // SizedBox(height: SizeConfig.size2),
            ],

            // SizedBox(height: SizeConfig.size10),
            // if (widget.isShowKM)
            //   Container(
            //     padding: EdgeInsets.symmetric(
            //       vertical: SizeConfig.size4,
            //     ), margin: EdgeInsets.symmetric(
            //       horizontal: SizeConfig.size4
            //   ),
            //     decoration: BoxDecoration(
            //         borderRadius: BorderRadius.circular(SizeConfig.size4),
            //         color: AppColors.blueShade.withOpacity(0.1),
            //         border: Border.all(
            //             color: AppColors.blueShade
            //         )
            //     ),
            //     child: KmAwayTextWidget(
            //         isUnderlineShow: false,
            //         lat: widget.productData.product.sellerClassification
            //             ?.businessLocation?.latitude
            //             .toString() ??
            //             "",
            //         long: widget.productData.product.sellerClassification
            //             ?.businessLocation?.longitude
            //             ?.toString() ??
            //             ""),
            //   ),

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

                  Map<String,dynamic>? userDetailsMap= await chatViewController.checkChatConnection(detas);
                  if(userDetailsMap!=null){
                    List<Map<String, String>> urlList =
                        product.details?.media.map((e) => {ApiKeys.url: e}).toList()??[];
                    final conversationId = userDetailsMap[ApiKeys.conversation_id];

                    final hasConversation = conversationId != null &&
                        conversationId.toString().isNotEmpty &&
                        conversationId.toString().toLowerCase() != 'null';
                    Map<String, dynamic> data = {
                      ApiKeys.product_id:"${product.details?.id}",

                      ApiKeys.price: "${product.sellerClassification?.variants[0].sellingPrice}",
                      ApiKeys.discount: "${discountProduct}",
                      if (!hasConversation)
                        ApiKeys.other_user_id: (userDetailsMap[ApiKeys.other_user_id]??'')
                      else
                        ApiKeys.conversation_id: (userDetailsMap[ApiKeys.conversation_id] ?? ''),
                      ApiKeys.message:
                      "${product.details?.name}",
                      ApiKeys.message_type: AppConstants.product,
                      ApiKeys.title: product.details?.name,
                      ApiKeys.mrp :product.sellerClassification?.variants[0].mrp,
                      ApiKeys.url: urlList,
                    };
                    chatViewController.checkChatConnectionAndOpenChat(
                      userId: widget.businessData?.userId ?? '',
                      shareProductParams: data,
                      isWithProductSend: true,
                    );

                  }

                },
                child: Container(
                    width: Get.width,
                    padding: EdgeInsets.all(SizeConfig.size5),

                    margin: EdgeInsets.only(
                        left: SizeConfig.size4,
                        right: SizeConfig.size4,
                        bottom: SizeConfig.size2),
                    child: CustomText(
                      AppStrings.chat,
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
            if (widget.isShowEnquiry)
              InkWell(
                onTap: () async {
                  if (isGuestUser()) {
                    createProfileScreen();

                    return;
                  }
                  final chatViewController = Get.find<ChatViewController>();

                  List<Map<String, String>> urlList =
                      product.details?.media.map((e) => {"url": e}).toList()??[];
                  Map<String, dynamic> data = {
                    ApiKeys.product_id:"${product.details?.id}",

                    ApiKeys.price: "${product.sellerClassification?.variants[0].sellingPrice}",
                    ApiKeys.discount: "${discountProduct}",
                    if ((widget.conversationId ==
                        '' ||
                        widget.conversationId==
                            null))
                      ApiKeys.other_user_id: widget.businessId
                    else
                      ApiKeys.conversation_id: widget.conversationId,
                    ApiKeys.message:
                    "${product.details?.name}",
                    ApiKeys.message_type: AppConstants.product,
                    ApiKeys.title: product.details?.name,
                    ApiKeys.mrp :product.sellerClassification?.variants[0].mrp,
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
            SizedBox(height: SizeConfig.size4,),
          ],
        ),
      ),
    );
  }
}