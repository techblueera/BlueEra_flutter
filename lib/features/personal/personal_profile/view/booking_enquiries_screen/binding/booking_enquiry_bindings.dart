import 'package:get/get.dart';

import '../controller/appointment_booking_controller.dart';
import '../controller/send_enquiry_controller.dart';
import '../repo/booking_repo.dart';

/// Scopes an [AppointmentBookingController] to the booking screen's route.
class AppointmentBookingBinding extends Bindings {
  AppointmentBookingBinding({required this.channelId, required this.videoId});

  final String channelId;
  final String videoId;

  @override
  void dependencies() {
    Get.lazyPut(() => AppointmentBookingController(
        repo: BookingRepo(), channelId: channelId, videoId: videoId));
  }
}

/// Scopes a [SendEnquiryController] to the enquiry screen's route.
class SendEnquiryBinding extends Bindings {
  SendEnquiryBinding({required this.channelId, required this.videoId});

  final String channelId;
  final String videoId;

  @override
  void dependencies() {
    Get.lazyPut(() => SendEnquiryController(
        repo: BookingRepo(), channelId: channelId, videoId: videoId));
  }
}
