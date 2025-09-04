import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/network_assets.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CommonProfileImage extends StatefulWidget {
  String? imagePath;
  String? dialogTitle;
  final double size;
  final Function(String) onImageUpdate;
  final bool isOwnProfile;

  CommonProfileImage({
    Key? key,
    required this.imagePath,
    required this.dialogTitle,
    required this.onImageUpdate,
    this.size = 100,
    this.isOwnProfile = true
  }) : super(key: key);

  @override
  State<CommonProfileImage> createState() => _CommonProfileImageState();
}

class _CommonProfileImageState extends State<CommonProfileImage> {


  @override
  Widget build(BuildContext context) {
    print('image--> ${widget.imagePath}');
    return InkWell(
      onTap: (widget.isOwnProfile) ? () => selectImage(context,widget.dialogTitle??"Upload Picture") : null,
      child: Stack(
        children: [
          Container(
            // padding: EdgeInsets.all(SizeConfig.size2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryColor, width: 1.6),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.white,
              child: widget.imagePath?.isNotEmpty == true
                  ? ClipOval(
                      child: ((widget.imagePath != null) &&
                              (widget.imagePath?.isNotEmpty ?? false) &&
                              (isNetworkImage(widget.imagePath ?? "")))
                          ? NetWorkOcToAssets(imgUrl: widget.imagePath??"")
                          : Image(
                              image: FileImage(File(widget.imagePath??""))
                                ..evict(),
                              fit: BoxFit.cover,
                              width: 100, // radius * 2
                              height: 100,
                            ),
                    )
                  : LocalAssets(imagePath: AppIconAssets.user_out_line),
            ),
          ),

          if (widget.isOwnProfile)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor,
              ),
              child: LocalAssets(
                imagePath: AppIconAssets.profile_pen_tool,
                imgColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///SELECT IMAGE AND SHOW DIALOG...
  selectImage(BuildContext context,String titleOfDialog) async {
    final appLocalizations = AppLocalizations.of(context);

    widget.imagePath = await SelectProfilePictureDialog.showLogoDialog(
        context, titleOfDialog ?? "");
    if (widget.imagePath?.isNotEmpty ?? false) {
      ///SET IMAGE PATH...
      widget.onImageUpdate(widget.imagePath ?? "");

      setState(() {});
    }
  }
}

CommonCircularImage({required String? url, String? title, double? radius}) {
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: AppColors.primaryColor, // border color
        width: 2.0, // border width
      ),
    ),
    child: CircleAvatar(
      radius: radius ?? 15,
      backgroundColor: Colors.blueGrey.shade100,
      child: ClipOval(
        child: Image.network(
          url ?? "",
          fit: BoxFit.cover,
          width: 60,
          height: 60,
          errorBuilder: (context, error, stackTrace) {
            if (title?.isNotEmpty ?? false) {
              return Center(child: CustomText(title?.substring(0, 1)));
            } else {
              return Center(child: Icon(Icons.person_outline_rounded));
            } // fallback initial or icon
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return CircularProgressIndicator(strokeWidth: 2);
          },
        ),
      ),
    ),
  );
}
