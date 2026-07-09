import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

/// Inquiry tab — mirrors `SchoolInquiryTabV2` / `HospitalInquiryTabV2`:
/// the shared [OrderActionsCarousel] sits on top, followed by the incoming
/// inquiries list.
///
/// Shows incoming inquiries only — i.e. business chats whose latest message
/// was authored by *someone else* (`excludeSenderId: userId`), so the business
/// owner sees who reached out to them.
///
/// The carousel's third (catalog) card is wired to the Services tab via
/// [onAddServices], supplied by the host so it can drive its (setState-based)
/// tab switch.
///
/// `isInParentScroll: true` makes `BusinessChatsList` drop its internal
/// `Expanded`/scroll and shrink-wrap, so the parent `SingleChildScrollView`
/// owns the scroll — no fixed height needed (mirrors grocery's Order tab).
class OtherInquiryTabV2 extends StatelessWidget {
  const OtherInquiryTabV2({super.key, required this.onAddServices});

  /// Switches the host screen to the Services tab.
  final VoidCallback onAddServices;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size10),
        OrderActionsCarousel(
          onAddCatalog: onAddServices,
          catalogIcon: Icons.design_services_rounded,
          catalogTitle: AppStrings.addService.tr,
          catalogSubtitle: 'List the services you offer',
        ),
        SizedBox(height: SizeConfig.size16),
        BusinessChatsList(
          excludeSenderId: userId,
          isInParentScroll: true,
          listTitle: 'Inquiry',
        ),
      ],
    );
  }
}
