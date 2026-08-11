import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/help_support/controller/help_support_controller.dart';
import 'package:BlueEra/features/common/help_support/model/help_question.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The "How can we help you?" body: the server-tailored question list plus a
/// free-text composer.
///
/// Extracted from [HelpBubble] so the floating bubble and the header's
/// customer-care button are the same conversation, not two that drift. The
/// bubble renders it inline in its own card; the header button has nothing to
/// anchor a popover to, so it presents this in a bottom sheet — hence the
/// [onClose] hook and the optional [showCloseButton], which are the only things
/// that differ between the two hosts.
class HelpQuestionsPanel extends StatefulWidget {
  const HelpQuestionsPanel({
    super.key,
    required this.onClose,
    this.showCloseButton = true,
  });

  /// Dismisses whatever is hosting the panel — collapses the bubble, or pops
  /// the sheet. Also called after a question is sent, since sending navigates
  /// the user to the chat screen.
  final VoidCallback onClose;

  /// The bottom-sheet host has a drag handle of its own, so it hides this.
  final bool showCloseButton;

  @override
  State<HelpQuestionsPanel> createState() => _HelpQuestionsPanelState();
}

class _HelpQuestionsPanelState extends State<HelpQuestionsPanel> {
  final HelpSupportController _controller =
      getOrPut(() => HelpSupportController());

  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _textFocus = FocusNode();

  bool get _isHindi => _controller.languageCode == 'hi';

  @override
  void dispose() {
    _textCtrl.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  Future<void> _send(String text, {String? questionId}) async {
    final opened = await _controller.sendInquiry(text, questionId: questionId);
    if (!mounted || !opened) return;
    // Only clear on success — a failed send keeps what the user typed.
    _textCtrl.clear();
    widget.onClose();
  }

  void _onQuestionTap(HelpQuestion q) {
    if (q.isOther) {
      // "Other inquiry" isn't a question, it's a prompt to write one.
      _textFocus.requestFocus();
      return;
    }
    _send(q.label(_controller.languageCode), questionId: q.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomText(
                _isHindi
                    ? 'Hum aapki kaise madad karein?'
                    : 'How can we help you?',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 2,
              ),
            ),
            if (widget.showCloseButton)
              InkWell(
                onTap: widget.onClose,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: AppColors.secondaryTextColor),
                ),
              ),
          ],
        ),
        SizedBox(height: SizeConfig.size8),
        // The list is short and server-capped (4 tailored + "Other"), so it is
        // laid out inline; bounded anyway so an unexpectedly long reply scrolls
        // inside the panel instead of overflowing the screen.
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: SingleChildScrollView(
            child: Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final q in _controller.questions) _questionRow(q),
                ],
              ),
            ),
          ),
        ),
        Divider(height: SizeConfig.size20, color: const Color(0xFFE0E0E0)),
        _composer(),
      ],
    );
  }

  Widget _questionRow(HelpQuestion q) {
    return InkWell(
      onTap: () => _onQuestionTap(q),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: SizeConfig.size8,
          horizontal: SizeConfig.size4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            SizedBox(width: SizeConfig.size8),
            Expanded(
              child: CustomText(
                q.label(_controller.languageCode),
                fontSize: SizeConfig.small,
                fontWeight: q.isOther ? FontWeight.w600 : FontWeight.w500,
                color:
                    q.isOther ? AppColors.primaryColor : AppColors.mainTextColor,
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _textCtrl,
            focusNode: _textFocus,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.send,
            onSubmitted: (v) => _send(v),
            style: TextStyle(fontSize: SizeConfig.small),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText:
                  _isHindi ? 'Apna sawaal likhein…' : 'Type your question…',
              hintStyle: TextStyle(
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
              ),
            ),
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        Obx(() {
          if (_controller.isSending.value) {
            return const SizedBox(
              width: 34,
              height: 34,
              child: Padding(
                padding: EdgeInsets.all(7),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return InkWell(
            onTap: () => _send(_textCtrl.text),
            customBorder: const CircleBorder(),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor,
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 17),
            ),
          );
        }),
      ],
    );
  }
}
