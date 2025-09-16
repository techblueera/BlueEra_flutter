import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/more/controller/more_cards_screen_controller.dart';
import 'package:BlueEra/features/common/more/widget/greeting_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:BlueEra/widgets/visiting_card_helper.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MoreCardsScreen extends StatefulWidget {
  const MoreCardsScreen({super.key});

  @override
  State<MoreCardsScreen> createState() => _MoreCardsScreenState();
}

class _MoreCardsScreenState extends State<MoreCardsScreen> {
  final MoreCardsScreenController moreCardsScreenController =
  Get.put(MoreCardsScreenController());

  /// Keys for capturing widget images (per card → per photo)
  final List<List<GlobalKey>> _cardKeys = [];

  /// Track current photo index for each card
  late List<int> _currentPhotoIndex;

  /// Each card can control its own carousel (null if single photo)
  final List<CarouselSliderController?> _carouselControllers = [];

  @override
  void initState() {
    super.initState();
    moreCardsScreenController.getAllCardCategories();
  }

  /// Build keys & trackers for each card
  void _generateKeysAndIndices(List cards) {
    _cardKeys.clear();
    _carouselControllers.clear();
    _currentPhotoIndex = List.generate(cards.length, (_) => 0);

    for (var card in cards) {
      final photoCount = card.photos?.length ?? 0;

      // Create keys
      if (photoCount > 0) {
        _cardKeys.add(List.generate(photoCount, (_) => GlobalKey()));
      } else {
        _cardKeys.add([]);
      }

      // Carousel controller only for multiple photos
      if (photoCount > 1) {
        _carouselControllers.add(CarouselSliderController());
      } else {
        _carouselControllers.add(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'More Cards',
        buildCardCategory: () {
          return Obx(() {
            final categories = moreCardsScreenController.allCategories;
            final selected = moreCardsScreenController.selectedCategory.value;

            return DropdownButtonHideUnderline(
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
            );
          });
        },
      ),
      body: Obx(() {
        if (moreCardsScreenController.isLoading.isTrue) {
          return const Center(child: CircularProgressIndicator());
        }

        final response = moreCardsScreenController.AllCardCategoriesResponse.value;

        if (response.status == Status.COMPLETE) {
          final cards = moreCardsScreenController.filteredCards;

          _generateKeysAndIndices(cards);

          if (cards.isEmpty) {
            return const EmptyStateWidget(message: 'No cards available.');
          }

          return ListView.builder(
            itemCount: cards.length,
            padding: const EdgeInsets.all(10.0),
            itemBuilder: (context, cardIndex) {
              final card = cards[cardIndex];
              final photoCount = card.photos?.length ?? 0;

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
                      // Carousel or single photo
                      SizedBox(
                        height: SizeConfig.size300,
                        child: photoCount > 1
                            ? CarouselSlider.builder(
                          carouselController:
                          _carouselControllers[cardIndex]!,
                          itemCount: photoCount,
                          itemBuilder: (context, photoIndex, realIndex) {
                            final imageUrl = card.photos![photoIndex];
                            return RepaintBoundary(
                              key: _cardKeys[cardIndex][photoIndex],
                              child: GreetingCard(imagePath: imageUrl),
                            );
                          },
                          options: CarouselOptions(
                            height: SizeConfig.size300,
                            viewportFraction: 1.0,
                            enableInfiniteScroll: true,
                            autoPlay: true,
                            onPageChanged: (index, reason) {
                              setState(() =>
                              _currentPhotoIndex[cardIndex] = index);
                            },
                          ),
                        )
                            : (card.photos?.isNotEmpty ?? false)
                            ? RepaintBoundary(
                          key: _cardKeys[cardIndex][0],
                          child:
                          GreetingCard(imagePath: card.photos!.first),
                        )
                            : const SizedBox.shrink(),
                      ),

                      // // Left arrow
                      // if (photoCount > 1)
                      //   Positioned(
                      //     left: 6,
                      //     top: 0,
                      //     bottom: 0,
                      //     child: GestureDetector(
                      //       onTap: () {
                      //         final previousPage =
                      //         _currentPhotoIndex[cardIndex] != 0
                      //             ? _currentPhotoIndex[cardIndex] - 1
                      //             : photoCount - 1;
                      //         _carouselControllers[cardIndex]!
                      //             .animateToPage(
                      //           previousPage,
                      //           duration: const Duration(milliseconds: 300),
                      //           curve: Curves.easeInOut,
                      //         );
                      //       },
                      //       child: _buildArrow(isLeft: true),
                      //     ),
                      //   ),
                      //
                      // // Right arrow
                      // if (photoCount > 1)
                      //   Positioned(
                      //     right: 6,
                      //     top: 0,
                      //     bottom: 0,
                      //     child: GestureDetector(
                      //       onTap: () {
                      //         final nextPage =
                      //         _currentPhotoIndex[cardIndex] != photoCount - 1
                      //             ? _currentPhotoIndex[cardIndex] + 1
                      //             : 0;
                      //         _carouselControllers[cardIndex]!
                      //             .animateToPage(
                      //           nextPage,
                      //           duration: const Duration(milliseconds: 300),
                      //           curve: Curves.easeInOut,
                      //         );
                      //       },
                      //       child: _buildArrow(isLeft: false),
                      //     ),
                      //   ),

                      // Share button
                      Positioned(
                        right: 8,
                        top: 8,
                        child: PositiveCustomBtn(
                          onTap: () async {
                            final currentPage = _currentPhotoIndex[cardIndex];
                            if (_cardKeys[cardIndex].isNotEmpty &&
                                currentPage < _cardKeys[cardIndex].length) {
                              await VisitingCardHelper().shareVisitingCard(
                                _cardKeys[cardIndex][currentPage],
                              );
                            }
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

  Widget _buildArrow({required bool isLeft}) {
    return Container(
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: AppColors.blackCC.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 1),
            blurRadius: 2,
            spreadRadius: 0,
          )
        ],
      ),
      child: Transform.rotate(
        angle: isLeft ? 3.1416 : 0,
        child: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.white,
        ),
      ),
    );
  }
}
