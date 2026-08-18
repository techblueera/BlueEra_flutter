import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/view/widget/component_widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Who the chat's "Call Customer" button should reach, and in which thread.
class CallCustomerTarget {
  const CallCustomerTarget({
    required this.conversationId,
    required this.name,
    this.userId,
    this.phone,
    this.photoUrl,
  });

  final String conversationId;
  final String name;

  /// The customer's BlueEra user id — required for the in-app voice/video call.
  final String? userId;

  /// The customer's phone number — enables the sheet's "Normal call" option.
  final String? phone;
  final String? photoUrl;

  bool get isReachable =>
      (userId ?? '').isNotEmpty || (phone ?? '').trim().isNotEmpty;
}

/// Drives the "Call Customer" button that hangs over a chat thread once the
/// shop owner has sent a packing PDF for that conversation.
///
/// The shop owner has just told the customer their order is packed, so the next
/// thing they almost always do is ring them — hence the button rather than
/// making them go back up to the appbar.
///
/// Tap behaviour is deliberately asymmetric, and both branches go through the
/// chat's own calling code so the pill behaves identically to the call icon in
/// the appbar:
///   • the **first** tap places the voice call straight away
///     ([startChatVoiceCall]) — that is what the owner wants in the common
///     case, so asking first would just add a step;
///   • **every tap after that** opens the appbar's own call sheet
///     ([showChatCallOptionsBottomSheet]) with voice / video / normal call,
///     because a repeat tap usually means the app call didn't get through and
///     the owner now wants the dialler.
///
/// Targets live for the session only — they are keyed by conversation so
/// leaving and re-entering a thread keeps the button, and each conversation
/// tracks its own tap count.
class CallCustomerController extends GetxController {
  final RxMap<String, CallCustomerTarget> _targets =
      <String, CallCustomerTarget>{}.obs;

  /// conversationId -> how many times the button has been tapped.
  final Map<String, int> _tapCounts = <String, int>{};

  /// The button target for [conversationId], or null when no packing PDF has
  /// been sent in that thread (or the customer can't be reached at all).
  CallCustomerTarget? targetFor(String? conversationId) {
    if ((conversationId ?? '').isEmpty) return null;
    return _targets[conversationId!];
  }

  /// Called right after a packing PDF is sent into [target]'s conversation.
  /// Unreachable customers are ignored so we never hang a dead button.
  void showFor(CallCustomerTarget target) {
    if (target.conversationId.isEmpty || !target.isReachable) return;
    _targets[target.conversationId] = target;
  }

  /// Hide the button for [conversationId] (the owner dismissed it).
  void dismiss(String conversationId) {
    _targets.remove(conversationId);
    _tapCounts.remove(conversationId);
  }

  /// How many times the button has been tapped in [conversationId].
  int tapCountFor(String conversationId) => _tapCounts[conversationId] ?? 0;

  void onTap(BuildContext context, CallCustomerTarget target) {
    final taps = tapCountFor(target.conversationId) + 1;
    _tapCounts[target.conversationId] = taps;

    final canAppCall = (target.userId ?? '').isNotEmpty;

    // First tap → straight to the voice call, provided we can place one.
    if (taps == 1 && canAppCall) {
      startChatVoiceCall(
        otherUserId: target.userId,
        conversationId: target.conversationId,
        userName: target.name,
        userImage: target.photoUrl ?? '',
      );
      return;
    }

    // Subsequent taps (or no user id to call) → the chat's own call sheet.
    if (!canAppCall && (target.phone ?? '').trim().isEmpty) {
      commonSnackBar(message: AppStrings.customerContactUnavailable.tr);
      return;
    }

    showChatCallOptionsBottomSheet(
      context: context,
      otherUserId: target.userId,
      conversationId: target.conversationId,
      userName: target.name,
      userImage: target.photoUrl ?? '',
      contactNo: target.phone ?? '',
    );
  }
}

/// Hangs the "Call Customer" button over [conversationId] right after a packing
/// PDF has been sent for [orderMessage].
///
/// The customer is the other party in the thread: on the shop owner's side the
/// order card was *received*, so its sender is the customer. The conversation
/// person id from [ChatViewController] is preferred because it is direction
/// independent; the sender is the fallback for threads opened without it.
void showCallCustomerButtonFor({
  required String? conversationId,
  required Messages orderMessage,
}) {
  if ((conversationId ?? '').isEmpty) return;

  final sender = orderMessage.sender;
  final chat = Get.isRegistered<ChatViewController>()
      ? Get.find<ChatViewController>()
      : null;

  getOrPut(() => CallCustomerController()).showFor(
    CallCustomerTarget(
      conversationId: conversationId!,
      name: (sender?.name ?? '').isNotEmpty ? sender!.name! : 'Customer',
      userId: (chat?.currentChatOtherUserId ?? '').isNotEmpty
          ? chat!.currentChatOtherUserId
          : sender?.id,
      phone: sender?.contactNo,
      photoUrl: sender?.profileImage,
    ),
  );
}
