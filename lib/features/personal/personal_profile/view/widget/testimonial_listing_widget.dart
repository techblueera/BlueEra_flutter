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
  const TestimonialListingWidget({super.key, required this.userId});

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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.size16),
      ),
      elevation: SizeConfig.size4,
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              "Testimonials",
              fontSize: SizeConfig.size20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
            SizedBox(
              height: SizeConfig.size8,
            ),
            Obx(() {
              if (visitController?.testimonialsList?.isEmpty ?? false) {
                {
                  return Center(child: CustomText("No testimonial found"));
                }
              }
              if (visitController?.testimonialsList?.isNotEmpty ?? false) {
                return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: visitController?.testimonialsList?.length,
                    itemBuilder: (context, index) {
                      Testimonials data =
                          visitController?.testimonialsList?[index] ??
                              Testimonials();
                      return Container(
                        padding: EdgeInsets.all(SizeConfig.size12),
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(SizeConfig.size12),
                            border:
                                Border.all(color: AppColors.whiteDB, width: 2)),
                        child: Column(
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
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage: NetworkImage(
                                      data.fromUser?.profileImage ?? "",
                                    ),
                                  ),
                                  SizedBox(width: SizeConfig.size10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomText(
                                        '@${data.fromUser?.name ?? ""}',
                                        fontSize: SizeConfig.size16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      Row(
                                        children: [
                                          ...List.generate(
                                            5,
                                            (index) => Icon(Icons.star,
                                                color: AppColors.yellow,
                                                size: SizeConfig.size16),
                                          ),
                                          SizedBox(width: SizeConfig.size6),
                                          CustomText(
                                            getTimeAgo(
                                                data.updatedAt.toString()),
                                            color: AppColors.coloGreyText,
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
                              fontSize: SizeConfig.size14,
                              color: AppColors.grayText,
                            ),
                            SizedBox(height: SizeConfig.size10),
                            Divider(
                              height: 8,
                              color: AppColors.greyA5,
                              thickness: 1,
                            ),
                            SizedBox(
                              height: SizeConfig.size16,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  children: const [
                                    CustomText("5K+"),
                                    SizedBox(width: 6),
                                    Icon(Icons.thumb_up_alt,
                                        color: AppColors.skyBlueDF),
                                  ],
                                ),
                                SizedBox(
                                    height: SizeConfig.size24,
                                    child: VerticalDivider(
                                      color: AppColors.coloGreyText,
                                      width: 2,
                                      thickness: 1,
                                    )),
                                Row(
                                  children: const [
                                    CustomText("310"),
                                    SizedBox(width: 6),
                                    Icon(Icons.comment_outlined,
                                        color: AppColors.coloGreyText),
                                  ],
                                ),
                                SizedBox(
                                    height: SizeConfig.size24,
                                    child: VerticalDivider(
                                      color: AppColors.coloGreyText,
                                      width: 2,
                                      thickness: 1,
                                    )),
                                Row(
                                  children: const [
                                    Text("50"),
                                    SizedBox(width: 6),
                                    Icon(Icons.ios_share,
                                        color: AppColors.coloGreyText),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    });
              }
              return SizedBox();
            }),
          ],
        ),
      ),
    );
  }
}
