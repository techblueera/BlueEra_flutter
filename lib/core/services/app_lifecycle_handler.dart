import 'dart:developer';

import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:flutter/material.dart';

class AppLifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    log("Lifecycle state changed → $state");

    if (state == AppLifecycleState.resumed) {
      if (await LocationService().isLocationAvailable()) {
        log("Permission granted after returning from settings.");
        await LocationService.fetchLocation();
      }
    }
  }
}
