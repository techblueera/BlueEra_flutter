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
/// was authored by *someone else* (`excludeSenderId: userId`), so the
/// pharmacy owner sees who reached out to them.
///
/// The carousel's third (catalog) card is wired to the Products tab via
/// [onAddProducts], supplied by the host so it can drive the TabController.
///
/// `isInParentScroll: true` makes `BusinessChatsList` drop its internal
/// `Expanded`/scroll and shrink-wrap, so the parent `SingleChildScrollView`
/// owns the scroll — no fixed height needed (mirrors grocery's Order tab).
class MedicalInquiryTabV2 extends StatelessWidget {
  const MedicalInquiryTabV2({super.key, required this.onAddProducts});

  /// Switches the host screen's TabController to the Products tab.
  final VoidCallback onAddProducts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size12),
        OrderActionsCarousel(
          onAddCatalog: onAddProducts,
          catalogIcon: Icons.medication_rounded,
          catalogTitle: AppStrings.addProduct.tr,
          catalogSubtitle: 'List items customers can order',
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
