import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final Function(bool isVisible) onHeaderVisibilityChanged;
  final bool isBottomNavVisible;
  final int currentIndex;
  final Function(int) onTap;
  final int chatNotificationCount;
  // When the SubscriptionDraggableSheet sits above the bar it provides its
  // own peak shadow, so the parent passes [showShadow] = false to avoid a
  // doubled shadow. On every other Me-tab state (sheet hidden because of
  // active subscription, social profile, etc.) the bar paints its own.
  final bool showShadow;

  BottomNavigationBarWidget({
    super.key,
    required this.onHeaderVisibilityChanged,
    required this.isBottomNavVisible,
    required this.currentIndex,
    required this.onTap,
    required this.chatNotificationCount,
    this.showShadow = true,
  });

  DateTime? lastBackPressed;

  bool _handleBackPress(BuildContext context) {
    if (!isBottomNavVisible) {
      onHeaderVisibilityChanged.call(true);
      return false;
    }
    final now = DateTime.now();
    if (lastBackPressed == null ||
        now.difference(lastBackPressed!) > const Duration(seconds: 2)) {
      lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Press back again to exit the app"),
          duration: Duration(seconds: 2),
        ),
      );
      return false; // Don't exit yet
    }
    return true; // Exit on second press
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_handleBackPress(context)) {
            SystemNavigator.pop();
          }
        }
      },
      child: SafeArea(
        top: false, // we only care about bottom
        child: Container(
          height: SizeConfig.size70, // adjust as needed
          decoration: BoxDecoration(
            color: AppColors.white,
            // Drop our own border + shadow only when the
            // SubscriptionDraggableSheet is rendering above us — otherwise
            // we'd doubled them up. The parent decides via [showShadow].
            border: !showShadow
                ? null
                : const Border(
                    top: BorderSide(color: AppColors.whiteDB, width: 1),
                  ),
            boxShadow: !showShadow
                ? null
                : const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                iconPath: AppIconAssets.home,
                isSelected: currentIndex == 0,
                label: AppStrings.home,
              ),
              _buildNavItem(
                index: 1,
                iconPath: AppIconAssets.finderIcon,
                isSelected: currentIndex == 1,
                label: AppStrings.discover,
              ),
              _buildNavItem(
                index: 2,
                iconPath: AppIconAssets.menIcon,
                isSelected: currentIndex == 2,
                label: AppStrings.me,
                // isCenter: true, // 👈 center icon
              ),
              // _buildNavItem(
              //   index: 3,
              //   iconPath: AppIconAssets.job,
              //   isSelected: currentIndex == 3,
              //   label: AppStrings.jobs,
              // ),
              _buildNavItem(
                index: 3,
                iconPath: AppIconAssets.chat,
                isSelected: currentIndex == 3,
                label: AppStrings.chat,
                showBadge: chatNotificationCount > 0,
                badgeText: "$chatNotificationCount",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String iconPath,
    required bool isSelected,
    String? label,
    bool isCenter = false,
    bool showBadge = false,
    String badgeText = '',
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: isCenter ? 40 : 24,
                  width: isCenter ? 40 : 24,
                  child: LocalAssets(
                    imagePath: iconPath,
                    imgColor: !isCenter
                        ? isSelected
                        ? AppColors.primaryColor
                        : AppColors.black
                        : null,
                    // imgColor: index != 2
                    //     ? isSelected
                    //         ? AppColors.primaryColor
                    //         : AppColors.black
                    //     : null,
                  ),
                ),
                if (showBadge)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: CustomText(
                        badgeText,
                        fontSize: SizeConfig.extraSmall,
                        color: AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),
            if (!isCenter && label != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: CustomText(
                  label,
                  fontSize: SizeConfig.extraSmall,
                  color: isSelected ? AppColors.primaryColor : AppColors.black,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
