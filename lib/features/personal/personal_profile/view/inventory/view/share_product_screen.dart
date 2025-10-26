import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/product_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/single_product_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/attribute_two_rows.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShareProductScreen extends StatefulWidget {
  final String productId;
  const ShareProductScreen({super.key, required this.productId});

  @override
  State<ShareProductScreen> createState() => _ShareProductScreenState();
}

class _ShareProductScreenState extends State<ShareProductScreen> {
  final ProductController controller = Get.put(ProductController());

  @override
  void initState() {
    controller.fetchSingleProductDataApi(productId: widget.productId);
    super.initState();
  }

  void _openNextScreen() async {
    final tempLoginType = await SharedPreferenceUtils.getSecureValue(
        SharedPreferenceUtils.accountType);
    accountTypeGlobal = tempLoginType.toString();

    dynamic isLoginStatus = await SharedPreferenceUtils.getSecureValue(
        SharedPreferenceUtils.isUserLogin);
    if (isLoginStatus == null) isLoginStatus = "false";

    if (isLoginStatus == "false") {
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteHelper.getOnboardingSliderScreenRoute(),
            (Route<dynamic> route) => false,
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        onBackTap: ()=> Get.back(),
        // onBackTap: ()=> _openNextScreen(),
      ),
      body: Obx(()=> controller.isSingleProductLoading.isTrue
          ? Center(child: CircularProgressIndicator())
          : ProductCard()
      ),
    );
  }

  Widget ProductCard(){

    SingleProductData? singleProductData = controller.singleProductData.value;

    final variants = singleProductData?.variants ?? [];

    final Map<String, List<dynamic>> uniqueAttributes = {};

    // final firstTwoKeys = <String>[];
    // for (var v in variants) {
    //   for (var key in v.attributes.keys) {
    //     if (!firstTwoKeys.contains(key)) {
    //       firstTwoKeys.add(key);
    //     }
    //     if (firstTwoKeys.length == 2) break;
    //   }
    //   if (firstTwoKeys.length == 2) break;
    // }
    //
    // for (var key in firstTwoKeys) {
    //   uniqueAttributes[key] = [];
    //   for (var v in variants) {
    //     final value = v.attributes[key];
    //     if (value != null) {
    //       if (key == 'color' && value is Map<String, dynamic>) {
    //         final colorMap = {
    //           "color_name": value["color_name"] ?? "",
    //           "color_code": value["color_code"] ?? ""
    //         };
    //         if (!uniqueAttributes[key]!.any((e) =>
    //         e is Map &&
    //             e["color_name"] == colorMap["color_name"] &&
    //             e["color_code"] == colorMap["color_code"])) {
    //           uniqueAttributes[key]!.add(colorMap);
    //         }
    //       } else {
    //         if (!uniqueAttributes[key]!.contains(value)) {
    //           uniqueAttributes[key]!.add(value);
    //         }
    //       }
    //     }
    //   }
    // }

    return GestureDetector(
      // onTap: (){
      //   ProductPreviewArgs productPreviewArgs = mapProductDataToPreviewArgs(product);
      //   Get.toNamed(
      //     RouteHelper.getProductPreviewScreenRoute(),
      //     arguments: {
      //       ApiKeys.isUserCanCreateVariants: false,
      //       ApiKeys.argProductData: productPreviewArgs,
      //     },
      //   );
      //   // ProductPreviewArgs productPreviewArgs = mapOwnProductToPreviewArgs(product);
      //   // Get.toNamed(
      //   //   RouteHelper.getProductPreviewScreenRoute(),
      //   //   arguments: {
      //   //     ApiKeys.argsProductPreview: productPreviewArgs,
      //   //   },
      //   // );
      // },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          color: AppColors.whiteFE,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              AspectRatio(
                aspectRatio: 1.1, // square-ish image (adjust if needed)
                child: Stack(
                  children: [
                    CustomImageSlideshow(
                      isLoading: false,
                      width: double.infinity,
                      height: double.infinity,
                      imagePaths: singleProductData?.media ?? [],
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                ),
              ),

              // Product Details
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    CustomText(
                      singleProductData?.name,
                      fontWeight: FontWeight.w600,
                      fontSize: SizeConfig.extraLarge,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Price Row
                    if (variants.isNotEmpty) ...[
                      Row(
                        children: [
                          CustomText(
                            '₹${singleProductData?.variants[0].sellingPrice}',
                            fontWeight: FontWeight.w700,
                            fontSize: SizeConfig.medium,
                            color: AppColors.mainTextColor,
                          ),
                          const SizedBox(width: 8),
                          CustomText(
                            '${calculateDiscount(
                              singleProductData?.variants[0].sellingPrice.toString() ?? "0",
                              singleProductData?.variants[0].mrp.toString() ?? "0",
                            ).toStringAsFixed(2)}% Off',
                            fontSize: SizeConfig.medium,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w400,
                          ),
                          CustomText(
                            ' ₹${singleProductData?.variants[0].mrp}',
                            fontSize: SizeConfig.medium,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Status
                    Row(
                      children: [
                        Flexible(
                          child: CustomText(
                            singleProductData?.categoryId,
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.medium,
                            color: AppColors.primaryColor,
                            // maxLines: 1,
                            // overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CustomText(
                            "(+${singleProductData?.variants.length.toString()})",
                            fontWeight: FontWeight.w600,
                            fontSize: SizeConfig.medium,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),

                    AttributeRows(attributeMap: uniqueAttributes),

                    const SizedBox(height: 6),


                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
