import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';


import '../stream/rider_response_stream.dart';
class LiveTrachRiderController extends GetxController {
  late Stream<dynamic> _stream;
  var liveLat = 0.0.obs;
  var liveLng = 0.0.obs;

  Future<void> fetchStream(String riderId)async{
    _stream = await riderLiveLocationOrderStream(riderId);

     _stream.listen((event) {
      Map<String,dynamic> data=event;

      // LocationDataRider location=LocationDataRider.fromJson(data['location']);
      liveLat.value = data['location']['coordinates'][1];
      liveLng.value = data['location']['coordinates'][0];

    }, onError: (error) {
      print('❌ Stream error: $error');
    }, onDone: () {
      print('ℹ️ Stream closed');
    });

  }
}