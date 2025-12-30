import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/model/upload_document_response.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ViewDocumentWidget extends StatelessWidget {
  final DocumentsResponse document;

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
              child: document.files != null ? Builder(
                builder: (BuildContext context) {
                final validImages = [
                  if (document.files?.front != null && document.files!.front!.isNotEmpty)
                    document.files!.front!,

                  if (document.files?.back != null && document.files!.back!.isNotEmpty)
                    document.files!.back!,
                ];

                return InkWell(
                  onTap: () {
                    if (validImages.isNotEmpty) {
                      Get.to(() => ImageViewScreen(
                        appBarTitle: document.documentType ?? '',
                        imageUrls: validImages,
                        initialIndex: 0,
                      ));
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: CustomImageSlideshow(
                      isLoading: false,
                      width: SizeConfig.screenWidth,
                      height: SizeConfig.size220,
                      imagePaths: validImages,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                );
               }
              ) :  LocalAssets(
                  imagePath: AppIconAssets.place_holder_image,
                width: SizeConfig.screenWidth,
                height: SizeConfig.size220,
                boxFix: BoxFit.cover,
              ),
            )
          ],
        ));
  }
}
