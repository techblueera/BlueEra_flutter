import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessRatingsBottomSheet extends StatefulWidget {
  final String businessId;
  const BusinessRatingsBottomSheet({super.key, required this.businessId});

  @override
  State<BusinessRatingsBottomSheet> createState() => _BusinessRatingsBottomSheetState();
}

class _BusinessRatingsBottomSheetState extends State<BusinessRatingsBottomSheet> {
  final ViewBusinessDetailsController viewBusinessDetailsController = Get.find<ViewBusinessDetailsController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    viewBusinessDetailsController.getBusinessDetailedRatings(widget.businessId);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final controller = viewBusinessDetailsController;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!controller.isBusinessRatingsLoadingMore.value && controller.businessRatingsHasMore) {
        controller.getBusinessDetailedRatings(widget.businessId, isLoadMore: true);
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
        initialChildSize: 0.6,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController){
          return Obx((){
            final controller = viewBusinessDetailsController;

            if (controller.isBusinessRatingsFirstLoading.value) {
              return Container(
                  decoration: BoxDecoration(
                    color: AppColors.whiteF3,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: EdgeInsets.only(
                    left: SizeConfig.size15,
                    right: SizeConfig.size15,
                    top: SizeConfig.size30,
                    bottom: SizeConfig.size15,
                  ),
                  child: const Center(child: CircularProgressIndicator()));
            }

            final ratings = controller.businessRatingsList;
            
            return Container(
              decoration: BoxDecoration(
                color: AppColors.whiteF3,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: SizeConfig.size15,
                right: SizeConfig.size15,
                top: SizeConfig.size30,
                bottom: SizeConfig.size15,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 2,
                        width: 60,
                        color: AppColors.secondaryTextColor,
                      )
                    ],
                  ),
                  SizedBox(height: SizeConfig.size20),
                  Expanded(
                    child: ratings.isNotEmpty ? ListView.builder(
                      controller: _scrollController,
                      itemCount: ratings.length + (controller.isBusinessRatingsLoadingMore.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= ratings.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final review = ratings[index];
                        final isBusiness = review.user?.accountType?.toUpperCase() == AppConstants.business.toUpperCase();

                        final String name = isBusiness
                            ? (review.user?.businessDetails?.isNotEmpty == true
                            ? review.user!.businessDetails!.first.businessName ?? ''
                            : 'Unknown User')
                            : (review.user?.username ?? '');

                        final String profilePhoto = isBusiness
                            ? (review.user?.businessDetails?.isNotEmpty == true
                            ? review.user!.businessDetails!.first.logo ?? ''
                            : 'Unknown User')
                            : (review.user?.profileImage ?? '');
                        return ReviewCard(
                          name: name,
                          avatarUrl: profilePhoto,
                          rating: review.rating ?? 0,
                          timeAgo: review.createdAt!= null
                              ? timeAgo(DateTime.parse(review.createdAt!))
                              : timeAgo(DateTime.now()),
                          comment: review.comment ?? ''
                        );
                      },
                    ) : EmptyStateWidget(
                        message: AppStrings.noRatingsFound
                    ),
                  ),
                ],
              ),
            );
          });
        }
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      name,
                      fontSize: SizeConfig.large,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          size: SizeConfig.size18,
                          color: AppColors.yellow,
                        )),
                        const SizedBox(width: 6),
                        CustomText(
                          timeAgo,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CustomText(
            comment,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }
}
