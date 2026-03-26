import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RiderLookupDialog {
  RiderLookupDialog._();

  static void show({required String text}) {
    final Stream<int> timerStream =
    Stream.periodic(const Duration(seconds: 1), (i) => 180 - i - 1)
        .take(180);

    Get.dialog(
      Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 25),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── Rider Illustration ───────────────────────────────────
                LocalAssets(
                  imagePath: AppIconAssets.riderIconColorful,
                  boxFix: BoxFit.contain,
                  height: 100,
                  width: 100,
                ),

                const SizedBox(height: 20),

                // ── Dynamic Text ─────────────────────────────────────────
                CustomText(
                  text,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // ── Action Row ───────────────────────────────────────────
                Row(
                  children: [

                    // Cancel Button
                    Expanded(
                      child: CustomBtn(
                        onTap: () => hide(),
                        title: "Cancel",
                        bgColor: AppColors.red,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Timer Button
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            StreamBuilder<int>(
                              stream: timerStream,
                              initialData: 180,
                              builder: (context, snapshot) {
                                final int seconds = snapshot.data ?? 0;
                                final int minutes = seconds ~/ 60;
                                final int remainingSeconds = seconds % 60;
                                final String timeText =
                                    "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";

                                return CustomText(
                                  timeText,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void hide() {
    if (Get.isDialogOpen ?? false) Get.back();
  }
}