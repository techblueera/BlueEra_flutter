import 'package:get/get.dart';

T getOrPut<T>(T Function() builder, {String? tag}) {
  if (Get.isRegistered<T>(tag: tag)) {
    return Get.find<T>(tag: tag);
  } else {
    return Get.put<T>(builder(), tag: tag);
  }
}

void deleteIfRegistered<T>({String? tag}) {
  if (Get.isRegistered<T>(tag: tag)) {
    Get.delete<T>(tag: tag, force: true);
  }
}
