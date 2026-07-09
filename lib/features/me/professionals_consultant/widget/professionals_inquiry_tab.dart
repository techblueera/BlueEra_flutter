import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

/// Order/Inquiry tab body for the Professionals dashboard — an
/// "Add Service" action carousel above the business-chat inquiry list.
/// Mirrors [SelfEmployeeInquiryTab] so both individual dashboards share
/// the same inquiry-tab treatment.
class ProfessionalsInquiryTab extends StatelessWidget {
  const ProfessionalsInquiryTab({super.key, required this.onAddServices});

  /// Switches the host screen to the Services tab.
  final VoidCallback onAddServices;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          child: OrderActionsCarousel(
            onAddCatalog: onAddServices,
            catalogIcon: Icons.design_services_rounded,
            catalogTitle: AppStrings.addService.tr,
            catalogSubtitle: 'List the services you offer',
          ),
        ),
        SizedBox(height: SizeConfig.size16),
        BusinessChatsList(
          isForwardUI: false,
          excludeSenderId: userId,
          isInParentScroll: true,
          listTitle: 'Inquiry',
        ),
      ],
    );
  }
}
