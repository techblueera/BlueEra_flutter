import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessRatingsBottomSheet extends StatefulWidget {
  final String businessId;
  const BusinessRatingsBottomSheet({super.key, required this.businessId});

  @override
  State<BusinessRatingsBottomSheet> createState() =>
      _BusinessRatingsBottomSheetState();
}

class _BusinessRatingsBottomSheetState
    extends State<BusinessRatingsBottomSheet> {
  final ViewBusinessDetailsController viewBusinessDetailsController =
      Get.find<ViewBusinessDetailsController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    viewBusinessDetailsController
        .getBusinessDetailedRatings(widget.businessId);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final controller = viewBusinessDetailsController;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!controller.isBusinessRatingsLoadingMore.value &&
          controller.businessRatingsHasMore) {
        controller.getBusinessDetailedRatings(widget.businessId,
            isLoadMore: true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE9ECEF),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(
        top: SizeConfig.size10,
        bottom: SizeConfig.size12,
        left: SizeConfig.size16,
        right: SizeConfig.size8,
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              height: 4,
              width: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFCED4DA),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.size14),
          // Title row with summary + close
          Row(
            children: [
              Icon(
                Icons.reviews_rounded,
                size: 20,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: SizeConfig.size8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      'Ratings & Reviews',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(height: SizeConfig.size2),
                    Obx(() {
                      final count = viewBusinessDetailsController
                          .businessRatingsList.length;
                      if (count == 0) return const SizedBox.shrink();
                      return CustomText(
                        '$count ${count == 1 ? 'review' : 'reviews'}',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                      );
                    }),
                  ],
                ),
              ),
              _CloseButton(onTap: () => Navigator.of(context).pop()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      final controller = viewBusinessDetailsController;

      if (controller.isBusinessRatingsFirstLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final ratings = controller.businessRatingsList;
      if (ratings.isEmpty) {
        return EmptyStateWidget(message: AppStrings.noRatingsFound);
      }

      return ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size16,
          SizeConfig.size14,
          SizeConfig.size16,
          SizeConfig.size20,
        ),
        itemCount: ratings.length +
            (controller.isBusinessRatingsLoadingMore.value ? 1 : 0),
        separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
        itemBuilder: (context, index) {
          if (index >= ratings.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final review = ratings[index];
          final isBusiness = review.user?.accountType?.toUpperCase() ==
              AppConstants.business.toUpperCase();

          final String name = isBusiness
              ? (review.user?.businessDetails?.isNotEmpty == true
                  ? review.user!.businessDetails!.first.businessName ?? ''
                  : 'Unknown User')
              : (review.user?.username ?? '');

          final String profilePhoto = isBusiness
              ? (review.user?.businessDetails?.isNotEmpty == true
                  ? review.user!.businessDetails!.first.logo ?? ''
                  : '')
              : (review.user?.profileImage ?? '');

          return ReviewCard(
            name: name,
            avatarUrl: profilePhoto,
            rating: review.rating ?? 0,
            timeAgo: review.createdAt != null
                ? timeAgo(DateTime.parse(review.createdAt!))
                : timeAgo(DateTime.now()),
            comment: review.comment ?? '',
          );
        },
      );
    });
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE9ECEF)),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: AppColors.secondaryTextColor,
          ),
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final int rating;
  final String timeAgo;
  final String comment;

  const ReviewCard({
    Key? key,
    required this.name,
    required this.avatarUrl,
    required this.rating,
    required this.timeAgo,
    required this.comment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E4E8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: avatar + name + rating pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF1F3F5),
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? Icon(
                        Icons.person_rounded,
                        color: AppColors.secondaryTextColor,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      name,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    CustomText(
                      timeAgo,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ),
              _RatingPill(rating: rating),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            CustomText(
              comment,
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: AppColors.mainTextColor,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final int rating;
  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.yellow.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 18, color: AppColors.yellow),
          const SizedBox(width: 4),
          CustomText(
            '$rating',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.yellowBC,
          ),
        ],
      ),
    );
  }
}
