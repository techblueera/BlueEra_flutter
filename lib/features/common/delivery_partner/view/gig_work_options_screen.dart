import 'dart:developer';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_service_screen.dart';
import 'package:flutter/material.dart';


class GigWorkOptionsScreen extends StatefulWidget {
  final bool fromBottomNavBar;
  const GigWorkOptionsScreen({super.key, this.fromBottomNavBar = false});

  @override
  State<GigWorkOptionsScreen> createState() => _GigWorkOptionsScreenState();
}

class _GigWorkOptionsScreenState extends State<GigWorkOptionsScreen> {
  final controller = getOrPut(() => EarnServiceController());
  final deliveryPartnerController = getOrPut(() => DeliveryPartnerController());

  @override
  void initState() {
    log('user profession global -- $userProfessionGlobal');
    log('user designation global -- $userDesignationGlobal');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // GigWork is exactly the four rider professions the professions API returns
    // (BIKE_RIDER, CAR_TAXI_DRIVER, GOODS_SUPPLY, AUTO_ERICKSHAW), so every gig
    // worker gets the rider dashboard. The old profession `if` plus its
    // CabAndTransportPartner fallback were dropped: two of its constants
    // ("GOODS_TAXI"/"AUTO_TAXI") never matched the real slugs, so goods and
    // auto drivers were wrongly routed to that fallback.
    //
    // The glassmorphic header now lives inside the child screen's cover
    // section (matches the self-employee / professionals layout), so this
    // wrapper just hosts the body.
    return Scaffold(
      body: RiderServiceScreen(fromBottomNavBar: widget.fromBottomNavBar),
    );
  }
}
