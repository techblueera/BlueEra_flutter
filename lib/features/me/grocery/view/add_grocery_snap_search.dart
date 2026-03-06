import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_snap_search_response.dart';import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddGrocerySnapSearchScreen extends StatefulWidget {
  const AddGrocerySnapSearchScreen({super.key});

  @override
  State<AddGrocerySnapSearchScreen> createState() => _AddGrocerySnapSearchScreenState();
}

class _AddGrocerySnapSearchScreenState extends State<AddGrocerySnapSearchScreen> {
  final controller = Get.find<GroceryController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(
        title: "Grocery Items",
      ),
      // bottomNavigationBar: _buildBottomAction(),
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

  Widget _buildBulkUploadSection() {
    return CustomFormCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText("Bulk Upload Shop Product Photos", fontWeight: FontWeight.bold),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              double spacing = 8.0;
              double totalHorizontalPadding = (spacing * 3);
              double boxSize = (constraints.maxWidth - totalHorizontalPadding) / 4;

              return Obx(() {
                int totalSlots = controller.grocerySnapSearchPhotos.length;
                int currentImages = controller.grocerySnapSearchImages.length;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: List.generate(totalSlots, (index) {
                    bool hasImage = index < currentImages;

                    return InkWell(
                      onTap: hasImage
                          ? () => controller.removeImageAt(index: index)
                          : () => controller.addImages(),
                      child: Stack(
                        children: [
                          Container(
                            width: boxSize,
                            height: boxSize,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.greyE5
                              ),
                              image: DecorationImage(
                                image: (hasImage
                                    ? FileImage(controller.grocerySnapSearchImages[index])
                                    : AssetImage(controller.grocerySnapSearchPhotos[index])) as ImageProvider,
                                fit: BoxFit.cover,
                                colorFilter: !hasImage
                                    ? ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken)
                                    : null,
                              ),
                            ),
                            child: !hasImage
                                ? const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20)
                                : null,
                          ),
                          if (hasImage)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red.withValues(alpha: 0.8),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
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
      var _groceryFoundProducts= _productSnapSearchData?.foundProducts;
      print('found products-- ${_groceryFoundProducts?.length}');

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
                CustomText("${_productSnapSearchData?.missingCount} Items missing", color: Colors.red, fontWeight: FontWeight.w500),
              ],
            ),
          ),

          if(_groceryFoundProducts?.isEmpty??false)
            EmptyStateWidget(
               message: 'No grocery product found in our system',
            ),


           ListView.builder(
             shrinkWrap: true,
             physics: const NeverScrollableScrollPhysics(),
             itemCount: _groceryFoundProducts!.length,
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

  Widget _buildProductCard(FoundProducts item) {
    // final bool isSelected = controller.selectedGroceries.contains(item);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: CachedNetworkImage(
                  imageUrl: item.productDetails?.images?.first.url ?? '',
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: AppColors.greyE5),
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: LocalAssets(
                      imagePath: AppIconAssets.place_holder_image,
                      boxFix: BoxFit.cover,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(item.productDetails?.name ?? '', fontWeight: FontWeight.bold, fontSize: 14),
                    CustomText(item.productDetails?.brand ?? '', color: Colors.grey, fontSize: 12),
                    const SizedBox(height: 4),
                    CustomText(
                      "${item.productDetails?.category}",
                      color: Colors.blue, fontSize: 11, maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.stop_circle_outlined, color: Colors.green, size: 18),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4)),
                          child: CustomText("${item.variants?[0].weight?.toInt()} ${item.variants?[0].unit}", fontSize: 10),
                        ),
                        const SizedBox(width: 8),
                        CustomText(
                            "₹${item.variants?[0].pricing?[0].sellingPrice}",
                            color: AppColors.mainTextColor,
                            fontWeight: FontWeight.bold
                        ),
                        const SizedBox(width: 4),
                        CustomText(
                            "₹${item.variants?[0].pricing?[0].mrp}",
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.secondaryTextColor,
                            fontSize: 11),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: CustomBtn(
              height: 30,
              width: 80,
              onTap: () {},
              // onTap: () => controller.toggleSelection(groceryProductData),
              // title: isSelected ? 'Added' : 'Add',
              title: 'Add',
              textColor: AppColors.primaryColor,
              bgColor: AppColors.white,
              borderColor: AppColors.primaryColor,
              radius: 10.0,

            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Request For Missing Item", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}