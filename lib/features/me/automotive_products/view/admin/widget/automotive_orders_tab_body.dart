import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

/// Order tab body for the Automotive Parts admin screen — the contribution
/// actions carousel followed by the incoming orders list (same widget the
/// Connect screen renders).
///
/// [onAddProducts] switches the host screen's TabController to the Products
/// tab.
class AutomotiveOrdersTabBody extends StatelessWidget {
  const AutomotiveOrdersTabBody({super.key, required this.onAddProducts});

  /// Switches the host screen's TabController to the Products tab.
  final VoidCallback onAddProducts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        BusinessChatsList(
          excludeSenderId: userId,
          isInParentScroll: true,
          showDateFilter: true,
        ),
      ],
    );
  }
}
