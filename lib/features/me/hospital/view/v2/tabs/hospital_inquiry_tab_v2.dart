import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:flutter/material.dart';

/// Inquiry tab — mirrors the inquiry list used by the Professionals
/// Consultant "Order" tab (`professionals_main.dart::_buildOrderTab`).
///
/// Shows incoming inquiries only — i.e. business chats whose latest
/// message was authored by *someone else* (`excludeSenderId: userId`),
/// so the hospital owner sees who reached out to them.
///
/// `BusinessChatsList` ships an Expanded `ListView` internally, so it
/// must live inside a bounded box; we use a fraction of the screen
/// height to play nicely with the parent `SingleChildScrollView`.
class HospitalInquiryTabV2 extends StatelessWidget {
  const HospitalInquiryTabV2({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.75,
      child: BusinessChatsList(
        isForwardUI: false,
        excludeSenderId: userId,
      ),
    );
  }
}
