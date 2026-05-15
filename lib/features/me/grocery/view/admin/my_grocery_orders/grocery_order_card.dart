import 'dart:developer';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/me/grocery/view/admin/my_grocery_orders/my_grocery_bill_details.dart';
import 'package:BlueEra/features/me/grocery/view/admin/my_grocery_orders/my_grocery_order_details_sheet.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/grocery/model/grocery_order_model.dart';
import 'package:BlueEra/features/me/grocery/controller/my_grocery_order_controller.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GroceryOrderCard extends StatefulWidget {
  final GroceryOrdersModel order;

  const GroceryOrderCard({
    super.key,
    required this.order,
  });

  @override
  State<GroceryOrderCard> createState() => _GroceryOrderCardState();
}

class _GroceryOrderCardState extends State<GroceryOrderCard> {
  final controller = getOrPut(() => MyGroceryOrdersController());
  late GroceryOrdersModel _order;

  @override
  void initState() {
    _order = widget.order;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant GroceryOrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.order != oldWidget.order) {
         log('update');
        _order = widget.order;
    }
  }

  @override
  Widget build(BuildContext context) {

    return CustomFormCard(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      padding: EdgeInsets.all(SizeConfig.size10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPendingOrderHeader(),
          SizedBox(height: SizeConfig.paddingM),
          _buildReceivedOrders(),

           if(_order.isAvailabilityUpdated??false)...[
            SizedBox(height: SizeConfig.paddingM),
            _buildSubmitSection(),
          ]

        ],
      ),
    );
  }

  Widget _buildPendingOrderHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  // 1. Define the Global/Base Style (used for "Order ID - ")
                  style: TextStyle(
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                    color: AppColors.mainTextColor,
                    fontFamily: 'OpenSans', // Make sure to define your font family if not default
                  ),
                  children: [
                    TextSpan(
                      text: AppStrings.groceryViewOrderIdPrefix.tr,
                    ),
                    TextSpan(
                      text: _order.orderId,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: SizeConfig.size8,
            ),
            _buildTimeText()
          ],
        ),
        SizedBox(
          height: SizeConfig.size8,
        ),
        CustomText(
          '${_order.riderName} / ${_order.customerName}',
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w400,
          color: AppColors.mainTextColor,
        )
      ],
    );
  }

  Widget _buildReceivedOrders(){
    return Container(
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: AppColors.greyE5
        ),
        boxShadow: [AppShadows.textFieldShadow]
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              AppStrings.groceryViewItemsOfTotal.trParams({
                'items': '${_order.totalItems}',
                'total': '${_order.totalPrice}',
              }),
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
            ),
          ),
          SizedBox(
            height: SizeConfig.size8,
          ),
          InkWell(
            onTap: () {
              GroceryOrderDetailsSheet.show(
                  context,
                  groceryOrderID: _order.groceryOrderId??'',
                  groceryItems: _order.items??[],
              );
            },
            child: CustomText(
              AppStrings.groceryViewViewAction.tr,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitSection(){
    return Row(
      children: [
        Expanded(
          child: CustomText(
            AppStrings.groceryViewItemMissingCount.trParams({'count': '${_order.missingItemsCount}'}),
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.redB4,
          ),
        ),
        SizedBox(
          height: SizeConfig.size8,
        ),
        InkWell(
          onTap: ()=> GroceryBillDetailsSheet.show(
              context,
              groceryOrderID: _order.groceryOrderId??''),
          child: Container(
            padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size10,
                horizontal: SizeConfig.size8
            ),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                    color: AppColors.primaryColor
                ),
            ),
            child: CustomText(
              AppStrings.groceryViewComplete.tr,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeText() {
    return CustomText(
      _formatTime(_order.createdAt ?? ''),
      fontSize: SizeConfig.extraSmall,
      fontWeight: FontWeight.w400,
      color: AppColors.grey9A,
    );
  }

  String _formatTime(String isoString) {
    final dateTime = DateTime.parse(isoString).toLocal();
    return DateFormat('hh:mm a').format(dateTime);
  }


}

