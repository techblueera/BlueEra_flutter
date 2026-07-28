import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/feed/widget/feed_author_header_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/personal_profile_setup_new_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:flutter/material.dart';

class ProfileAvatarWidget extends StatelessWidget {
  final double size;
  final double? borderRadius;
  final Color? borderColor;
  final bool navigateOnTap;

  const ProfileAvatarWidget({
    super.key,
    this.size = 34,
    this.borderRadius,
    this.borderColor,
    this.navigateOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: navigateOnTap ? () => _onProfileTap(context) : null,
      child: CachedAvatarWidget(
        imageUrl: userProfileGlobal.isNotEmpty ? userProfileGlobal : null,
        size: size,
        borderRadius: borderRadius ?? size / 2,
        borderColor: borderColor ?? AppColors.primaryColor,
        showProfileOnFullScreen: false,
      ),
    );
  }

  void _onProfileTap(BuildContext context) {
    if (isGuestUser()) {
      createProfileScreen();
    } else if (isIndividualUser()) {
      openMeOverview();

      // navigatePushTo(context, PersonalProfileSetupNewScreen());
    } else if (isBusinessUser()) {
      navigatePushTo(context, BusinessOwnProfileScreen());
    }
  }
}
