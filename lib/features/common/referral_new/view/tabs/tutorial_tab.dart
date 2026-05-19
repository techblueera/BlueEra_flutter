import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral_new/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral_new/widgets/admin_post_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Tutorial tab — vertical list of admin-post cards loaded from
/// `GET /earn-service/admin-posts?type=tutorial`. Uses the same
/// AdminPostCard the Overview tab uses, so the visual language stays
/// consistent across the dashboard.
class TutorialTab extends StatefulWidget {
  final ReferralControllerNew controller;
  const TutorialTab({super.key, required this.controller});

  @override
  State<TutorialTab> createState() => _TutorialTabState();
}

class _TutorialTabState extends State<TutorialTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.controller.tutorialPosts.isEmpty) {
      widget.controller.fetchTutorials();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size10,
        SizeConfig.paddingXSL,
        SizeConfig.size10,
        SizeConfig.size20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final status = widget.controller.tutorialsResponse.value.status;
            if (status == Status.INITIAL || status == Status.LOADING) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (status == Status.ERROR) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CustomText(
                    'Oops, something went wrong',
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.small,
                  ),
                ),
              );
            }
            final items = widget.controller.tutorialPosts;
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CustomText(
                    'No tutorials yet.',
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.small,
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  SizedBox(height: SizeConfig.paddingXSL),
              itemBuilder: (_, i) => AdminPostCard(post: items[i]),
            );
          }),
        ],
      ),
    );
  }
}
