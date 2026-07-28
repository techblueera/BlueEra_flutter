import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/widgets/profile_share_banner.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The once-a-day "share your profile" promo, shown as a **bottom sheet** on
/// Discover.
///
/// Nothing but presentation — the promo clip, poster and share row are all one
/// card now, composed inside [ProfileShareBanner], which the profile screens
/// render inline. This only decides how that card is presented on Discover.
class SharePromoSheet {
  const SharePromoSheet._();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Open at 70% of the screen height; the banner is tall, so the body
      // scrolls within that cap (see the SingleChildScrollView below).
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.70,
      ),
      builder: (_) => const _SharePromoSheetBody(),
    );
  }
}

class _SharePromoSheetBody extends StatelessWidget {
  const _SharePromoSheetBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size10,
            SizeConfig.size8,
            SizeConfig.size10,
            SizeConfig.size12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dragHandle(),
              SizedBox(height: SizeConfig.size10),
              _banner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dragHandle() => Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.greyE5,
          borderRadius: BorderRadius.circular(999),
        ),
      );

  /// The share banner configured for the signed-in account type — business
  /// reads the registered business profile itself; individual is fed name /
  /// photo / designation from the personal profile (same as the me-screens).
  Widget _banner() {
    if (isBusinessUser()) {
      return const ProfileShareBanner(
        showCloseButton: true,
        // No promo clip on Discover: this sheet opens by itself once a day, so
        // it stays the poster + share row. (`autoPlayVideo` is moot while the
        // clip is hidden — flip showPromoVideo back to true to restore both.)
        showPromoVideo: false,
      );
    }
    final viewCtrl = getOrPut(() => ViewPersonalDetailsController());
    return Obx(() {
      final user = viewCtrl.personalProfileDetails.value.user;
      final name = (user?.name ?? '').trim();
      return ProfileShareBanner(
        // Always non-empty so the widget takes its override (individual) path
        // instead of falling back to the business profile.
        overrideName: name.isNotEmpty ? _capitalizeFirst(name) : 'My Profile',
        overridePhoto: user?.profileImage,
        overrideSubCategory: user?.designation ?? '',
        accountType: AppConstants.individual,
        // Surface the banner's own ✕ — it pops the sheet.
        showCloseButton: true,
        // No promo clip on Discover — see the business branch above.
        showPromoVideo: false,
      );
    });
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
