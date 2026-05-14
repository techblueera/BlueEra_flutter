import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/view/v2/hotel_home_screen_v2.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:flutter/material.dart';

/// Root container for the hotel tab in the Me section. Defers to
/// [HotelHomeScreenV2] for actual content; this widget exists only to:
///
///   * register the controller eagerly (so the v2 screen can `Get.find` it
///     without a dependency on creation order), and
///   * clear the controller's default `isLoading=true` so deeper screens
///     that observe it (e.g. RoomSelectionScreen) don't flash a loader on
///     app open before the first fetch lands.
class HotelMain extends StatefulWidget {
  const HotelMain({super.key});

  @override
  State<HotelMain> createState() => _HotelMainState();
}

class _HotelMainState extends State<HotelMain> {
  final hotelDetailController = getOrPut(() => HotelDetailController());

  @override
  void initState() {
    super.initState();
    // v2 screen gates on `hotelData == null`, not `isLoading`. Reset to
    // false so any nested observer doesn't flash a spinner on entry.
    hotelDetailController.isLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BottomNavHideOnScroll(
          child: HotelHomeScreenV2(),
        ),
      ),
    );
  }
}
