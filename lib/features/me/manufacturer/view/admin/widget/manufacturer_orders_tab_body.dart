import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

/// Order tab body for the Manufacturer admin screen — the shared
/// [OrderActionsCarousel] (which builds its own contribution card internally)
/// followed by the incoming orders list (same widget the Connect screen
/// renders under its Orders tab).
///
class ManufacturerOrdersTabBody extends StatelessWidget {
  const ManufacturerOrdersTabBody({super.key, required this.onAddProducts});

  /// Switches the host screen's TabController to the Products tab.
  final VoidCallback onAddProducts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size10),
        Padding(
          padding: EdgeInsets.only(right: SizeConfig.size12),
          child: OrderActionsCarousel(
            onAddCatalog: onAddProducts,
            catalogIcon: Icons.inventory_2_rounded,
            catalogTitle: AppStrings.addProduct.tr,
            catalogSubtitle: 'List items customers can order',
          ),
        ),
        SizedBox(height: SizeConfig.size12),
        // Incoming orders — same widget the Connect screen renders under
        // its Orders tab. `excludeSenderId: userId` hides chats whose last
        // message was authored by the merchant, leaving only incoming order
        // pings — same approach as the Grocery screen. `isInParentScroll:
        // true` makes the orders list drop its inner `Expanded` and switch
        // to NeverScrollableScrollPhysics so the surrounding scroll view owns
        // the scroll — no fixed height needed.
        BusinessChatsList(
          excludeSenderId: userId,
          isInParentScroll: true,
          listTitle: 'Orders',
        ),
      ],
    );
  }
}
