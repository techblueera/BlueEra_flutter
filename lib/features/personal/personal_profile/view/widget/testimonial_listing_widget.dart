import 'package:BlueEra/core/api/model/user_testimonial_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/profile_controller.dart';
import 'package:BlueEra/widgets/channel_profile_header.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TestimonialListingWidget extends StatefulWidget {
  const TestimonialListingWidget(
      {super.key, required this.userId, this.showBorder = true});

  final bool showBorder;
  final String? userId;

  @override
  State<TestimonialListingWidget> createState() =>
      _TestimonialListingWidgetState();
}

class _TestimonialListingWidgetState extends State<TestimonialListingWidget> {
  late VisitProfileController? visitController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<VisitProfileController>()) {
      visitController = Get.find<VisitProfileController>();
    } else {
      visitController = Get.put(VisitProfileController());
    }
    apiCalling();
  }

  apiCalling() async {
    await visitController?.getTestimonialController(userID: widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(widget.showBorder == false ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CustomText(
          //   "Testimonials",
          //   fontSize: SizeConfig.size20,
          //   fontWeight: FontWeight.bold,
          //   color: AppColors.black,
          // ),
          // SizedBox(
          //   height: SizeConfig.size8,
          // ),
          Obx(() {
            if (visitController?.testimonialsList?.value.isEmpty ?? false) {
              {
                return Center(child: CustomText("No testimonial found"));
              }
            }
            if (visitController?.testimonialsList?.value.isNotEmpty ??
                false || true) {
              // if (true) {
              return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: visitController?.testimonialsList?.value.length,
                  itemBuilder: (context, index) {
                    Testimonials data =
                        visitController?.testimonialsList?.value[index] ??
                            Testimonials();
                    return Container(
                      margin: EdgeInsets.only(bottom: SizeConfig.size10),
                      padding: EdgeInsets.all(SizeConfig.size12),
                      decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius:
                              BorderRadius.circular(SizeConfig.size12),
                          border: widget.showBorder == false
                              ? null
                              : Border.all(color: AppColors.whiteDB, width: 2)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              if (data.fromUser?.id == userId) {
                                return;
                              }
                              // if (data.fromUser?.accountType?.toUpperCase() ==
                              //     AppConstants.individual) {
                              //
                              //     Get.to(() => VisitProfileScreen1(authorId: data.fromUser?.id??""));
                              // }
                              // if (data.fromUser?.accountType?.toUpperCase() ==
                              //     AppConstants.business) {
                              //
                              //     Get.to(() => VisitBusinessProfile(businessId: data.fromUser?.id??""));
                              // }
                            },
                            child: Row(
                              children: [
                                // CircleAvatar(
                                //   radius: 20,
                                //   backgroundImage: NetworkImage(
                                //     data.fromUser?.profileImage ?? "",
                                //   ),
                                // ),
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primaryColor,
                                  backgroundImage:
                                      data.fromUser?.profileImage != null
                                          ? NetworkImage(
                                              data.fromUser?.profileImage ?? "")
                                          : null,
                                  child: data.fromUser?.profileImage == null
                                      ? CustomText(
                                          getInitials(
                                              data.fromUser?.name ?? "U"),
                                          fontSize: SizeConfig.size18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                SizedBox(width: SizeConfig.size10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      '${data.fromUser?.name ?? ""}',
                                      fontSize: SizeConfig.size16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                    Row(
                                      children: [
                                        // ...List.generate(
                                        //   5,
                                        //   (index) => Icon(Icons.star,
                                        //       color: AppColors.yellow,
                                        //       size: SizeConfig.size16),
                                        // ),
                                        // SizedBox(width: SizeConfig.size6),
                                        CustomText(
                                          getTimeAgo(data.updatedAt.toString()),
                                          color: AppColors.secondaryTextColor,
                                          fontSize: SizeConfig.size12,
                                        )
                                      ],
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          SizedBox(height: SizeConfig.size10),
                          CustomText(
                            data.description,
                            textAlign: TextAlign.start,
                            fontSize: SizeConfig.size14,
                            color: AppColors.grayText,
                          ),
                          // SizedBox(height: SizeConfig.size10),
                          // Divider(
                          //   height: 8,
                          //   color: AppColors.greyA5,
                          //   thickness: 1,
                          // ),
                          // SizedBox(
                          //   height: SizeConfig.size16,
                          // ),

                          /*    Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: AppColors.borderGray,
                                        width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  height: 50.0,
                                  child: Row(
                                    children: <Widget>[
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundImage: NetworkImage(
                                          data.fromUser?.profileImage ?? "",
                                        ),
                                      ),
                                      Expanded(
                                        child: TextFormField(
                                          textAlign: TextAlign.left,
                                          style: TextStyle(fontSize: 11.0),
                                          decoration: InputDecoration(
                                              disabledBorder:
                                                  InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              focusedErrorBorder:
                                                  InputBorder.none,
                                              suffixIcon:
                                                  Icon(Icons.edit_outlined),
                                              suffixIconConstraints:
                                                  BoxConstraints(),
                                              contentPadding:
                                                  new EdgeInsets.symmetric(
                                                      vertical: 0.0),
                                              border: InputBorder.none,
                                              hintText:
                                                  'Write your comment..',
                                              hintStyle:
                                                  TextStyle(fontSize: 11.0)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: SizeConfig.small,
                              ),
                              InkWell(
                                onTap: () {},
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppColors.borderGray,
                                            width: 2)),
                                    height: 50,
                                    width: 50,
                                    child: Image.asset(
                                        "assets/images/share.png")),
                              )
                            ],
                          ),*/
                        ],
                      ),
                    );
                  });
            }
            return SizedBox();
          }),
        ],
      ),
    );
  }
}
