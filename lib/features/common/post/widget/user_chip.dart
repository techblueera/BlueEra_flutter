import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/reel/models/get_all_users.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class UserChip extends StatelessWidget {
  final UsersData user;
  final VoidCallback onRemove;

  const UserChip({
    Key? key,
    required this.user,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          EdgeInsets.only(right: SizeConfig.size8, bottom: SizeConfig.size8),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size12, vertical: SizeConfig.size6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              "@${user.name}",
              fontSize: SizeConfig.size14,
              color: Colors.black87,
            ),
            SizedBox(width: SizeConfig.size4),
            InkWell(
                onTap: onRemove,
                child: LocalAssets(
                  imagePath: AppIconAssets.close_black,
                  imgColor: Colors.black,
                ))
          ],
        ),
      ),
    );
  }
}
