import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/more/controller/more_cards_screen_controller.dart';
import 'package:BlueEra/features/common/more/widget/greeting_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:BlueEra/widgets/visiting_card_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    moreCardsScreenController.getAllCardCategories();
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

        final response = moreCardsScreenController.AllCardCategoriesResponse.value;

        if (response.status == Status.COMPLETE) {
          final cards = moreCardsScreenController.filteredCards;

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
                      final card = cards[cardIndex];
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
                                height: SizeConfig.size300,
                                child: RepaintBoundary(
                                  key: _cardKeys[cardIndex],
                                  child: GreetingCard(imagePath: imageUrl),
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
              moreCardsScreenController.getAllCardCategories();
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


}
