import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/jobs/create_job_post/create_job.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_order_model.dart';
import 'package:BlueEra/features/me/grocery/controller/my_grocery_order_controller.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
class GroceryOrderDetailsSheet extends StatelessWidget {
  final String groceryOrderId;
  final List<GroceryItem> groceryItems;

  const GroceryOrderDetailsSheet({
    super.key,
    required this.groceryOrderId,
    required this.groceryItems,
  });

  // --- Static Helper to Show the Sheet ---
  static void show(BuildContext context, {
    required String groceryOrderID,
    required List<GroceryItem> groceryItems}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroceryOrderDetailsSheet(
          groceryOrderId: groceryOrderID,
          groceryItems: groceryItems,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Find the Controller
    final controller = getOrPut(() => MyMedicalOrdersController());

    return CommonDraggableBottomSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      backgroundColor: AppColors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      padding: EdgeInsets.only(
        left: SizeConfig.size12,
        right: SizeConfig.size12,
        top: SizeConfig.size10,
        bottom: kToolbarHeight,
      ),
      builder: (scrollController) {
        return ListView(
          controller: scrollController,
          children: [
            _buildDragHandle(),

            _buildHeader(context),

            const SizedBox(height: 12),

            // Pass controller to list
            _buildReceivedOrdersList(controller),

            // Footer Action
            _buildSubmitFooter(controller, context)
          ],
        );
      },
    );
  }

  // --- 1. Order List Widget ---
  Widget _buildReceivedOrdersList(MyMedicalOrdersController controller) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groceryItems.length,
      padding: EdgeInsets.only(bottom: SizeConfig.size10),
      itemBuilder: (_, index) {
        final item = groceryItems[index];
        return _buildOrderItem(item, controller);
      },
    );
  }

  // --- 2. Single Order Item ---
  Widget _buildOrderItem(GroceryItem groceryItems, MyMedicalOrdersController controller) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      padding: EdgeInsets.all(SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.greyE5),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// Variant Image
          (groceryItems.productVariant?.product?.images != null
              && (groceryItems.productVariant?.product?.images!.isNotEmpty ?? false))
              ? CustomImageSlideshow(
            isLoading: false,
            width: SizeConfig.size50,
            height: SizeConfig.size50,
            imagePaths: [groceryItems.productVariant?.product?.images![0].url ?? ''],
            borderRadius: BorderRadius.circular(6),
          )
              : ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LocalAssets(
              imagePath: AppIconAssets.place_holder_image,
              boxFix: BoxFit.fill,
              width: SizeConfig.size50,
              height: SizeConfig.size50,
            ),
          ),

          SizedBox(width: SizeConfig.size10),

          /// Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  groceryItems.productVariant?.product?.name ?? '',
                  fontWeight: FontWeight.w600,
                  fontSize: SizeConfig.medium,
                  color: AppColors.mainTextColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: SizeConfig.size6),
                Row(
                  children: [
                    CustomText(
                      '${groceryItems.productVariant?.weight ?? ''} ${groceryItems.productVariant?.unit ?? ''}',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    Container(
                      width: 0.5,
                      height: SizeConfig.size12,
                      color: AppColors.secondaryTextColor,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    CustomText(
                      '₹${groceryItems.productVariant?.pricing?[0].sellingPrice}',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    CustomText(
                      '₹${groceryItems.productVariant?.pricing?[0].mrp}',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.secondaryTextColor,
                    ),
                  ],
                )
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size10),

          /// Dashed Border
          DashedBorderContainer(
            borderColor: AppColors.greyE5,
            strokeWidth: 1,
            dashLength: 2,
            child: SizedBox(
              height: SizeConfig.size50,
              width: 1,
            ),
          ),
          SizedBox(width: SizeConfig.size10),

          /// Check Box (Logic Integrated)
          Obx(() {
            // Using logic from controller
            final bool isAdded = controller.isItemSelected(groceryItems.id??'');

            return InkWell(
              onTap: () => controller.toggleSelection(groceryItems),
              child: Container(
                padding: EdgeInsets.all(SizeConfig.size8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blackMite.withValues(alpha: 0.2),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                        color: AppColors.greyE5
                    ),
                    color: isAdded ? AppColors.primaryColor : AppColors.white
                  ),
                  child: Icon(
                    Icons.check,
                    size: SizeConfig.size16,
                    color: isAdded ? AppColors.white : Colors.transparent,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- 3. Footer Action (Submit & Select All) ---
  Widget _buildSubmitFooter(MyMedicalOrdersController controller, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryColor),
      ),
      child: Obx (()=> controller.isGroceryItemAvailabilityLoading.value
          ? Center(
        child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator()),
      )
          : InkWell(
        onTap: () {
          controller.submitCustomerOrderForItemAvailability(
              groceryOrderId: groceryOrderId
          );
        },
        child: Row(
          children: [
            // Toggle All
            Expanded(
              child:  CustomText(
                AppStrings.groceryViewAllItemsReceived.tr,
                fontWeight: FontWeight.w600,
                fontSize: SizeConfig.medium,
                color: AppColors.primaryColor,
              ),
            ),

            SizedBox(width: SizeConfig.size8),

            // Submit Button
            CustomText(
              AppStrings.groceryViewSubmit.tr,
              fontWeight: FontWeight.w600,
              fontSize: SizeConfig.medium,
              color: AppColors.primaryColor,
            )
          ],
        ),
       )
      ),
    );
  }

  // --- 4. Helper Widgets ---
  Widget _buildDragHandle() => Center(
    child: Container(
      width: 50,
      height: 5,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.secondaryTextColor,
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );

  Widget _buildHeader(BuildContext context) => Row(
    children: [
      Expanded(
        child: CustomText(
          AppStrings.groceryViewCustomerOrderDetails.tr,
          fontWeight: FontWeight.w600,
          fontSize: SizeConfig.large,
          color: AppColors.mainTextColor,
        ),
      ),
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
    ],
  );
}