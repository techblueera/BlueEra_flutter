
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/add_documents_screen/add_documents_controller.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddDocumentScreen extends StatelessWidget {
  const AddDocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AddDocumentsController>(
        init: AddDocumentsController(),
        builder: (Controller) {
          return Scaffold(
            appBar: CommonBackAppBar(
              title: AppStrings.addDocuments,
              isLeading: true,
            ),
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(SizeConfig.size20),
                  decoration: BoxDecoration(
                    color: AppColors.fillColor,
                    borderRadius: BorderRadius.circular(SizeConfig.size12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      CommonTextField(
                        title:   AppStrings.documentName,
                        textEditController: Controller.documentNameController,
                        hintText:AppStrings.documentNameHint,
                        keyBoardType: TextInputType.text,
                        // validator: controller.validateBankHolderName,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size16,
                          vertical: SizeConfig.size12,
                        ),
                        borderColor: AppColors.greyE5,
                        borderWidth: 1,
                      ),
                      SizedBox(height: SizeConfig.size16),
                      CustomText(
                        AppStrings.shareDocument,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black,
                      ),
                      SizedBox(height: SizeConfig.size8),
                      Container(

                        height: SizeConfig.size55,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            // border: Border.all(color: AppColors.grey17),
                            boxShadow: [AppShadows.textFieldShadow],
                            color: AppColors.white),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:  [
                            Icon(Icons.ios_share,color:Color(0xff505050),size: 20,),
                            SizedBox(width: 5,),
                            // 505050
                            CustomText(  AppStrings.shareMediaFile,)],
                        ),
                      ),
                      SizedBox(height: SizeConfig.size80),
                      CustomBtn(
                        onTap: () {},
                        title:   AppStrings.add,
                        bgColor: AppColors.primaryColor,
                        textColor: AppColors.white,
                        radius: SizeConfig.size8,
                        height: SizeConfig.buttonXL,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.bold,
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }
}
