import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/common/bottomNavigationBar/controller/bottom_bar_controller.dart';
import 'package:BlueEra/features/me/others/view/v2/other_home_screen_v2.dart';
import 'package:BlueEra/widgets/business_live_photo_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OthersMain extends StatefulWidget {
  const OthersMain({super.key});

  @override
  State<OthersMain> createState() => _OthersMainState();
}

class _OthersMainState extends State<OthersMain> {
  final _viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Skip when the user isn't on the Me tab — the screen can mount
      // transiently during initial bottom-nav routing (currentIndex
      // starts at 0 → meScreens, then post-frame flips to the intended
      // tab like Discover), and we don't want the sheet popping there.
      if (Get.isRegistered<BottomBarController>() &&
          Get.find<BottomBarController>().currentIndex.value != 0) {
        return;
      }
      showBusinessLivePhotoBottomSheetIfNeeded(
        context: context,
        controller: _viewBusinessDetailsController,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const OtherHomeScreenV2();
  }
}
