import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

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
    // From Connect (0) or Order (3), back routes to Discover (1) instead
    // of falling through to the press-twice-to-exit flow. Discover is the
    // app's "home" tab in this layout.
    if (currentIndex == 0 || currentIndex == 3) {
      onTap(1);
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

  // ── Design tokens ──────────────────────────────────────────
  // All values pinned to the spec the product asked for, so future
  // tweaks to the bar's identity happen in one place.
  static const double _barRadius = 20;
  static const double _barPadding = 6;
  static const double _pillRadius = 12;

  // Column layout: icon stacked over label. Identical paddings/size
  // for selected and unselected so layout is stable on tap — only
  // the decoration (pill bg) and the text/icon color animate.
  static const double _pillPaddingH = 16;
  static const double _pillPaddingV = 8;
  static const double _iconLabelGap = 2;
  static const double _iconSize = 18;
  static const double _labelFontSize = 10;
  static const double _horizontalInset = 14;
  static const double _bottomInset = 10;

  // Bar height = bar padding (10×2) + pill v-padding (2×2) + icon (18)
  // + icon→label gap (2) + actual label line height (~16 with default
  // text height factor + leading) ≈ 60. Bumped slightly to 72 for
  // text-metric headroom across devices. Pinned explicitly so the
  // Stack→AnimatedSlide→FractionalTranslation chain never queries
  // intrinsic dimensions through the BackdropFilter.

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
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              _horizontalInset, 0, _horizontalInset, _bottomInset),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: DecoratedBox(
              // Drop shadow per spec: black 0.26 / blur 16 / offset (0,0).
              // BlurStyle.outer is the critical bit — at offset (0,0) a
              // normal BoxShadow renders behind the box and bleeds
              // through our translucent (white 0.30) surface, which made
              // the whole bar look dark/blurred. .outer paints only the
              // outer halo, leaving the bar interior clean so the
              // BackdropFilter and icons read crisp.
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_barRadius),
                boxShadow: !showShadow
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.26),
                          blurRadius: 16,
                          offset: const Offset(0, 0),
                          blurStyle: BlurStyle.outer,
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_barRadius),
                child: BackdropFilter(
                  // Blur 12 per spec.
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    // White 0.30 fill + 1.5 px white border per spec.
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(_barRadius),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(_barPadding),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Tab mapping: Me=0, Discover=1, Connect=2, Order=3.
                        // Selected tab takes flex 2 so the icon + label pill
                        // can breathe; unselected take flex 1 (icon only).
                        _buildNavItem(
                          index: 0,
                          iconPath: AppIconAssets.menIcon,
                          isSelected: currentIndex == 0,
                          label: AppStrings.me,
                        ),
                        _buildNavItem(
                          index: 1,
                          iconPath: AppIconAssets.finderIcon,
                          isSelected: currentIndex == 1,
                          label: AppStrings.discover,
                        ),
                        _buildNavItem(
                          index: 2,
                          iconPath: AppIconAssets.chat,
                          isSelected: currentIndex == 2,
                          label: AppStrings.chat.tr,
                        ),
                        _buildNavItem(
                          index: 3,
                          iconPath: AppIconAssets.socialNetworkIcon,
                          isSelected: currentIndex == 3,
                          label: AppStrings.social.tr,
                          showBadge: chatNotificationCount > 0,
                          badgeText: "$chatNotificationCount",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
    bool showBadge = false,
    String badgeText = '',
  }) {
    // Selected pill earns extra room so the icon + label can sit
    // side-by-side without crowding the unselected slots next to it.
    final color = isSelected ? AppColors.primaryColor : AppColors.mainTextColor;

    // Stable layout: every tab uses flex 1 + the same padding +
    // always shows icon-and-label side-by-side. Only the decoration
    // (pill bg color) and the text color/weight differ between
    // selected and unselected. Size is identical → no layout reflow
    // on tap → FractionalTranslation never finds an unlaid-out child.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(_pillRadius),
        splashColor: AppColors.primaryColor.withValues(alpha: 0.10),
        highlightColor: AppColors.primaryColor.withValues(alpha: 0.05),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 7),
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_pillRadius),
            child: Stack(
              children: [
                if (isSelected)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: const SizedBox.shrink(),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: _pillPaddingH,
                    vertical: _pillPaddingV,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryColor.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(_pillRadius),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            height: _iconSize,
                            width: _iconSize,
                            child: LocalAssets(
                              imagePath: iconPath,
                              imgColor: color,
                            ),
                          ),
                          if (showBadge)
                            Positioned(
                              top: -4,
                              right: -6,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.20),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: CustomText(
                                    badgeText,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (label != null) ...[
                        const SizedBox(height: _iconLabelGap),
                        CustomText(
                          label,
                          fontSize: _labelFontSize,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: color,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
