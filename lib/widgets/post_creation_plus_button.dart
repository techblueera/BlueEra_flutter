import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/popup_menu_builders.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/chat/view/add_symbol/add_symbol_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/post_via_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The "+" create-post control used in the Social section header, and anywhere
/// else that needs the *same* entry point (currently the My Post empty state).
///
/// It is a single widget rather than a copied block so the two never drift:
/// same [PopupMenuBuilders.popupMenuItems] list, same guest gate, and the same
/// "attribute to the profile" shortcut — the Social section is the user's own
/// feed, so nothing created here raises the channel/profile chooser that other
/// entry points (global app bar, Me dashboards) still show.
class PostCreationPlusButton extends StatelessWidget {
  const PostCreationPlusButton({
    super.key,
    this.size = 32,
    this.offset = const Offset(0, 36),
    this.only,
  });

  /// Edge length of the "+" glyph.
  final double size;

  /// Where the popup opens relative to the button.
  final Offset offset;

  /// Narrows the menu to these entries — see [PopupMenuBuilders.postCreationMenus].
  /// Null (the default) offers everything the account may post.
  final Set<PostCreationMenu>? only;

  @override
  Widget build(BuildContext context) {
    // Nothing this account is allowed to create in the requested slice (a
    // business account on a reel-only menu, say) — show no affordance at all
    // rather than a "+" that opens an empty popup.
    if (PopupMenuBuilders.postCreationMenus(only: only).isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<PostCreationMenu>(
      padding: EdgeInsets.zero,
      offset: offset,
      color: AppColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      onSelected: (value) async {
        if (isGuestUser()) {
          createProfileScreen();
        } else if (value == PostCreationMenu.message ||
            value == PostCreationMenu.poll ||
            value == PostCreationMenu.reel) {
          postNavigations(context, value, PostVia.profile);
        } else if (value == PostCreationMenu.jobPost) {
          Get.toNamed(
            RouteHelper.getCreateJobPostScreenRoute(),
            arguments: {
              'isEditMode': false,
              'jobId': '',
              'createJobVia': 'business',
            },
          );
        } else if (value == PostCreationMenu.symbol) {
          Get.to(() => AddChatSymbolScreen());
        }
      },
      itemBuilder: (context) => PopupMenuBuilders.popupMenuItems(only: only),
      child: LocalAssets(
        imagePath: AppIconAssets.addOutlinedIcon,
        width: size,
        height: size,
      ),
    );
  }
}
