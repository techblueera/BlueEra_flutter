import 'dart:async';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';


class LiveTrachRiderController extends GetxController {
  var liveLat = 0.0.obs;
  var liveLng = 0.0.obs;

  Future<void> fetchStream(String riderId)async{


  }
}