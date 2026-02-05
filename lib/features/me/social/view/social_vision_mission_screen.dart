import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/personal/resume/controller/add_more_controller.dart';
import 'package:BlueEra/widgets/ai_description_field_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_document_picker.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialVisionMissionScreen extends StatefulWidget {
  final bool isEdit;
  final String? experienceId;

  const SocialVisionMissionScreen(
      {Key? key, this.isEdit = false, this.experienceId})
      : super(key: key);

  @override
  State<SocialVisionMissionScreen> createState() =>
      _SocialVisionMissionScreenState();
}

class _SocialVisionMissionScreenState extends State<SocialVisionMissionScreen> {
  final descCtrl = TextEditingController();
  String? imagePath;
  RxString descriptionTxt = "".obs;
  bool validate = false;

  bool isValidDate(int? day, int? month, int? year) {
    if (day == null || month == null || year == null) return false;
    try {
      final date = DateTime(year, month, day);
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      return !date.isAfter(todayOnly);
    } catch (e) {
      return false;
    }
  }

  // final EntityController ngoController = Get.find<EntityController>(tag: "ngo");
  final ngoController = getOrPut(() => EntityController(isPatent: false));

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.experienceId != null) {
      final existing = ngoController.entityList
          .firstWhereOrNull((e) => e['_id'] == widget.experienceId);
      if (existing != null) {
        descCtrl.text = existing['subtitle2'] ?? '';

        final docs = (existing['document'] as List<dynamic>?)?.cast<String>();
        if (docs != null && docs.isNotEmpty) imagePath = docs.first;
      }
    }

    validateForm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CommonBackAppBar(
            title: widget.isEdit ? "Vision & Mission" : "Vision & Mission"),
        body: SingleChildScrollView(
            child: SafeArea(
                child: CommonCardWidget(
          padding: 0,
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
              child: Column(children: [
                AiDescriptionField(
                  label: "Our Vision & Mission",
                  hintText: "Share Your Vision & Mission...",
                  controller: descCtrl,
                  rxValue: descriptionTxt,
                  aiType: "vision mission",
                  aiData: {"title": "vision mission"},
                ),
                SizedBox(height: SizeConfig.size20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomText("Upload Photos Or Videos",
                      color: AppColors.black1A,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400),
                ),
                SizedBox(height: SizeConfig.size8),
                CommonDocumentPicker(
                  imagePath: imagePath,
                  onClear: () {
                    setState(() {
                      imagePath = null;
                    });
                    validateForm();
                  },
                  onSelect: (context) {
                    selectImage(context);
                  },
                ),
                SizedBox(height: SizeConfig.size15),
                CustomBtn(
                  //...
                  onTap: validate
                      ? () async {
                          final params = {
                            'description': descCtrl.text.trim(),
                          };
                          if (widget.isEdit && widget.experienceId != null) {
                            await ngoController.updateEntity(
                                widget.experienceId!, params,
                                imagePath: imagePath);
                          } else {
                            await ngoController.addEntity(params,
                                imagePath: imagePath);
                          }
                          Navigator.pop(context);
                        }
                      : null,
                  title: widget.isEdit ? AppStrings.update : AppStrings.save,
                  isValidate: validate,
                ),
                SizedBox(height: SizeConfig.size20),
              ])),
        ))));
  }

  void validateForm() {
    final valid = descCtrl.text.isNotEmpty && (imagePath?.isNotEmpty ?? false);

    setState(() {
      validate = valid;
    });
  }

  void selectImage(BuildContext context) async {
    imagePath = await SelectProfilePictureDialog.showLogoDialog(
        context, AppStrings.uploadYourDocumentPhoto);
    if (imagePath?.isNotEmpty ?? false) {
      validateForm();
    }
  }
}
