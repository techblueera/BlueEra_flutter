import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_controller.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/view/grocery_home_screen_v2.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:flutter/material.dart';

class GroceryScreen extends StatefulWidget {
  final bool? fromBottomNavBar;

  const GroceryScreen({super.key, this.fromBottomNavBar});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  @override
  void dispose() {
    deleteIfRegistered<GroceryController>();
    deleteIfRegistered<GrocerySelfPickupConsumerController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavHideOnScroll(
      child: GroceryHomeScreenV2(businessId: userId),
    );
  }
}
