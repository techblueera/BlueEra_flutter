import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';

/// Opens the customer's chat with the captain of a live ride.
///
/// A ride booking is an order with the rider as the shop (see `bucketChat` in
/// business_chat_list.dart), so the thread belongs to the **business** lane —
/// the customer finds it under Inquiry, next to their grocery and Discover
/// orders. Passing [AppConstants.route_discover] is what pins it there: without
/// it, `checkChatConnection` opens whichever lane the backend happens to report
/// and the ride chat can land in the personal Chat tab instead.
///
/// Shared by every customer-side entry point into that thread (the Discover
/// ongoing-ride chip and leaving the ride tracking screen) so they can't drift
/// into opening two different conversations with the same captain.
///
/// The captain's name / number / photo are passed through when the caller
/// already has them — they seed the chat header while `checkChatConnection` is
/// still in flight, so the screen never opens on a blank title.
Future<void> openRiderInquiryChat({
  required String riderUserId,
  String? name,
  String? phone,
  String? photoUrl,
}) async {
  if (riderUserId.isEmpty) {
    commonSnackBar(message: 'Captain chat is unavailable right now');
    return;
  }
  await getOrPut(() => ChatViewController()).checkChatConnectionAndOpenChat(
    userId: riderUserId,
    name: name,
    conductNo: phone,
    profile: photoUrl,
    route: AppConstants.route_discover,
  );
}
