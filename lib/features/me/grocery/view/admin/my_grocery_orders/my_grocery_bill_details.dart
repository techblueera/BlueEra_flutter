import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/grocery/controller/my_grocery_order_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/dashed_border_container.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroceryBillDetailsSheet extends StatefulWidget {
  final String groceryOrderId;

   GroceryBillDetailsSheet({
    required this.groceryOrderId,
    super.key,
  });


  static void show(BuildContext context, {required String groceryOrderID}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroceryBillDetailsSheet(
        groceryOrderId: groceryOrderID,
      ),
    );
  }

  @override
  State<GroceryBillDetailsSheet> createState() => _GroceryBillDetailsSheetState();
}

class _GroceryBillDetailsSheetState extends State<GroceryBillDetailsSheet> {
  final controller = getOrPut(() => MyGroceryOrdersController());

  @override
  void initState(){
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getCustomerGroceryOrderAvailableItem(groceryOrderId: widget.groceryOrderId);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Obx((){

        if (controller.isBillLoading.value) {
          return Container(
            height: 250, // Fixed height for loader
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }

        var billDetails = controller.groceryAvailableItemModel.value;

        return SingleChildScrollView(
          padding: EdgeInsets.only(
          left: SizeConfig.size12,
          right: SizeConfig.size12,
          top: SizeConfig.size10,
          bottom: SizeConfig.size40,
      ),
        child: Form(
          key: controller.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content height
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _buildDragHandle(),

              _buildHeader(context),

              // SizedBox(height: SizeConfig.size16),

              CustomText(
                  AppStrings.groceryViewItemMissingCount.trParams({'count': '${billDetails?.totalNoOfMissingItems}'}),
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: AppColors.redB4
              ),

              SizedBox(height: SizeConfig.size16),

              // --- 2. Summary Card (Items & MRP) ---
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.greyE5),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                        imagePath: AppIconAssets.cartListIcon,
                        label: AppStrings.groceryViewTotalItems.tr,
                        value: '${billDetails?.totalNoofAvailableItems.toString().padLeft(2, '0')}'
                    ),
                    CommonHorizontalDivider(
                      height: 0.5,
                      color: AppColors.greyE5,
                    ),
                    _buildSummaryRow(
                        imagePath: AppIconAssets.handPriceIcon,
                        label: AppStrings.groceryViewTotalMrp.tr,
                        value: '₹${billDetails?.totalPrice}'
                    ),
                  ],
                ),
              ),

              SizedBox(height: SizeConfig.paddingM),

              // --- 3. Net Payment Input (Blue Dashed/Bordered Box) ---
              DashedBorderContainer(
                borderColor: AppColors.primaryColor,
                strokeWidth: 1,
                dashLength: 2,
                child: Container(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                            style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                            children: [
                              TextSpan(text: "Net Payment From Rider"),
                            ]
                        ),
                      ),
                      SizedBox(height: SizeConfig.paddingM),
                      CommonTextField(
                        textEditController: controller.netPaymentController,
                        keyBoardType: TextInputType.number,
                        hintText: '₹${billDetails?.totalPrice}',
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: SizeConfig.paddingM),

              // --- 4. Payment Mode Selector ---
              CustomText(
                "Payment Mode",
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  _buildPaymentChip(controller, GroceryPaymentMode.cash),
                  const SizedBox(width: 12),
                  _buildPaymentChip(controller, GroceryPaymentMode.upi),
                  const SizedBox(width: 12),
                  _buildPaymentChip(controller, GroceryPaymentMode.pending),
                ],
              ),

              SizedBox(height: SizeConfig.paddingL),

              // --- 5. Submit Button ---
              CustomBtn(
                title: controller.isSubmitOrderToRiderLoading.value
                    ? null
                    : "Submit",
                onTap: () => controller.submitOrderToRider(
                  groceryOrderId: billDetails?.groceryOrderId ?? '',
                  riderOrderId: billDetails?.rideOrderId ?? '',
                ),
                radius: 10.0,
                bgColor: AppColors.primaryColor,
                isLoading: controller.isSubmitOrderToRiderLoading.value,
              ),
            ],
          ),
        ),
      );
      }),
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
          "Bill Details",
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

  // --- Helper: Summary Row ---
  Widget _buildSummaryRow({required String imagePath, required String label, required String value}) {
    return Padding(
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Row(
        children: [
          LocalAssets(imagePath: imagePath),
          const SizedBox(width: 10),
          Expanded(
            child: CustomText(
              label,
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w400,
            ),
          ),
          CustomText(
            value,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ],
      ),
    );
  }

  // --- Helper: Payment Selection Chip ---
  Widget _buildPaymentChip(MyGroceryOrdersController controller, GroceryPaymentMode paymentMode) {
    return Expanded(
      child: Obx(() {
        final isSelected = controller.selectedPaymentMode.value == paymentMode;
        return InkWell(
          onTap: () => controller.selectMode(paymentMode),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.blue : AppColors.greyE5,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: CustomText(
              paymentMode.label,
              fontSize: SizeConfig.medium,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.secondaryTextColor : Colors.grey.shade600,
            ),
          ),
        );
      }),
    );
  }
}