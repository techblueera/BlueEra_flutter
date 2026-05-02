import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_home_screen_v2.dart';
import 'package:BlueEra/widgets/business_live_photo_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroceryScreen extends StatefulWidget {
  final bool? fromBottomNavBar;

  const GroceryScreen({super.key, this.fromBottomNavBar});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  final _viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();

  @override
  void initState() {
    super.initState();
    // Auto-prompt the live-photos upload sheet on first paint when the
    // business doesn't have any live photos yet — same behaviour the
    // legacy [MyGroceryStoreScreen] used so existing merchants aren't
    // surprised by the missing nudge after the v2 redesign.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showBusinessLivePhotoBottomSheetIfNeeded(
        context: context,
        controller: _viewBusinessDetailsController,
      );
    });
  }

  @override
  void dispose() {
    deleteIfRegistered<GroceryController>();
    deleteIfRegistered<GrocerySelfPickupConsumerController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GroceryHomeScreenV2(businessId: userId);
  }
}
