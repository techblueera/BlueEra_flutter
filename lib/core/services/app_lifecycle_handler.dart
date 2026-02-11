import 'dart:developer';

import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import '../../features/common/delivery_partner/view/delivery_partner_orders/on_going_pip_screen.dart';
import '../constants/app_constant.dart';
import '../constants/getx_utils.dart';
import '../constants/shared_preference_utils.dart';

class AppLifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    log("Lifecycle state changed → $state");
    if (userDesignationGlobal == DELIVERY_RIDER) {
      if(state == AppLifecycleState.inactive){
        final controller = getOrPut(() => DeliverPartnerOrdersController());
        if(controller.onGoingOrders.isNotEmpty){
          Get.to(OnGoingPipScreen());
        }
    }

    }
    if (state == AppLifecycleState.resumed) {
      if (await LocationService().isLocationAvailable()) {
        log("Permission granted after returning from settings.");
        await LocationService.fetchLocation();
      }
    }
  }
}
