import 'package:get/get.dart';
import 'package:BlueEra/features/me/school/controller/notice_news_controller.dart';

/// Registers [NoticeController] for [NoticeNewsScreen].
///
/// This screen is opened with Get.to (not a named route), so the binding is
/// passed at each call site. Every call site must pass it: without one the
/// screen's Get.find would throw.
class NoticeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NoticeController>(() => NoticeController());
  }
}
