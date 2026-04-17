import 'dart:async';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';


import '../stream/rider_response_stream.dart';
class LiveTrachRiderController extends GetxController {
  late Stream<dynamic> _stream;
  StreamSubscription? _subscription;
  var liveLat = 0.0.obs;
  var liveLng = 0.0.obs;
  var rideCompleted = false.obs;

  Future<void> fetchStream(String riderId)async{
    _stream = await riderLiveLocationOrderStream(riderId);

    _subscription = _stream.listen((event) {
      Map<String,dynamic> data=event;

      // Check if the event signals ride completion
      if (data['status'] == 'completed' || data['status'] == 'delivered') {
        rideCompleted.value = true;
        _subscription?.cancel();
        return;
      }

      if (data['location'] != null && data['location']['coordinates'] != null) {
        liveLat.value = data['location']['coordinates'][1];
        liveLng.value = data['location']['coordinates'][0];
      }

    }, onError: (error) {
      print('❌ Stream error: $error');
    }, onDone: () {
      print('ℹ️ Stream closed');
      // Stream closed by server — ride may be completed
      if (!rideCompleted.value) {
        rideCompleted.value = true;
      }
    });

  }

  @override
  void onClose() {
    _subscription?.cancel();
    _subscription = null;
    super.onClose();
  }
}