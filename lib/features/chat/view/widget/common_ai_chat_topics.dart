import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../ai_chat/view/ai_chat_message_view_screen.dart';
class InitialMessageOptionDialog extends StatelessWidget {
  final String userName;
  final List<Map<String, String>> topics;
  final Function(String message, String tag) onSend;

  const InitialMessageOptionDialog({
    super.key,
    required this.userName,
    required this.topics,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // important for dialog
      child: Container(
        width: 340,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            /// Title
            _whiteCard(
              child: CustomText(
                "Hi $userName Choose Your Topic",
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 6),

            /// Grid Topics
            _whiteCard(
              padding: const EdgeInsets.all(10),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3,
                ),
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];

                  return TopicButton(
                    title: topic["title"]!,
                    onTab: () {

                      onSend(topic["title"]!, topic["tag"]!);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            /// Subtitle
            _whiteCard(
              child: CustomText(
                "Or How Can I Help You?",
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 6),

            /// Bottom Buttons
            _whiteCard(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TopicButton(
                      title: "Create Reply",
                      onTab: () {
                        onSend("Create Reply", "create reply");
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TopicButton(
                      title: "Draft Email",
                      onTab: () {

                        onSend("Draft Email", "draft email");
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable white card container
  Widget _whiteCard({
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Container(
      width: 270,
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: child,
    );
  }
}