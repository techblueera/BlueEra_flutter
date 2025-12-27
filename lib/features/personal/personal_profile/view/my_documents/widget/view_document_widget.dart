import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ViewDocumentWidget extends StatelessWidget {
  final Document document;

  ViewDocumentWidget({super.key, required this.document});

  // final controller = getOrPut(() => MyDocumentsController());

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(SizeConfig.size5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: AppColors.white,
                border: Border.all(
                  color: AppColors.greyE5
                ),
                boxShadow: [AppShadows.textFieldShadow]
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: CachedNetworkImage(
                  imageUrl: document.filePath,
                  fit: BoxFit.cover,
                  width: SizeConfig.screenWidth,
                  height: SizeConfig.size220,
                  placeholder: (context, url) =>  LocalAssets(
                    imagePath: AppIconAssets.place_holder_image,
                    boxFix: BoxFit.fill,
                  ),
                  errorWidget: (context, url, error) =>
                      LocalAssets(
                        imagePath: AppIconAssets.place_holder_image,
                        boxFix: BoxFit.fill,
                      ),
                ),
              ),
            )

          ],
        ));
  }
}
