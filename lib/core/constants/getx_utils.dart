import 'package:get/get.dart';

T getOrPut<T>(T Function() builder) {
  if (Get.isRegistered<T>()) {
    return Get.find<T>();
  } else {
    return Get.put<T>(builder());
  }
}
