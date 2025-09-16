import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile.dart';
import 'package:BlueEra/features/business/visiting_card/view/business_own_profile_screen.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/profile_setup_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_draggable_bottom_sheet.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FeedTagPeopleBottomSheet extends StatelessWidget {
  final List<User> taggedUser;

  const FeedTagPeopleBottomSheet({super.key, required this.taggedUser});

  @override
  Widget build(BuildContext context) {
    return CommonDraggableBottomSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      backgroundColor: AppColors.white,
      builder: (scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            // Title
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      'In this post',
                      color: AppColors.mainTextColor,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w600,
                    ),

                    // Close Button
                    Padding(
                      padding: EdgeInsets.only(right: SizeConfig.size10),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(
                            Icons.close,
                            size: SizeConfig.size20,
                            color: AppColors.black,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
              child: CommonHorizontalDivider(
                color: AppColors.secondaryTextColor,
                height: 0.5,
              ),
            ),

            const SizedBox(height: 10),

            (taggedUser.isNotEmpty)
                ? Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: taggedUser.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final user = taggedUser[index];
                        String profileImage = user.profileImage ?? '';
                        String name =
                            (user.accountType == AppConstants.individual)
                                ? user.name ?? ''
                                : user.username ?? '';
                        String designation =
                            (user.accountType == AppConstants.individual)
                                ? user.designation ?? ''
                                : user.businessName ?? '';

                        return InkWell(
                          onTap: () {
                            redirectToProfileScreen(accountType: user.accountType??"", profileId: user.id??"");

                          },
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: SizeConfig.size15,
                                vertical: SizeConfig.size5),
                            leading: CachedAvatarWidget(
                              imageUrl: profileImage,
                              size: SizeConfig.size45,
                              borderRadius: SizeConfig.size30,
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.black1F,
                                    offset: Offset(0, 2))
                              ],
                            ),
                            title: CustomText(
                              name,
                              fontSize: SizeConfig.medium,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                            subtitle: CustomText(
                              designation,
                              fontSize: SizeConfig.medium,
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400,
                            ),
                            // trailing: CustomBtn(
                            //   onTap: () {},
                            //   height: SizeConfig.size30,
                            //   width: SizeConfig.size70,
                            //   bgColor: AppColors.primaryColor,
                            //   borderColor: Colors.transparent,
                            //   title: "Follow",
                            // ),
                          ),
                        );
                      },
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.only(top: SizeConfig.size40),
                    child: Center(
                      child: CustomText(
                        'No Tagged user',
                        fontSize: SizeConfig.extraLarge,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
          ],
        );
      },
    );
  }
}
