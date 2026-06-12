import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/view/widget/component_widgets.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Renders a `payment_transaction` chat message — a payment recorded against a
/// Payment QR (UTR + amount + screenshot). See payment-qr-integration-guide.md.
///
/// Outgoing (payer / [isReceive] == false): "Payment Sent".
/// Incoming (payee / [isReceive] == true):  "Payment Received".
class PaymentTransactionMsgCard extends StatelessWidget {
  final Messages message;
  final String time;
  final bool isReceive;

  const PaymentTransactionMsgCard({
    super.key,
    required this.message,
    required this.time,
    required this.isReceive,
  });

  String? get _screenshotUrl {
    final list = message.url;
    if (list == null || list.isEmpty) return null;
    return list.first.url;
  }

  @override
  Widget build(BuildContext context) {
    final chatThemeController = Get.find<ChatThemeController>();
    final meta = message.metadata;
    final amount = meta?.amount;
    final utr = meta?.utrNo ?? '';
    final screenshot = _screenshotUrl;

    final bgColor = isReceive
        ? chatThemeController.receiveMessageBgColor.value
        : chatThemeController.myMessageBgColor.value;
    final onColor = isReceive ? AppColors.mainTextColor : Colors.white;
    final subColor = isReceive ? AppColors.grayText : Colors.white70;

    return Align(
      alignment: isReceive ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: SizeConfig.screenWidth * 0.66,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomRight: Radius.circular(isReceive ? 12 : 0),
            bottomLeft: Radius.circular(isReceive ? 0 : 12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: icon + title + amount
            Padding(
              padding:
                  const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 6),
              child: Row(
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: (isReceive ? AppColors.primaryColor : Colors.white)
                          .withValues(alpha: isReceive ? 0.12 : 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isReceive
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      size: 18,
                      color: isReceive ? AppColors.primaryColor : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomText(
                      isReceive ? 'Payment Received' : 'Payment Sent',
                      fontWeight: FontWeight.w700,
                      fontSize: SizeConfig.size14,
                      color: onColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (amount != null)
                    CustomText(
                      '₹${_formatAmount(amount)}',
                      fontWeight: FontWeight.w800,
                      fontSize: SizeConfig.size16,
                      color: onColor,
                    ),
                ],
              ),
            ),
            // UTR
            if (utr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    CustomText(
                      'UTR: ',
                      fontSize: SizeConfig.size12,
                      color: subColor,
                      fontWeight: FontWeight.w500,
                    ),
                    Expanded(
                      child: CustomText(
                        utr,
                        fontSize: SizeConfig.size12,
                        color: subColor,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            // Screenshot preview
            if (screenshot != null && screenshot.isNotEmpty)
              GestureDetector(
                onTap: () => _showScreenshot(context, screenshot),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(maxHeight: 180),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black12,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    screenshot,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 120,
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryColor),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 120,
                      child: Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            // Time + read info
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 4, bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  timeAndReadInfoWidget(
                    message: message,
                    isMyMessage: message.myMessage ?? false,
                    time: time,
                    timeColor: isReceive ? Colors.black45 : Colors.white70,
                    indicateColor:
                        message.messageRead == 1 ? Colors.blue : Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Trims a trailing `.0` so whole rupees read cleanly (₹499 not ₹499.0).
  String _formatAmount(num value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  void _showScreenshot(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 16,
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
