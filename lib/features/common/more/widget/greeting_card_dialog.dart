import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/more/model/card_model.dart';
import 'package:BlueEra/features/common/more/widget/greeting_card.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/visiting_card_helper.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GreetingCardDialog extends StatefulWidget {
  final List<Cards> cards;

  const GreetingCardDialog({super.key, required this.cards});

  @override
  State<GreetingCardDialog> createState() => _GreetingCardDialogState();
}

class _GreetingCardDialogState extends State<GreetingCardDialog> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentIndex = 0;
  late final List<GlobalKey> _cardKey;
  bool dontShowAgain = false;

  @override
  void initState() {
    super.initState();
    _cardKey = List.generate(widget.cards.length, (_) => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () {
                  Get.back();
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.mainTextColor,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                      color: AppColors.whiteE5
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.08),
                        offset: Offset(0, 1),
                        blurRadius: 2
                    )]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          "Share This Card To Your Friend Or Family",
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w400,
                          fontSize: SizeConfig.small,
                          fontFamily: AppConstants.OpenSans
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: SizeConfig.size300,
                        child: CarouselSlider.builder(
                          carouselController: _carouselController,
                          itemCount: widget.cards.length,
                          itemBuilder: (context, index, realIndex) {
                            final card = widget.cards[index];
                            final cardPhoto = card.photo ?? '';

                            return RepaintBoundary(
                              key: _cardKey[index],
                              child: GreetingCard(imagePath: cardPhoto),
                            );
                          },
                          options: CarouselOptions(
                            height: SizeConfig.size300,
                            enlargeCenterPage: true,
                            enableInfiniteScroll: true,
                            autoPlay: widget.cards.length > 1,
                            autoPlayInterval: const Duration(seconds: 3),
                            autoPlayAnimationDuration: const Duration(milliseconds: 800),
                            viewportFraction: 1.0, // show one card fully
                            onPageChanged: (i, reason) {
                              setState(() => _currentIndex = i);
                            },
                          ),
                        ),
                      ),

                      // Left Arrow
                      if (widget.cards.length > 1)
                        Positioned(
                          left: 6,
                          child: GestureDetector(
                            onTap: () {
                              final previousPage = _currentIndex != 0
                                  ? _currentIndex - 1
                                  : widget.cards.length - 1;
                              _carouselController.animateToPage(
                                previousPage,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
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
                                angle: 3.1416,
                                child: const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: AppColors.white),
                              ),
                            ),
                          ),
                        ),

                      // Right Arrow
                      if (widget.cards.length > 1)
                        Positioned(
                          right: 6,
                          child: GestureDetector(
                            onTap: () {
                              final nextPage = _currentIndex != widget.cards.length - 1
                                  ? _currentIndex + 1
                                  : 0;
                              _carouselController.animateToPage(
                                nextPage,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
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
                              child: const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: AppColors.white),
                            ),
                          ),
                        ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: dontShowAgain,
                  onChanged: (val) {
                    setState(() => dontShowAgain = val!);
                    if (val == true) {
                      disableGreetingCard();
                      print("User does not want to see this card anymore");
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeColor: AppColors.primaryColor,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  checkColor: AppColors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomText(
                    "Don't show this card again",
                    fontSize: SizeConfig.medium,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            !dontShowAgain
            ? Row(
              children: [
                Expanded(
                  child: PositiveCustomBtn(
                    onTap: () {
                      Get.back();
                      Get.toNamed(RouteHelper.getMoreCardsScreenRoute(), arguments: {ApiKeys.isFromHomeScreen: false});
                    },
                    title: 'More Card',
                    bgColor: AppColors.white,
                    borderColor: AppColors.primaryColor,
                    textColor: AppColors.primaryColor,
                    radius: 100.0,
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                Expanded(
                  child: PositiveCustomBtn(
                    onTap: () async {
                      Get.back();
                      await VisitingCardHelper().shareVisitingCard(
                        _cardKey[_currentIndex],
                     );
                    },
                    title: 'Share',
                    iconPath: AppIconAssets.shareIcon,
                    bgColor: AppColors.primaryColor,
                    borderColor: AppColors.primaryColor,
                    radius: 100.0,
                  ),
                ),
              ],
            )
            : PositiveCustomBtn(
              onTap: () async {
                await disableGreetingCard();
                Get.back();
              },
              title: 'Submit',
              bgColor: AppColors.primaryColor,
              borderColor: AppColors.primaryColor,
              radius: 100.0,
            ),
          ],
        ),
      ),
    );
  }
}
