import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/widgets/add_link_bottom_sheet.dart';
import 'package:BlueEra/features/common/referral/widgets/admin_post_card.dart';
import 'package:BlueEra/features/common/referral/widgets/post_empty_state.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostTab extends StatefulWidget {
  final ReferralController controller;
  const PostTab({super.key, required this.controller});

  @override
  State<PostTab> createState() => _PostTabState();
}

class _PostTabState extends State<PostTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.controller.userPosts.isEmpty) {
      widget.controller.fetchUserPosts();
    }
  }

  void _openAddSheet() {
    // Pause any background admin-post videos before showing the sheet —
    // the active VideoPlayer otherwise keeps the codec busy and the
    // bottom sheet's keystroke / paste handling skips frames.
    pauseAllAdminPostVideos();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSocialLinkSheet(controller: widget.controller),
    );
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
          _sectionHeading('Welcome Content Creator'),
          SizedBox(height: SizeConfig.paddingXSL),
          _welcomeCard(),
          SizedBox(height: SizeConfig.paddingM),
          _sectionHeading('My Videos'),
          SizedBox(height: SizeConfig.paddingXSL),
          _myVideosList(),
        ],
      ),
    );
  }

  Widget _sectionHeading(String text) {
    return CustomText(
      text,
      fontSize: SizeConfig.large,
      fontWeight: FontWeight.w700,
      color: AppColors.mainTextColor,
    );
  }

  Widget _welcomeCard() {
    return CustomFormCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const HorizontalVideoPlayer(isAutoPlay: false),
          ),
          const SizedBox(height: 10),
          _addYourLinksButton(),
        ],
      ),
    );
  }

  /// Outlined "🔗 Add Your Links" CTA tucked inside the welcome card —
  /// triggers [AddSocialLinkSheet] which POSTs the URL to the admin-
  /// posts endpoint and re-fetches the My Videos list on success.
  Widget _addYourLinksButton() {
    return InkWell(
      onTap: _openAddSheet,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primaryColor, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_rounded,
                color: AppColors.primaryColor, size: 18),
            const SizedBox(width: 8),
            CustomText(
              'Add Your Links',
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _myVideosList() {
    return Obx(() {
      final status = widget.controller.userPostsResponse.value.status;
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
      final items = widget.controller.userPosts;
      if (items.isEmpty) {
        return const PostEmptyState();
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
    });
  }
}
