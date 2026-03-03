import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/doc_verification_pending_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:get/get.dart';

import '../view/add_document_screen.dart';

class BuildAddDocumentButton extends StatelessWidget {
  final String title;
  final String documentKey;
  final String? document;
  final dynamic status;
  final bool? showViewDocProof;
  final VoidCallback onTap;

  const BuildAddDocumentButton({
    super.key,
    required this.title,
    required this.documentKey,
    required this.status,
    required this.onTap,
    this.showViewDocProof,
    this.document
  });

  @override
  Widget build(BuildContext context) {
    bool isUploadable = status == DocStatus.notUploaded;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextButton(
            onPressed: status == DocStatus.verified
                ? null
                : () {
              if (status == DocStatus.pending) {
                _showPendingInstructionDialog(documentKey);
              } else {
                onTap();
              }
            },
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                (!isUploadable)
                    ? status == DocStatus.verified
                    ? LocalAssets(
                  imagePath: AppIconAssets.green_tick_icon,
                  height: 20,
                  width: 20,
                )
                    : LocalAssets(
                  imagePath: AppIconAssets.storeWatch,
                  imgColor: AppColors.yellow,
                  height: 20,
                  width: 20,
                )
                    : Icon(
                  CupertinoIcons.add,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                SizedBox(width: SizeConfig.size8),
                Flexible(
                  child: CustomText(
                    title,
                    color: isUploadable
                        ? AppColors.primaryColor
                        : AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                    fontSize: SizeConfig.large,
                  ),
                ),

              ],
            ),
          ),
        ),
        if(showViewDocProof??false)
          if(!isUploadable)
            InkWell(
              onTap: () {
                AddDocumentScreen.showDocumentProofDialog(context, document??'');
              },
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.primaryColor
                      )

                  ),
                  child: Row(
                    children: [
                      Icon(Icons.remove_red_eye,color: AppColors.primaryColor,size: 16,),
                      SizedBox(width: 6,),
                      CustomText("View", color: AppColors.primaryColor)
                    ],
                  )),
            ),
      ],
    );
  }

  void _showPendingInstructionDialog(String document) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size20),
          child: DocumentVerificationPendingWidget(
            documentName: document,
          ),
        ),
      ),
    );
  }
}