import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/go_live_pill.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Glassmorphic header shared by the rider and self-employee dashboards.
/// Left: drawer button + Refer & Earn pill. Right: bell (logged-in
/// users only) + Go Live pill. The Go Live tap is injected so each
/// host can decide whether to gate the toggle behind permission flow.
class ProfileTopBar extends StatelessWidget {
  final VoidCallback onGoLiveTap;
  final bool showGoLivePill;

  const ProfileTopBar({
    super.key,
    required this.onGoLiveTap,
    this.showGoLivePill = true,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x42001120),
            blurRadius: 16,
            offset: Offset(0, 0),
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              SizeConfig.size12,
              topInset + SizeConfig.size8,
              SizeConfig.size12,
              SizeConfig.size10,
            ),
            decoration: BoxDecoration(
              // Frosted band, matching the Connect header and the reference
              // (docs/chat_new.jpeg). It used to be a 20% white fill, which
              // over a busy banner left the bar reading as part of the photo
              // rather than as a surface sitting on it — the blur was doing all
              // the work and the controls had no plate to sit on.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.52),
                  Colors.white.withValues(alpha: 0.42),
                ],
              ),
              // Bottom hairline only. `Border.all` drew a hard white rule down
              // both sides and across the top of the bar — visible as a box
              // outline against the banner, which is not what the design shows.
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                _CircleIconButton(
                  icon: Icons.menu,
                  onTap: () => _openDrawer(context),
                ),
                SizedBox(width: SizeConfig.size8),
                const ReferEarnPill(),
                const Spacer(),
                if (!isGuestUser()) ...[
                  _CircleIconButton(
                    icon: Icons.notifications_none,
                    onTap: () => Navigator.pushNamed(
                      context,
                      RouteHelper.getNotificationScreenRoute(),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                ],
                if (showGoLivePill) _goLivePill(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The shared [GoLivePill], fed from the personal profile's shop status.
  ///
  /// This used to be a private `_GoLivePill` copied verbatim from the shared
  /// widget — same frosted pill, same 30×18 toggle, same spinner — differing
  /// only in that it read its own state instead of taking props. That meant the
  /// individual screens (self-employed, rider, cab) silently drifted from the
  /// ~14 business screens. Now there is one Go Live UI everywhere.
  Widget _goLivePill() {
    final viewCtrl = Get.find<ViewPersonalDetailsController>();
    return Obx(
      () => GoLivePill(
        value: viewCtrl.shopStatusOpenClose.value,
        isUpdating: viewCtrl.isShopStatusUpdating.value,
        onTap: onGoLiveTap,
      ),
    );
  }

  void _openDrawer(BuildContext context) {
    showDialog(
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      useSafeArea: false,
      context: context,
      builder: (_) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: double.infinity,
          child: Drawer(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: ProfileMenuDrawer(),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: CircleBorder()),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: SizeConfig.size36,
              width: SizeConfig.size36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFFC9CDD5),
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 20, color: AppColors.secondaryTextColor),
            ),
          ),
        ),
      ),
    );
  }
}

