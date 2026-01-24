import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/chat/view/orders_chat/widget/select_address_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_icon_assets.dart';
import '../../../../../core/constants/regular_expression.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/commom_textfield.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../../../widgets/local_assets.dart';
import '../../../auth/controller/order_controllar.dart';
import '../../../auth/model/GetListOfMessageData.dart';

class OrderCommonWidget {

  static Future<void> showEnterOrderValueDialog(
      BuildContext context, String businessId, Messages message) async {
    final orderController = Get.put(OrderNowController());
    if(message.metadata?.price!=null){
      orderController.orderValueController.text=message.metadata?.price??'';
    }
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool hasOrderValue =
                orderController.orderValueController.text.trim().isNotEmpty;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonTextField(
                        textEditController: orderController.orderValueController,
                        keyBoardType: TextInputType.number,
                        title: AppStrings.totalOrderValue,
                        hintText: "E.g  ₹400",
                        regularExpression:
                        RegularExpressionUtils.alphanumericPattern,
                        isValidate: true,
                        onChange: (value) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: SizeConfig.size25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                AppColors.grayText.withOpacity(0.04),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const CustomText(
                                AppStrings.cancel,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          SizedBox(width: SizeConfig.size12),

                          // Next
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasOrderValue
                                    ? AppColors.primaryColor
                                    : AppColors.grayText.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: hasOrderValue
                                  ? () {
                                Navigator.pop(context);
                                OrderCommonWidget.showPickupOptionDialog(
                                    context, businessId, message,);
                              }
                                  : null,
                              child: const CustomText(
                                AppStrings.next,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  static Future<void> showPickupOptionDialog(
      BuildContext context, String businessId, Messages message) async {
    int selectedIndex = -1;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomText(
                        AppStrings.choosePickupOption,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: SizeConfig.size12),
                      GestureDetector(
                        onTap: () => setState(() => selectedIndex = 0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: selectedIndex == 0
                                ? AppColors.primaryColor
                                : AppColors.white,
                            border: Border.all(
                              color: selectedIndex == 0
                                  ? AppColors.primaryColor
                                  : AppColors.grayText.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              LocalAssets(imagePath: AppIconAssets.self_pickup),
                              CustomText(
                                "    ${AppStrings.selfPickup.tr}",
                                fontSize: 16,
                                color: selectedIndex == 0
                                    ? AppColors.white
                                    : AppColors.grayText,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: SizeConfig.size12),

                      GestureDetector(
                        onTap: () => setState(() => selectedIndex = 1),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: selectedIndex == 1
                                ? AppColors.primaryColor
                                : AppColors.white,
                            border: Border.all(
                              color: selectedIndex == 1
                                  ? AppColors.primaryColor
                                  : AppColors.grayText.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              LocalAssets(
                                  imagePath: AppIconAssets.pickup_by_rider),
                              CustomText(
                                "    ${AppStrings.bookRider.tr}",
                                fontSize: 16,
                                color: selectedIndex == 1
                                    ? AppColors.white
                                    : AppColors.grayText,
                              ),
                              CustomText(
                                "  (${AppStrings.paid.tr})",
                                fontSize: 12,
                                color: selectedIndex == 1
                                    ? AppColors.white
                                    : AppColors.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: SizeConfig.size25),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Cancel
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                AppColors.grayText.withOpacity(0.04),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const CustomText(
                                AppStrings.cancel,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          SizedBox(width: SizeConfig.size12),

                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedIndex != -1
                                    ? AppColors.primaryColor
                                    : AppColors.grayText.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: selectedIndex != -1
                                  ? () {
                                if (selectedIndex == 1) {
                                  Navigator.pop(context);
                                  Get.to(()=>AddressListScreen(
                                    message: message,
                                    businessId: businessId,
                                  ));

                                } else {
                                  final orderController = Get.put(OrderNowController());
                                  orderController.createSelfPickupOrder(message.id, message.seller?.id, message.conversationId,);
                                  Navigator.pop(context);
                                }
                              }
                                  : null,
                              child: const CustomText(
                                AppStrings.next,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
