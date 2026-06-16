import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:flutter/material.dart';

/// Inquiry tab — incoming business chats, mirroring the hospital v2
/// inquiry tab. `BusinessChatsList` ships an Expanded `ListView`
/// internally, so it must live inside a bounded box.
class VehicleInquiryTabV2 extends StatelessWidget {
  const VehicleInquiryTabV2({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.75,
      child: const BusinessChatsList(),
    );
  }
}
