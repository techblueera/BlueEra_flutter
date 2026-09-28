import 'package:get/get.dart';

T getOrPut<T>(T Function() builder, {String? tag, bool permanent = false}) {
  if (Get.isRegistered<T>(tag: tag)) {
    return Get.find<T>(tag: tag);
  } else {
    return Get.put<T>(builder(), tag: tag, permanent: permanent);
  }
}

/// Registers [builder]'s result like `Get.put(builder())`, but only calls
/// [builder] when a new instance is actually needed.
///
/// `Get.put(X())` always constructs `X`, even when it then keeps the instance
/// already registered, so calling it from `build` makes a throwaway controller
/// (and its text controllers, Rx values, ...) on every rebuild. This goes
/// through the same registration path as `Get.put`, so unlike [getOrPut] it
/// still replaces an instance GetX has marked for deletion.
T putLazy<T>(T Function() builder, {String? tag}) {
  Get.lazyPut<T>(builder, tag: tag);
  return Get.find<T>(tag: tag);
}

void deleteIfRegistered<T>({String? tag}) {
  if (Get.isRegistered<T>(tag: tag)) {
    Get.delete<T>(tag: tag, force: true);
  }
}
