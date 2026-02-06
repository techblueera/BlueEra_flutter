import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/size_config.dart';
import '../../../../widgets/common_back_app_bar.dart';
import '../../../../widgets/commom_textfield.dart';
import '../../../../widgets/custom_btn.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../../common/delivery_partner/widget/common_image_upload_section.dart';

class SocialActivityForm extends StatefulWidget {
  const SocialActivityForm({super.key});

  @override
  State<SocialActivityForm> createState() => _SocialActivityFormState();
}

class _SocialActivityFormState extends State<SocialActivityForm> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final activityTypeController = TextEditingController();
  final locationController = TextEditingController();
  final roleController = TextEditingController();
  final organizerController = TextEditingController();
  final beneficiaryController = TextEditingController();

  File? imageFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonBackAppBar(
        title: "Social Activity",
        isShadowShow: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.whiteE5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                "Upload Photo/Video",
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w400,
                color: AppColors.mainTextColor,
              ),
              const SizedBox(height: 10),
              CommonImageUploadTile(
                title: "Upload Photos",
                imageFile: Rxn<File>(imageFile),
                context: context,
                onImageSelected: () async {
                  final path =
                  await CommonImageUploadTile.pickImage(context: context);
                  if (path != null) {
                    setState(() => imageFile = File(path));
                  }
                },
                onImageRemove: () {
                  setState(() => imageFile = null);
                },
              ),

              const SizedBox(height: 20),

              CommonTextField(
                title: "Activity Title",
                hintText: "E.g. Free Health Check-up Camp",

                textEditController: titleController,
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w400,
                titleColor:AppColors.mainTextColor,

              ),

              const SizedBox(height: 20),

              CommonTextField(
                title: "Description of Message",
                hintText: "Free medicines & doctor consultation",
                textEditController: descController,
                maxLine: 4,
                maxLength: 140,
                keyBoardType: TextInputType.multiline,
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w400,
                titleColor:AppColors.mainTextColor,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: CustomText(
                  "${descController.text.length}/140",
                  fontSize: 12,
                  color: AppColors.mainTextColor,
                ),
              ),

              const SizedBox(height: 20),

              CommonTextField(
                title: "Activity Type",
                hintText: "E.g. Community Service",
                textEditController: activityTypeController,
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w400,
                titleColor:AppColors.mainTextColor,
              ),

              const SizedBox(height: 20),

              CustomText("Date",
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w400,
                color:AppColors.mainTextColor,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _dateBox("DD"),
                  const SizedBox(width: 8),
                  _dateBox("MM"),
                  const SizedBox(width: 8),
                  _dateBox("YYYY"),
                ],
              ),

              const SizedBox(height: 20),

              CommonTextField(
                title: "Location",
                hintText: "E.g. Community Service",
                textEditController: locationController,
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w400,
                titleColor:AppColors.mainTextColor,
              ),

              const SizedBox(height: 20),

              CommonTextField(
                title: "Your Role",
                hintText: "E.g. Organizer, Chief Guest",
                textEditController: roleController,
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w400,
                titleColor:AppColors.mainTextColor,
              ),

              const SizedBox(height: 20),

              CommonTextField(
                title: "Organizer Name",
                hintText: "E.g. Organizer, Chief Guest",
                textEditController: organizerController,
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w400,
                titleColor:AppColors.mainTextColor,
              ),

              const SizedBox(height: 20),


              CommonTextField(
                title: "Beneficiaries/Impact (Forecast)",
                hintText:
                "E.g. 80 villagers / 1.2K People / 99 KM Area",
                textEditController: beneficiaryController,
                maxLength: 140,
                fontSize: SizeConfig.size12,
                fontWeight: FontWeight.w400,
                titleColor:AppColors.mainTextColor,
              ),

              const SizedBox(height: 30),

              CustomBtn(
                title: "Continue",
                onTap: () {
                },
                isValidate: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateBox(String hint) {
    return Expanded(
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.whiteE5),
        ),
        child: CustomText(
          hint,
          color: Colors.grey,
        ),
      ),
    );
  }
}
