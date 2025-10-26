import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class UploadRestrictionDialog extends StatelessWidget {
  final String message;
  final RxInt remainingSeconds;
  final VoidCallback onClose;

  const UploadRestrictionDialog({
    Key? key,
    required this.message,
    required this.remainingSeconds,
    required this.onClose,
  }) : super(key: key);

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0086FF), // Primary Blue
              Color(0xFF00C6FF),
            ], // Lighter Sky Blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🧩 Animated emoji or icon
            const Icon(Icons.hourglass_bottom, color: Colors.white, size: 48),

            const SizedBox(height: 12),

            // 📝 Title
            const CustomText(
              "Hold On, Creator!",
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),

            const SizedBox(height: 10),

            // 💬 Message text
            CustomText(
              message,
              textAlign: TextAlign.center,
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
            ),

            const SizedBox(height: 20),

            // ⏳ Countdown timer
            Obx(() => CustomText(
                  "⏳ Next upload in: ${formatTime(remainingSeconds.value)}",
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                )),

            const SizedBox(height: 24),

            // ✋ Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const CustomText("Got it!",
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

