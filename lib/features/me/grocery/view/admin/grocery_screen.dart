import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
import 'package:BlueEra/features/me/grocery/view/admin/grocery_home_screen_v2.dart';
import 'package:flutter/material.dart';

class GroceryScreen extends StatefulWidget {
  final bool? fromBottomNavBar;

  const GroceryScreen({super.key, this.fromBottomNavBar});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  // The live-photo sheet used to pop from here, on mount. This screen opens on
  // the PRODUCTS tab, so the first thing a new store saw was a photo request
  // over a screen about stock — asking for something that belongs to, and is
  // shown on, Overview. It now fires when that tab is opened; see
  // [GroceryHomeScreenV2].

  @override
  void dispose() {
    // GroceryController deliberately NOT deleted here.
    //
    // The bottom nav swaps its child rather than stacking the tabs, so leaving
    // Me for Discover / Chat / Social disposes this screen. Tearing the
    // controller down with it threw away the Products tab's lists AND their
    // FetchCache stamp, so every return to Me → Grocery refetched categories +
    // top-selling from scratch, however recently they had loaded. It also
    // raced the post-publish refresh: publishing pops back through here, and a
    // deleted controller refetches into an instance nobody reads.
    //
    // Cost of keeping it: the grocery lists stay in memory for the session.
    // The cache is keyed per store (`grocery|<userId>|<otherStore>`), so
    // opening another store still fetches, and the 5-min TTL forces a refetch
    // once the data is actually stale. Mirrors MedicalScreen.
    deleteIfRegistered<GrocerySelfPickupConsumerController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GroceryHomeScreenV2(businessId: userId);
  }
}
