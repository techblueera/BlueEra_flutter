import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/testimonial_listing_widget.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TestimonialsScreen extends StatefulWidget {
  final String? userName, visitUserID;
  final bool? isSelfTestimonial;

  const TestimonialsScreen({super.key, this.userName, this.visitUserID,required this.isSelfTestimonial});

  @override
  State<TestimonialsScreen> createState() => _TestimonialsScreenState();
}

class _TestimonialsScreenState extends State<TestimonialsScreen> {
  final titleTextEditController = TextEditingController();
  final contentTextEditController = TextEditingController();
  bool isValidate = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            if(widget.isSelfTestimonial==false)...[
              CommonCardWidget(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                              fontFamily: AppConstants.OpenSans),
                          children: [
                            TextSpan(
                              text: 'Write a Testimonial for ',
                            ),
                            TextSpan(
                              text: widget.userName,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                  fontFamily: AppConstants.OpenSans),
                            ),
                            TextSpan(
                              text: ' 🌟 ✍️',
                              style: TextStyle(
                                  fontSize: 16, fontFamily: AppConstants.OpenSans),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.size20,
                      ),
                      CommonTextField(
                        textEditController: titleTextEditController,
                        hintText: "Testimonial Title (e.g., Supportive Team...",
                        isValidate: false,

                        onChange: (value) {
                          isTextFieldValidate();
                        },
                      ),
                      SizedBox(
                        height: SizeConfig.size15,
                      ),
                      CommonTextField(
                        textEditController: contentTextEditController,
                        maxLine: 5,
                        isValidate: false,
                        maxLength: 200,
                        onChange: (value) {
                          isTextFieldValidate();
                        },
                        hintText:
                        "Write a few words about their personality, behavior, or how it was working with them...",
                      ),
                      SizedBox(
                        height: SizeConfig.size15,
                      ),
                      CustomBtn(
                          isValidate: isValidate,
                          onTap: isValidate
                              ? () async {
                            if (isGuestUser()) {
                              createProfileScreen();
                            } else {

                            await Get.find<VisitProfileController>()
                                .addTestimonialController(bodyReq: {
                              ApiKeys.title: titleTextEditController.text,
                              ApiKeys.description: contentTextEditController.text,
                              ApiKeys.toUser: widget.visitUserID,
                            });
                            resetFiled();
                          }
                          }
                              : null,
                          title: "Add Testimonial"),
                      SizedBox(
                        height: SizeConfig.size5,
                      ),
                    ],
                  )),
              SizedBox(height: SizeConfig.size10,),
            ],

            TestimonialListingWidget(
              userId: widget.visitUserID,
              showBorder: false,
            ),
            SizedBox(height: SizeConfig.size30,),

          ],
        ),
      ),
    );
  }

  isTextFieldValidate() {
    if (titleTextEditController.text.isNotEmpty &&
        contentTextEditController.text.isNotEmpty) {
      isValidate = true;
    } else {
      isValidate = false;
    }

    setState(() {});
  }

  ///RESET...
  resetFiled() {
    isValidate = false;
    titleTextEditController.clear();
    contentTextEditController.clear();
    setState(() {});
  }
}
