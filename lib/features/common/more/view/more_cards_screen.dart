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

          _generateKeys(cards);

          if (cards.isEmpty) {
            return const EmptyStateWidget(message: 'No cards available.');
          }

          return ListView.builder(
            itemCount: cards.length,
            padding: const EdgeInsets.all(10.0),
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

}
