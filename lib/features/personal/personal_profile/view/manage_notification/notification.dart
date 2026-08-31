import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/notification_settings_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_switch_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationSettingScreen extends StatelessWidget {
  const NotificationSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationSettingsController>();

    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.notificationSetting.tr),
      body: Obx(() {
        final status = controller.getResponse.value.status;
        if (status == Status.LOADING || status == Status.INITIAL) {
          return const Center(child: CircularProgressIndicator());
        }
        if (status == Status.ERROR && controller.preferences.isEmpty) {
          return _ErrorState(onRetry: controller.fetchSettings);
        }
        if (controller.preferences.isEmpty) {
          return Center(
            child: CustomText(
              AppStrings.noNotificationSettingsAvailable.tr,
              color: AppColors.mainTextColor,
            ),
          );
        }

        final keys = controller.preferences.keys.toList();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _ColumnHeader(),
                        ...keys.map(
                          (key) => _NotificationTile(
                            title: _formatTitle(key),
                            settingKey: key,
                            controller: controller,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => PositiveCustomBtn(
                  onTap: controller.isUpdating.value
                      ? null
                      : () => controller.submit(),
                  title: controller.isUpdating.value
                      ? '${AppStrings.submit.tr}...'
                      : AppStrings.submit.tr,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  String _formatTitle(String key) {
    if (key.isEmpty) return key;
    final normalized = key.replaceAll(RegExp(r'[_\-]+'), ' ');
    final spaced = normalized.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
    return spaced
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              AppStrings.category.tr,
              color: AppColors.mainTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            width: SizeConfig.size60,
            child: CustomText(
              AppStrings.pushLabel.tr,
              color: AppColors.mainTextColor,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String settingKey;
  final NotificationSettingsController controller;

  const _NotificationTile({
    required this.title,
    required this.settingKey,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greyE5, width: 0.5),
        ),
        child: Obx(() {
          final pref = controller.preferences[settingKey];
          final push = pref?.push ?? false;
          return Row(
            children: [
              Expanded(
                child: CustomText(title.tr, color: AppColors.mainTextColor),
              ),
              SizedBox(
                width: SizeConfig.size60,
                child: Center(
                  child: CustomSwitch(
                    value: push,
                    onChanged: (v) => controller.togglePush(settingKey, v),
                    containerHeight: SizeConfig.size24,
                    containerWidth: SizeConfig.size44,
                    circleSize: SizeConfig.size16,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              AppStrings.somethingWentWrong.tr,
              color: AppColors.mainTextColor,
            ),
            const SizedBox(height: 12),
            PositiveCustomBtn(
              onTap: onRetry,
              title: AppStrings.retry.tr,
              width: SizeConfig.size120,
            ),
          ],
        ),
      ),
    );
  }
}
