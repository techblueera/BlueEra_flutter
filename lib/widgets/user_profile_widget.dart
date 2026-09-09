import 'package:BlueEra/core/navigation/me_profile_navigator.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/common/feed/widget/feed_author_header_widget.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommonProfileAvatar extends StatelessWidget {
  final VoidCallback? onProfileTap;
  final double? size;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  const CommonProfileAvatar({
    super.key,
    this.onProfileTap,
    this.size,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(borderRadius ?? 5.0),
      onTap: () {
        if (onProfileTap != null) {
          onProfileTap!();
          return;
        }

        if (isGuestUser()) {
          createProfileScreen();
        } else if (isIndividualUser()) {
          MeProfileNavigator.openOverview();

          // navigatePushTo(context, PersonalProfileSetupNewScreen());
        } else if (isBusinessUser()) {
          // Own business profile -> the "Me" tab, which resolves the per-business-
          // type screen (Food / Grocery / School / Hospital / Hotel / Product / ...).
          // BusinessOwnProfileScreen() is the single generic profile every business
          // type used to share; the individual branch already routes this way.
          MeProfileNavigator.openOverview();
        }
      },
      child: Obx(() {
        final authController = Get.find<AuthController>();

        return Padding(
          padding: padding ?? EdgeInsets.only(left: SizeConfig.size15),
          child: CachedAvatarWidget(
            imageUrl: authController.imgPath.value,
            size: size ?? SizeConfig.size30,
            borderRadius: borderRadius ?? 5.0,
            showProfileOnFullScreen: false,
          ),
        );
      }),
    );
  }
}
