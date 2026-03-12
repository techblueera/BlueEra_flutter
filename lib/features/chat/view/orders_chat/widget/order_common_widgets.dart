import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/chat/view/orders_chat/widget/select_address_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/view/choose_delivery_options_screen.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import '../../../../../core/constants/regular_expression.dart';
import '../../../../../widgets/commom_textfield.dart';
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
    Get.dialog(
      ChoosePickupAndDeliveryOption(businessId:businessId,message: message,),
      barrierDismissible: false,
    );

  }
}

class ChoosePickupAndDeliveryOption extends StatefulWidget {
  const ChoosePickupAndDeliveryOption({super.key, required this.businessId, required this.message});
  final String businessId;
  final Messages message;
  @override
  State<ChoosePickupAndDeliveryOption> createState() => _ChoosePickupAndDeliveryOptionState();
}

class _ChoosePickupAndDeliveryOptionState extends State<ChoosePickupAndDeliveryOption> {
  String _selectedOptionId = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greenShade, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    'Choose Delivery Option',
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                ),
                IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close))
              ],
            ),
            const SizedBox(height: 10),

            // 2. Loop through the list to build options
            ...chooseDeliveryOptions.map((option) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildDeliveryOption(
                id: option['id']!,
                icon: option['icon']!,
                title: option['title']!,
                subtitle: option['subtitle']!,
              ),
            )).toList(),

            const SizedBox(height: 10),

            // Footer (Buttons)
            Align(
              alignment: Alignment.centerRight,
              child: CustomBtn(
                onTap: _selectedOptionId.isNotEmpty
                    ? () {
    if (_selectedOptionId != "SELF") {
    Get.back();
    Get.to(()=>AddressListScreen(
    message: widget.message,
    businessId: widget.businessId,
    ));

    } else {
    final orderController = Get.put(OrderNowController());
    orderController.createSelfPickupOrder(widget.message.id, widget.message.seller?.id, widget.message.conversationId,);
    Get.back();
    }
                }
                    : null,
                title: AppStrings.next,
                height: SizeConfig.size35,
                width: SizeConfig.size80,
                isValidate: _selectedOptionId.isNotEmpty,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryOption({
    required String id,
    required String icon,
    required String title,
    required String subtitle,
  }) {
    bool isSelected = _selectedOptionId == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedOptionId = id;
        });
      },
      borderRadius: BorderRadius.circular(10.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : AppColors.whiteFE,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isSelected ? AppColors.greenShade : AppColors.greyE5,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected ? [AppShadows.textFieldShadow] : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: LocalAssets(imagePath: icon, boxFix: BoxFit.contain),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.mainTextColor : AppColors.secondaryTextColor,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    subtitle,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            ),
            if (isSelected)
              LocalAssets(
                imagePath: AppIconAssets.green_tick_icon,
                width: 20,
                height: 20,
              ),
          ],
        ),
      ),
    );
  }
}
