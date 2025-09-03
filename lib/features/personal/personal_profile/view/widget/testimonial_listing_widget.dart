import 'package:BlueEra/core/api/model/user_testimonial_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
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
    // TODO: implement initState
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
    return Obx(() {
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
                  visitController?.testimonialsList?[index] ?? Testimonials();
              return Padding(
                padding: EdgeInsets.only(bottom: SizeConfig.size5),
                child: CommonCardWidget(
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
                        child: ChannelProfileHeader(
                          imageUrl: data.fromUser?.profileImage ?? "",
                          title: '@${data.fromUser?.name ?? ""}',
                          subtitle: data.fromUser?.designation ?? "",
                          avatarSize: SizeConfig.size42,
                          borderColor: AppColors.primaryColor,
                        ),
                      ),
                      SizedBox(
                        height: SizeConfig.size10,
                      ),
                      CustomText(
                        data.title,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(
                        height: SizeConfig.size10,
                      ),
                      CustomText(data.description),
                      SizedBox(
                        height: SizeConfig.size10,
                      ),

                      // PostAuthorHeader(post: Post(id: ,user: User(username: username,)), authorId: authorId, postFilteredType: postFilteredType)
                    ],
                  ),
                ),
              );
            });
      }
      return SizedBox();
    });
  }
}
