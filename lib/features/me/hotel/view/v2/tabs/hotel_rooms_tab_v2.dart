import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/widget/hotel_choose_room_card.dart';
import 'package:BlueEra/widgets/order_actions_carousel.dart';
import 'package:flutter/material.dart';

/// Rooms tab — order-actions deck at top, then the shared [HotelChooseRoomCard]
/// which handles room-type chips, the horizontal room list, and the
/// per-card Edit / Delete affordances.
class HotelRoomsTabV2 extends StatelessWidget {
  final HotelDetailController controller;

  const HotelRoomsTabV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8),
          child: OrderActionsCarousel(),
        ),
        SizedBox(height: SizeConfig.size12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
          child: HotelChooseRoomCard(controller: controller),
        ),
        SizedBox(height: kBottomNavigationBarHeight + 10),
      ],
    );
  }
}
