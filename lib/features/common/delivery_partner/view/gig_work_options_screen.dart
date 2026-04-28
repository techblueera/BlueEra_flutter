import 'dart:developer';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_employee_screen.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/bottom_nav_hide_on_scroll.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

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
        userProfessionGlobal == AUTO_TAXI ||
        userProfessionGlobal == CAR_TAXI_DRIVER) {
      body = RiderServiceScreen(fromBottomNavBar: widget.fromBottomNavBar);
    } else {
      body = CabAndTransportPartner(fromBottomNavBar: widget.fromBottomNavBar);
    }

    return Scaffold(
      appBar: CommonBackAppBar(
        showElevation: 0,
        isDrawerMenu: true,
        isLeading: false,
        isMore: true,
        isProfile: false,
        isNotification: !isGuestUser(),
        bellIconNotEmpty: true,
        isGuestLogout: isGuestUser(),
        onNotificationTap: () {
          Navigator.pushNamed(
            context,
            RouteHelper.getNotificationScreenRoute(),
          );
        },
      ),
      // BottomNavHideOnScroll listens to scroll notifications bubbling
      // up from the inner Scaffolds (RiderServiceScreen /
      // CabAndTransportPartner) and toggles the bottom nav visibility
      // accordingly. The outer AppBar stays fixed because it lives
      // outside the inner screens' NestedScrollView headers — moving it
      // into those headers would require editing those child screens.
      body: BottomNavHideOnScroll(child: body),
    );
  }


}
