import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
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

  BottomNavigationBarWidget({
    super.key,
    required this.onHeaderVisibilityChanged,
    required this.isBottomNavVisible,
    required this.currentIndex,
    required this.onTap,
    required this.chatNotificationCount,
  });
  DateTime? lastBackPressed;

  bool _handleBackPress(BuildContext context) {
    if(!isBottomNavVisible){
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
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(
              top: BorderSide(color: AppColors.whiteDB, width: 1),
            ),
            boxShadow: [
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
                label: 'Home',
              ),
              _buildNavItem(
                index: 1,
                iconPath: AppIconAssets.shop,
                isSelected: currentIndex == 1,
                label: 'Store',
              ),
              _buildNavItem(
                index: 2,
                iconPath: AppIconAssets.gpsIcon,
                isSelected: currentIndex == 2,
                isCenter: true, // 👈 center icon
              ),
              _buildNavItem(
                index: 3,
                iconPath: AppIconAssets.job,
                isSelected: currentIndex == 3,
                label: 'Jobs',
              ),
              _buildNavItem(
                index: 4,
                iconPath: AppIconAssets.chat,
                isSelected: currentIndex == 4,
                label: 'Chat',
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
                    imgColor: index != 2
                        ? isSelected
                            ? AppColors.primaryColor
                            : AppColors.black
                        : null,
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
