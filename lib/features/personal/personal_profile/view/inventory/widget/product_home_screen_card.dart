import 'dart:developer';
import 'dart:math' hide log;
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/home/widgets/diwali_offer_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_own_product_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/visiting_card_helper.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class ProductHomeScreenCard extends StatefulWidget {
  final List<OwnProductData> allProducts;

  const ProductHomeScreenCard({super.key, required this.allProducts});

  @override
  State<ProductHomeScreenCard> createState() => _ProductHomeScreenCardState();
}

class _ProductHomeScreenCardState extends State<ProductHomeScreenCard> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentIndex = 0;

  final List<String> bgAssets = [
    'assets/diwali_card/diwali_sample_card1.jpeg',
    'assets/diwali_card/diwali_sample_card2.jpeg',
    'assets/diwali_card/diwali_sample_card3.jpeg',
    'assets/diwali_card/diwali_sample_card4.jpeg',
    'assets/diwali_card/diwali_sample_card5.jpeg',
    'assets/diwali_card/diwali_sample_card6.jpeg',
  ];
  late final List<GlobalKey> _cardKey;

  @override
  void initState() {
    super.initState();
    _cardKey = List.generate(widget.allProducts.length, (_) => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate card size - 1:1 aspect ratio
    const double maxCardSize = 400.0;
    final double cardSize = screenWidth > maxCardSize ? maxCardSize : screenWidth * 0.9;


    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.whiteE5),
              boxShadow: [
                BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.08),
                    offset: Offset(0, 1),
                    blurRadius: 2)
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [

                  InkWell(
                    onTap: () {
                      // Get.toNamed(RouteHelper.getMoreCardsScreenRoute(),
                      //     arguments: {ApiKeys.isFromHomeScreen: false});
                    },
                    child: SizedBox(
                      height: cardSize,
                      child: CarouselSlider.builder(
                        carouselController: _carouselController,
                        itemCount: widget.allProducts.length,
                        itemBuilder: (context, index, realIndex) {
                          final product = widget.allProducts[index];
                          final int randomIndex = Random().nextInt(bgAssets.length);
                          final String bgAsset = bgAssets[randomIndex];

                          return DiwaliOfferCard(
                              cardKey: _cardKey[index],
                              ownProductData: product,
                              backgroundAsset: bgAsset,
                          );
                        },
                        options: CarouselOptions(
                          height: cardSize,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: false,
                          autoPlay: widget.allProducts.length > 1,
                          autoPlayInterval: const Duration(seconds: 5),
                          autoPlayAnimationDuration:
                          const Duration(milliseconds: 5000),
                          viewportFraction: 1.0,
                          onPageChanged: (i, reason) {
                            log('currentIndex--> $_currentIndex');
                            setState(() => _currentIndex = i);
                          },
                        ),
                      ),
                    ),
                  ),

                  // Left Arrow
                  if (widget.allProducts.length > 1)
                    Positioned(
                      left: 6,
                      child: GestureDetector(
                        onTap: () {
                          final previousPage = _currentIndex != 0
                              ? _currentIndex - 1
                              : widget.allProducts.length - 1;
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
                  if (widget.allProducts.length > 1)
                    Positioned(
                      right: 6,
                      child: GestureDetector(
                        onTap: () {
                          final nextPage =
                          _currentIndex != widget.allProducts.length - 1
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
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: CustomText(
                        "Share card to social media, Grow business",
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w400,
                        fontSize: SizeConfig.small,
                        fontFamily: AppConstants.OpenSans),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: () async {
                        final currentProduct = widget.allProducts[_currentIndex];
                        await VisitingCardHelper().shareVisitingCard(
                            _cardKey[_currentIndex],
                            productId: currentProduct.product.details?.id
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: SizeConfig.size5,right: SizeConfig.size5,top: SizeConfig.size5),
                        child: LocalAssets(imagePath: AppIconAssets.share_bold, imgColor: AppColors.primaryColor ),
                      ),
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),
      ],
    );
  }

}
