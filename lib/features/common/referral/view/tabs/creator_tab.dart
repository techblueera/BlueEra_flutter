import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/model/creator_program_model.dart';
import 'package:BlueEra/features/common/referral/widgets/add_link_bottom_sheet.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Content-Creator tab (formerly "Post"). One call — `GET /earn-service/creator`
/// — powers the bonus/program card, the "Add Your Links" CTA and the
/// "My Videos" list.
class CreatorTab extends StatefulWidget {
  final ReferralController controller;
  const CreatorTab({super.key, required this.controller});

  @override
  State<CreatorTab> createState() => _CreatorTabState();
}

class _CreatorTabState extends State<CreatorTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  ReferralController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    if (_c.creatorData.value == null) _c.fetchCreator();
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSocialLinkSheet(controller: _c),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      final status = _c.creatorResponse.value.status;
      final data = _c.creatorData.value;

      if ((status == Status.INITIAL || status == Status.LOADING) &&
          data == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (status == Status.ERROR && data == null) {
        return _centerMsg('Oops, something went wrong');
      }

      final creator = data ?? const CreatorData();
      return RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: _c.fetchCreator,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size10,
            SizeConfig.paddingXSL,
            SizeConfig.size10,
            SizeConfig.size20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bonusCard(creator.program, creator.progress),
              SizedBox(height: SizeConfig.paddingM),
              _addYourLinksCard(),
              SizedBox(height: SizeConfig.paddingM),
              _myVideosHeader(),
              SizedBox(height: SizeConfig.paddingXSL),
              _myVideosList(creator.videos),
            ],
          ),
        ),
      );
    });
  }

  Widget _centerMsg(String msg) => Center(
        child: CustomText(msg,
            color: AppColors.secondaryTextColor, fontSize: SizeConfig.small),
      );

  // ── Bonus / program card ─────────────────────────────────────────────
  Widget _bonusCard(CreatorProgram program, CreatorProgress progress) {
    final amount = program.totalAmount;
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomText(
            'Welcome Content Creator',
            textAlign: TextAlign.center,
            fontSize: SizeConfig.extraLarge,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size16),
          // Reward box.
          Container(
            padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size20, horizontal: SizeConfig.size16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FAFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size24,
                      vertical: SizeConfig.size12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.35),
                      width: 1.4,
                    ),
                  ),
                  child: CustomText(
                    '\u{20B9}$amount',
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                  ),
                ),
                SizedBox(height: SizeConfig.size16),
                CustomText(
                  "Yay! You've won",
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size6),
                CustomText(
                  'This will be credited to your wallet. You can use it at the '
                  'time of order payment.',
                  textAlign: TextAlign.center,
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                  height: 1.4,
                ),
              ],
            ),
          ),
          SizedBox(height: SizeConfig.size16),
          GestureDetector(
            onTap: () => _showProgramInfo(program),
            child: Text.rich(
              TextSpan(
                text: 'By Clicking You Accept the ',
                style: TextStyle(
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                ),
                children: [
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: TextStyle(
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          GestureDetector(
            onTap: () => _showProgramInfo(program),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomText(
                'Join Now',
                fontSize: SizeConfig.medium15,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProgramInfo(CreatorProgram program) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                'Creator Program',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
              SizedBox(height: SizeConfig.size4),
              CustomText(
                'Earn ₹${program.perApprovalAmount} per approved video, up to '
                '₹${program.totalAmount}.',
                fontSize: SizeConfig.small,
                color: AppColors.secondaryTextColor,
              ),
              if (program.requirements.isNotEmpty) ...[
                SizedBox(height: SizeConfig.size16),
                _bulletTitle('Requirements'),
                ...program.requirements.map((r) => _bullet(r)),
              ],
              if (program.termsAndConditions.isNotEmpty) ...[
                SizedBox(height: SizeConfig.size16),
                _bulletTitle('Terms & Conditions'),
                ...program.termsAndConditions.map((t) => _bullet(t)),
              ],
              SizedBox(height: SizeConfig.size16),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _openAddSheet();
                },
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomText('Add Your Video',
                      fontSize: SizeConfig.medium15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bulletTitle(String t) => Padding(
        padding: EdgeInsets.only(bottom: SizeConfig.size6),
        child: CustomText(t,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor),
      );

  Widget _bullet(String t) => Padding(
        padding: EdgeInsets.only(bottom: SizeConfig.size8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: CustomText(t,
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                  height: 1.4),
            ),
          ],
        ),
      );

  // ── Add Your Links ───────────────────────────────────────────────────
  Widget _addYourLinksCard() {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size8),
      child: InkWell(
        onTap: _openAddSheet,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryColor, width: 1.2),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link_rounded, color: AppColors.primaryColor, size: 18),
              const SizedBox(width: 8),
              CustomText('Add Your Links',
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  // ── My Videos ────────────────────────────────────────────────────────
  Widget _myVideosHeader() {
    return Row(
      children: [
        CustomText('My Videos',
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor),
        SizedBox(width: SizeConfig.size10),
        Expanded(child: Container(height: 1, color: AppColors.greyE5)),
      ],
    );
  }

  Widget _myVideosList(List<CreatorVideo> videos) {
    if (videos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CustomText(
            'No videos yet — add your first link above.',
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
      itemCount: videos.length,
      separatorBuilder: (_, __) => SizedBox(height: SizeConfig.paddingXSL),
      itemBuilder: (_, i) => _videoCard(videos[i]),
    );
  }

  Future<void> _openVideo(CreatorVideo v) async {
    if (v.url.isEmpty) return;
    final uri = Uri.tryParse(v.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _videoCard(CreatorVideo v) {
    return GestureDetector(
      onTap: () => _openVideo(v),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEF1F8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (v.thumbnail.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: v.thumbnail,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => ColoredBox(color: AppColors.whiteE5),
                      errorWidget: (_, __, ___) => _thumbFallback(),
                    )
                  else
                    _thumbFallback(),
                  Container(color: Colors.black.withValues(alpha: 0.18)),
                  const Center(
                    child: Icon(Icons.play_circle_fill,
                        color: Colors.white, size: 52),
                  ),
                  if (v.platform.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _tag(v.platform.capitalizeFirst ?? v.platform),
                    ),
                  Positioned(top: 8, right: 8, child: _statusChip(v.status)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(SizeConfig.size12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (v.title.trim().isNotEmpty)
                    CustomText(
                      v.title,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (v.creditedAmount > 0) ...[
                    SizedBox(height: SizeConfig.size6),
                    CustomText(
                      'Credited ₹${v.creditedAmount}',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF16A34A),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() => ColoredBox(
        color: AppColors.whiteE5,
        child: Center(
          child: Icon(Icons.videocam_outlined,
              color: AppColors.secondaryTextColor, size: 40),
        ),
      );

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: CustomText(text,
            fontSize: SizeConfig.extraSmall,
            fontWeight: FontWeight.w700,
            color: Colors.white),
      );

  Widget _statusChip(String status) {
    final s = status.toLowerCase();
    late final Color color;
    if (s == 'approved') {
      color = const Color(0xFF16A34A);
    } else if (s == 'rejected') {
      color = AppColors.redB4;
    } else {
      color = const Color(0xFFF59E0B); // pending
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        status.isEmpty ? 'Pending' : (status.capitalizeFirst ?? status),
        fontSize: SizeConfig.extraSmall,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}
