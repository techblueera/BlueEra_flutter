import 'dart:developer';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_service_screen.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:flutter/material.dart';

import '../../cab_and_transport_partner/view/cab_and_transport_partner.dart';


class GigWorkOptionsScreen extends StatefulWidget {
  final bool fromBottomNavBar;
  const GigWorkOptionsScreen({super.key, this.fromBottomNavBar = false});

  @override
  State<GigWorkOptionsScreen> createState() => _GigWorkOptionsScreenState();
}

class _GigWorkOptionsScreenState extends State<GigWorkOptionsScreen>
    with SingleTickerProviderStateMixin, RouteAware {

  final controller = getOrPut(() => EarnServiceController());
  final deliveryPartnerController = getOrPut(() => DeliveryPartnerController());

  @override
  void initState() {
    log('user profession global -- $userProfessionGlobal');
    log('user designation global -- $userDesignationGlobal');
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      RouteHelper.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
  }


  @override
  void dispose() {
    RouteHelper.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (userProfessionGlobal == BIKE_RIDER ||
        userProfessionGlobal == GOODS_TAXI ||
        userProfessionGlobal == AUTO_TAXI) {
      // body = RiderMeScreen(fromBottomNavBar: widget.fromBottomNavBar);
      body = RiderServiceScreen(fromBottomNavBar: widget.fromBottomNavBar);
    } else {
      body = CabAndTransportPartner(fromBottomNavBar: widget.fromBottomNavBar);
    }

    // The glassmorphic header now lives inside each child screen's
    // cover section (matches the self-employee / professionals layout),
    // so this wrapper just hosts the body.
    return Scaffold(
      body: BottomNavHideOnScroll(child: body),
    );
  }
}
