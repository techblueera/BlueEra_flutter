import 'package:get/get.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkController extends GetxController {
  final InternetConnection _connection = InternetConnection();

  bool isOnline = true;

  bool get online => isOnline;

  @override
  void onInit() {
    super.onInit();
    _init();
    _listen();
  }

  Future<void> _init() async {
    isOnline = await _connection.hasInternetAccess;
    update();
  }

  void _listen() {
    _connection.onStatusChange.listen((status) {
      final newStatus = status == InternetStatus.connected;
      if (newStatus != isOnline) {
        isOnline = newStatus;
      }
      update();
    });
  }
}
