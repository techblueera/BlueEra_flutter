import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_product_model.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_snap_search_response.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class AddGrocerySnapSearchScreen extends StatefulWidget {
  const AddGrocerySnapSearchScreen({super.key});

  @override
  State<AddGrocerySnapSearchScreen> createState() => _AddGrocerySnapSearchScreenState();
}

class _AddGrocerySnapSearchScreenState extends State<AddGrocerySnapSearchScreen> {
  final controller = getOrPut(() => GroceryController());

  @override
  dispose(){
    deleteIfRegistered<GroceryController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(
        title: "Grocery Items",
      ),
      bottomNavigationBar: _buildBottomAction(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            vertical: SizeConfig.size15,
            horizontal: SizeConfig.size8
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBulkUploadSection(),
              _buildProductList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.all(SizeConfig.size15),
      child: SafeArea(
        child: Obx(() {

          if (controller.productSnapSearchData.value == null) {
            return const SizedBox.shrink();
          }

          final bool canSubmit = controller.canSubmitProducts;
          print('can submit-- $canSubmit');

          final int productCount = controller.selectedProductVariants.keys.length;
          final variantCount = controller.selectedProductVariants.values.fold(0, (sum, list) => sum + list.length);
          final bool loading = controller.isAddGroceryProductsLoading.value;

          return CustomBtn(
            onTap: canSubmit && !loading
                ? () => controller.addGroceryProductNewVariant()
                : null,
            isValidate: canSubmit,
            radius: SizeConfig.size8,
            bgColor: canSubmit ? AppColors.primaryColor : Colors.grey,
            title: 'Publish $productCount Products, $variantCount Variants',
            isLoading: loading,
          );
        }),
      ),
    );
  }

  Widget _buildBulkUploadSection() {
    return CustomFormCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText("Bulk Upload Shop Product Photos", fontWeight: FontWeight.bold),
          const SizedBox(height: 14),
          MasonryGridView.count(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.grocerySnapSearchPhotos.length,
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              return Obx(() {
                bool hasImage = index < controller.grocerySnapSearchImages.length;

                return InkWell(
                  onTap: hasImage
                      ? () =>  navigatePushTo(
                    context,
                    ImageViewScreen(
                      appBarTitle: AppStrings.imageViewer,
                      // imageUrls: [post?.author.profileImage ?? ''],
                      imageUrls: [controller.grocerySnapSearchImages[index].path],
                      initialIndex: 0,
                    ),
                  )
                      : () => controller.addImages(),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          height: SizeConfig.size180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.greyE5),
                            image: DecorationImage(
                              image: (hasImage
                                  ? FileImage(controller.grocerySnapSearchImages[index])
                                  : AssetImage(controller.grocerySnapSearchPhotos[index])) as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      if (hasImage)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => controller.removeImageAt(index: index),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red.withValues(alpha: 0.8),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              });
            },
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: CustomBtn(
              width: 70,
              height: 30,
              title: "Submit",
              textColor: AppColors.primaryColor,
              bgColor: AppColors.white,
              borderColor: AppColors.primaryColor,
              radius: 10.0,
              onTap: () {
                controller.fetchGrocerySnapSearchApi();
              },

            ),
          )
        ],
      ),
    );
  }

  // Widget _buildProductList() {
  //   return Obx(() {
  //
  //     if(controller.grocerySnapSearchResponse.value.status == Status.INITIAL){
  //       return SizedBox();
  //     }
  //
  //     if (controller.grocerySnapSearchResponse.value.status  == Status.LOADING) {
  //       return const Center(child: Padding(
  //         padding: EdgeInsets.all(40.0),
  //         child: CircularProgressIndicator(),
  //       ));
  //     }
  //
  //     var _productSnapSearchData= controller.productSnapSearchData.value;
  //     var _groceryFoundProducts= _productSnapSearchData?.foundProducts;
  //     print('found products-- ${_groceryFoundProducts?.length}');
  //
  //     return Column(
  //       children: [
  //
  //         Padding(
  //           padding: const EdgeInsets.symmetric(
  //               vertical: 10.0
  //           ),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               CustomText(
  //                 "${_productSnapSearchData?.foundCount} Items Found",
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 16,
  //               ),
  //               CustomText("${_productSnapSearchData?.missingCount} Items missing", color: Colors.red, fontWeight: FontWeight.w500),
  //             ],
  //           ),
  //         ),
  //
  //         if(_groceryFoundProducts?.isEmpty??false)
  //           EmptyStateWidget(
  //              message: 'No grocery product found in our system',
  //           ),
  //
  //
  //          ListView.builder(
  //            shrinkWrap: true,
  //            physics: const NeverScrollableScrollPhysics(),
  //            itemCount: _groceryFoundProducts!.length,
  //            itemBuilder: (context, index) {
  //              final product = _groceryFoundProducts[index];
  //              return _buildProductCard(product);
  //            },
  //          )
  //        ,
  //       ],
  //     );
  //   });
  // }

  Widget _buildProductList() {
    return Obx(() {

      if(controller.grocerySnapSearchResponse.value.status == Status.INITIAL){
        return SizedBox();
      }

      if (controller.grocerySnapSearchResponse.value.status  == Status.LOADING) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ));
      }

      var _productSnapSearchData= controller.productSnapSearchData.value;
      var _groceryFoundProducts= _productSnapSearchData?.foundProducts ?? [];
      var _groceryMissingProducts= _productSnapSearchData?.missingProducts ?? [];
      print('found products-- ${_groceryFoundProducts.length}');

      return Column(
        children: [

          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 10.0
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  "${_productSnapSearchData?.foundCount} Items Found",
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                InkWell(
                    onTap: ()=> Get.toNamed(RouteHelper.getMissingGroceryItemsScreenRoute(),
                        arguments: {
                          ApiKeys.controller: controller,
                          ApiKeys.argMissingProducts:  _groceryMissingProducts
                        }
                    ),
                    child: CustomText(
                        "${_productSnapSearchData?.missingCount} Items missing",
                        color: Colors.red,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          if(_groceryFoundProducts.isEmpty)
            EmptyStateWidget(
               message: 'No grocery product found in our system',
            ),


           ListView.builder(
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(),
             itemCount: _groceryFoundProducts.length,
             itemBuilder: (context, index) {
               final product = _groceryFoundProducts[index];
               return _buildProductCard(product);
             },
           )
         ,
        ],
      );
    });
  }

  Widget _buildProductCard(FoundProducts foundProducts){

    GroceryProductData? groceryItem = foundProducts.productDetails;

    if(groceryItem==null) return SizedBox();

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: EdgeInsets.only(
          bottom: SizeConfig.size12
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: EdgeInsets.all(SizeConfig.size10),
            decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10.0)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child:  (groceryItem.images!=null &&  groceryItem.images!.isNotEmpty)
                      ? CachedNetworkImage(
                    imageUrl: groceryItem.images!.first.url??'',
                    fit: BoxFit.contain,
                    // fit: BoxFit.cover,
                    height: SizeConfig.size80,
                    width: SizeConfig.size80,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.cover,
                    ),
                  )
                      : LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.fill,
                      height: SizeConfig.size80,
                      width: SizeConfig.size80
                  ),
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// --- Product Title ---
                      Padding(
                        padding: EdgeInsets.only(left: SizeConfig.size10),
                        child: CustomText(
                          groceryItem.name,
                          fontSize: SizeConfig.medium,
                          color: AppColors.mainTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: SizeConfig.size8),

                      /// --- Variant Column ---
                      Obx(() {
                        final groceryVariants = groceryItem.variants ?? [];

                        return Column(
                          children: List.generate(groceryVariants.length, (variantIndex) {
                            final v = groceryVariants[variantIndex];

                            return Padding(
                              padding: EdgeInsets.zero,
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: controller.isVariantSelected(
                                      groceryItem.sId ?? '',
                                      v.sId ?? '',
                                    ),
                                    onChanged: (_) {
                                      controller.toggleVariant(
                                        groceryItem.sId ?? '',
                                        v,
                                      );
                                    },
                                    checkColor: Colors.white,
                                    activeColor: AppColors.primaryColor,
                                    side: const BorderSide(
                                      color: AppColors.secondaryTextColor,
                                      width: 1.5,
                                    ),
                                  ),

                                  CustomText(
                                    '${v.quantity}',
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.mainTextColor,
                                  ),

                                  const SizedBox(width: 6),

                                  Container(
                                    width: 2.0,
                                    height: SizeConfig.size16,
                                    color: AppColors.greyLite,
                                  ),

                                  const SizedBox(width: 6),

                                  // Safe access for pricing array
                                  CustomText(
                                    "₹${(v.pricing != null && v.pricing!.isNotEmpty) ? v.pricing![0].mrp : '0'}",
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.mainTextColor,
                                  ),

                                  const SizedBox(width: 6),

                                  Container(
                                    width: 2.0,
                                    height: SizeConfig.size16,
                                    color: AppColors.greyLite,
                                  ),

                                  const SizedBox(width: 6),

                                  CustomText(
                                    "Selling- ₹${(v.pricing != null && v.pricing!.isNotEmpty) ? v.pricing![0].sellingPrice : '0'}",
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.mainTextColor,
                                  ),

                                  const Spacer(),

                                  InkWell(
                                    onTap: () {
                                      controller.openEditVariantDialog(
                                        context: context,
                                        title: groceryItem.name ?? 'Edit Variant',
                                        variant: v,
                                      );
                                    },
                                    child: LocalAssets(
                                      imagePath: AppIconAssets.pen_line,
                                      imgColor: AppColors.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        );
                      })

                    ],
                  ),
                ),
              ],
            ),
          ),


        ],
      ),
    );
  }


}