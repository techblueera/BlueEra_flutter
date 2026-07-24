import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

/// Order tab body for the Food dashboard — an "Add Product" action
/// carousel above the business-chat orders list.
class FoodOrderTab extends StatelessWidget {
  const FoodOrderTab({super.key, required this.onAddProduct});

  /// Switches the host screen to the Products tab.
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size10),
        Padding(
          padding: EdgeInsets.only(right: SizeConfig.size12),
          child: OrderActionsCarousel(
            onAddCatalog: onAddProduct,
            catalogIcon: Icons.inventory_2_rounded,
            catalogTitle: AppStrings.addProduct.tr,
            catalogSubtitle: AppStrings.listItemsCustomersCanOrder.tr,
          ),
        ),
        SizedBox(height: SizeConfig.size12),
        // `excludeSenderId: userId` hides chats whose last message was
        // authored by the merchant; `isInParentScroll: true` makes
        // BusinessChatsList drop its inner `Expanded` and switch to
        // NeverScrollableScrollPhysics so the surrounding CustomScrollView
        // owns the scroll — no fixed height needed.
        BusinessChatsList(
          excludeSenderId: userId,
          isInParentScroll: true,
          listTitle: 'Orders',
        ),
      ],
    );
  }
}
