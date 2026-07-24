import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

class SelfEmployeeInquiryTab extends StatelessWidget {
  const SelfEmployeeInquiryTab({super.key, required this.onAddServices});

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
            catalogSubtitle: AppStrings.listTheServicesYouOffer.tr,
          ),
        ),
        SizedBox(height: SizeConfig.size16),
        BusinessChatsList(
          isForwardUI: false,
          excludeSenderId: userId,
          isInParentScroll: true,
          listTitle: AppStrings.inquiry,
        ),
      ],
    );
  }
}
