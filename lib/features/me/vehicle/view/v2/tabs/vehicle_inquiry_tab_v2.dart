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
/// showroom owner sees who reached out to them.
///
/// The carousel's third (catalog) card is wired to the Vehicles tab via
/// [onAddVehicles], supplied by the host so it can drive the TabController.
///
/// `isInParentScroll: true` makes `BusinessChatsList` drop its internal
/// `Expanded`/scroll and shrink-wrap, so the parent `SingleChildScrollView`
/// owns the scroll — no fixed height needed (mirrors grocery's Order tab).
class VehicleInquiryTabV2 extends StatelessWidget {
  const VehicleInquiryTabV2({super.key, required this.onAddVehicles});

  /// Switches the host screen's TabController to the Vehicles tab.
  final VoidCallback onAddVehicles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.size10),
        OrderActionsCarousel(
          onAddCatalog: onAddVehicles,
          catalogIcon: Icons.directions_car_rounded,
          catalogTitle: AppStrings.vehiclesTab.tr,
          catalogSubtitle: AppStrings.manageVehicleListings.tr,
        ),
        SizedBox(height: SizeConfig.size16),
        BusinessChatsList(
          excludeSenderId: userId,
          isInParentScroll: true,
          listTitle: AppStrings.inquiry,
        ),
      ],
    );
  }
}
