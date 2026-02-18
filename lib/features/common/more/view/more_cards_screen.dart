import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/more/controller/more_cards_screen_controller.dart';
import 'package:BlueEra/features/common/more/widget/home_screen_card.dart';
import 'package:BlueEra/features/common/more/model/card_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:BlueEra/features/common/visiting_card/helper/visiting_card_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MoreCardsScreen extends StatefulWidget {
  final bool isFromHomeScreen;
  final double? headerHeight;
  final Function(bool)? onHeaderVisibilityChanged;
  const MoreCardsScreen({super.key, required this.isFromHomeScreen, this.headerHeight, this.onHeaderVisibilityChanged});

  @override
  State<MoreCardsScreen> createState() => _MoreCardsScreenState();
}

class _MoreCardsScreenState extends State<MoreCardsScreen> {
  final MoreCardsScreenController moreCardsScreenController = Get.find<MoreCardsScreenController>();
  final ScrollController _scrollController = ScrollController();

  /// Keys for capturing widget images (per card → per photo)
  final List<GlobalKey> _cardKeys = [];

  @override
  void initState() {
    super.initState();
    moreCardsScreenController.getAllCards();
    // moreCardsScreenController.getAllCardCategories();
  }

  /// Build keys & trackers for each card
  void _generateKeys(List cards) {
    _cardKeys
      ..clear()
      ..addAll(List.generate(cards.length, (_) => GlobalKey()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: !(widget.isFromHomeScreen) ? CommonBackAppBar(
        title: 'More Cards',
        buildCustomWidget: () => _cardCategory(),
      ) : null,
      body: Obx(() {
        if (moreCardsScreenController.isLoading.isTrue) {
          return const Center(child: CircularProgressIndicator());
        }

        // final response = moreCardsScreenController.allCardCategoriesResponse.value;
        final response = moreCardsScreenController.daysRangeAllCardCategoriesResponse.value;

        if (response.status == Status.COMPLETE) {
          final cards = moreCardsScreenController.filteredDaysRangeAllCards;

          _generateKeys(cards);

          if (cards.isEmpty) {
            return const EmptyStateWidget(message: 'No cards available.');
          }

          return setupScrollVisibilityNotification(
            controller: _scrollController,
            headerHeight: (widget.headerHeight ?? SizeConfig.size100),
            onVisibilityChanged: (visible, offset) {
              final controller = Get.find<HomeScreenController>();
              final currentOffset = controller.headerOffset.value;

              // Linear animation step (same speed up/down)
              const step = 0.25;

              double newOffset = currentOffset;
              if (visible) {
                // show header
                newOffset = (currentOffset - step).clamp(0.0, 1.0);
              } else {
                // hide header
                newOffset = (currentOffset + step).clamp(0.0, 1.0);
              }

              controller.headerOffset.value = newOffset;
              controller.isVisible.value = visible;
              widget.onHeaderVisibilityChanged?.call(visible);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                if(widget.isFromHomeScreen)
                  Padding(
                    padding: EdgeInsets.only(
                      left: SizeConfig.paddingXS,
                      right: SizeConfig.paddingXS,
                    ),
                    child: _categoryRow(),
                  ),

                Expanded(
                  child: ListView.builder (
                    itemCount: cards.length,
                    padding: const EdgeInsets.all(10.0),
                    shrinkWrap: true,
                    physics: AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, cardIndex) {
                      final Cards card = cards[cardIndex];
                      final imageUrl = card.photo??'';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: AppColors.whiteFE,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          margin: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: AppColors.whiteE5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withValues(alpha: 0.08),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              )
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // ---- Single Photo ----
                              SizedBox(
                                height: SizeConfig.size390,
                                child: InkWell(
                                  onTap: () {
                                    _openCardDetailsBottomSheet(
                                      context: context,
                                      card: card,
                                      imageUrl: imageUrl,
                                      captureKey: _cardKeys[cardIndex],
                                    );
                                  },
                                  child: RepaintBoundary(
                                    key: _cardKeys[cardIndex],
                                    child: HomeScreenCard(imagePath: imageUrl),
                                  ),
                                ),
                              ),

                              // ---- Share Button ----
                              Positioned(
                                right: 8,
                                top: 8,
                                child: PositiveCustomBtn(
                                  onTap: () async {
                                    await VisitingCardHelper().shareVisitingCard(
                                      _cardKeys[cardIndex],
                                    );
                                  },
                                  title: 'Share',
                                  iconPath: AppIconAssets.shareIcon,
                                  width: SizeConfig.size90,
                                  height: SizeConfig.size30,
                                  bgColor: AppColors.primaryColor,
                                  borderColor: AppColors.primaryColor,
                                  radius: 100.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );


        } else if (response.status == Status.ERROR) {
          return LoadErrorWidget(
            errorMessage: 'Failed to load cards',
            onRetry: () {
              moreCardsScreenController.getAllCards();
              // moreCardsScreenController.getAllCardCategories();
            },
          );
        }

        return const SizedBox();
      }),
    );
  }

  Widget _cardCategory(){
   return Obx(() {
     final categories = moreCardsScreenController.allCategories;
     final selected = moreCardsScreenController.selectedCategory.value;

     return Container(
       constraints: BoxConstraints(
         minHeight: SizeConfig.size30, // Use minHeight instead of fixed height
       ),
       padding: const EdgeInsets.symmetric(horizontal: 10),
       decoration: BoxDecoration(
         color: AppColors.white,
         border: Border.all(color: AppColors.primaryColor),
         borderRadius: BorderRadius.circular(8),
       ),
       margin: EdgeInsets.only(right: SizeConfig.size20),
       child: DropdownButtonHideUnderline(
         child: DropdownButton<String>(
           value: selected,
           isDense: true,
           icon: const Icon(Icons.expand_more, color: Colors.blue),
           style: TextStyle(
             color: AppColors.primaryColor,
             fontSize: SizeConfig.small,
             fontWeight: FontWeight.w600,
           ),
           items: [
             const DropdownMenuItem<String>(
               value: "All",
               child: Text(
                 "All",
                 style: TextStyle(color: AppColors.mainTextColor),
               ),
             ),
             ...categories.map((value) {
               return DropdownMenuItem<String>(
                 value: value,
                 child: Text(
                   value,
                   style:
                   const TextStyle(color: AppColors.mainTextColor),
                 ),
               );
             }),
           ],
           onChanged: (String? newValue) {
             if (newValue != null) {
               moreCardsScreenController.selectedCategory.value = newValue;
               moreCardsScreenController.filterCardsByCategory(newValue);
             }
           },
         ),
       ),
     );
   });
  }

  Widget _categoryRow() {
    return Obx(() {
      final categories = moreCardsScreenController.allCategories;
      final selected = moreCardsScreenController.selectedCategory.value;

      // Insert "All" at first index
      final allCategories = ["All", ...categories];

      return Padding(
        padding: EdgeInsets.only(top: SizeConfig.size3, bottom: SizeConfig.size8),
        child: SizedBox(
          height: SizeConfig.size28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = allCategories[index];
              final isSelected = category == selected;

              return GestureDetector(
                onTap: () {
                  moreCardsScreenController.selectedCategory.value = category;
                  moreCardsScreenController.filterCardsByCategory(category);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor : Colors.transparent,
                    border: Border.all(color: isSelected ? AppColors.primaryColor : AppColors.secondaryTextColor),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: CustomText(
                    category,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                    color: isSelected
                        ? AppColors.white
                        : AppColors.secondaryTextColor,
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  void _openCardDetailsBottomSheet({
    required BuildContext context,
    required Cards card,
    required String imageUrl,
    required GlobalKey captureKey,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Material(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(top: 8, bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.whiteE5,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: SizeConfig.size180,
                        width: double.infinity,
                        child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((card.categoryName ?? '').isNotEmpty)
                            _infoRow('Category', card.categoryName ?? ''),
                          if ((card.eventDate ?? '').isNotEmpty)
                            _infoRow('Event Date', card.eventDate ?? ''),
                          if ((card.language ?? '').isNotEmpty)
                            _infoRow('Language', card.language ?? ''),
                          if ((card.timeZone ?? '').isNotEmpty)
                            _infoRow('Time Zone', card.timeZone ?? ''),
                          if ((card.createdBy ?? '').isNotEmpty)
                            _infoRow('Created By', card.createdBy ?? ''),
                          if ((card.createdAt ?? '').isNotEmpty)
                            _infoRow('Created At', card.createdAt ?? ''),
                          if ((card.updatedAt ?? '').isNotEmpty)
                            _infoRow('Updated At', card.updatedAt ?? ''),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: PositiveCustomBtn(
                            onTap: () async {
                              await VisitingCardHelper().shareVisitingCard(captureKey);
                            },
                            title: 'Share',
                            iconPath: AppIconAssets.shareIcon,
                            height: SizeConfig.size40,
                            radius: 10,
                            bgColor: AppColors.primaryColor,
                            borderColor: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: PositiveCustomBtn(
                            onTap: () {
                              navigatePushTo(
                                context,
                                ImageViewScreen(
                                  subTitle: '',
                                  appBarTitle: '',
                                  imageUrls: [imageUrl],
                                  initialIndex: 0,
                                ),
                              );
                            },
                            title: 'View Image',
                            height: SizeConfig.size40,
                            radius: 10,
                            bgColor: AppColors.white,
                            borderColor: AppColors.primaryColor,
                            textColor: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: CustomText(
              label,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextColor,
              fontSize: SizeConfig.small,
            ),
          ),
          Expanded(
            child: CustomText(
              value,
              fontWeight: FontWeight.w400,
              color: AppColors.mainTextColor,
              fontSize: SizeConfig.medium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }


}
