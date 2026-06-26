import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

/// Order tab body for the Grocery dashboard — an "Add Product" action
/// carousel above the business-chat orders list.
class GroceryOrderTab extends StatelessWidget {
  const GroceryOrderTab({
    super.key,
    required this.businessId,
    required this.onAddProduct,
  });

  /// Business whose orders are shown (kept for parity / future filtering).
  final String businessId;

  /// Switches the host screen to the Products tab.
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: SizeConfig.size12),
          child: OrderActionsCarousel(
            onAddCatalog: onAddProduct,
            catalogIcon: Icons.inventory_2_rounded,
            catalogTitle: AppStrings.addProduct.tr,
            catalogSubtitle: 'List items customers can order',
          ),
        ),
        SizedBox(height: SizeConfig.size16),
        BusinessChatsList(
          excludeSenderId: userId,
          isInParentScroll: true,
          listTitle: 'Orders',
        ),
      ],
    );
  }
}
