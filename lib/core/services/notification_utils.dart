import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();
  static final List<void Function(bool)> _listeners = [];

  static Future<bool> isConnected() async {
    // final connectivityResult = await Connectivity().checkConnectivity();
    //
    // return connectivityResult.contains(ConnectivityResult.none);
return false;
  }

  static void addListener(void Function(bool isConnected) listener) {
    _listeners.add(listener);
  }


  static void initialize() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      final isConnected = !result.contains(ConnectivityResult.none) ;
      print("🔌 Connectivity changed: $result, connected: $isConnected");
      for (final listener in _listeners) {
        listener(isConnected);
      }
    });
  }

  /// Optional: remove listener if needed
  static void removeListener(void Function(bool isConnected) listener) {
    _listeners.remove(listener);
  }
}
