import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/more/controller/more_cards_screen_controller.dart';
import 'package:BlueEra/features/common/more/model/card_model.dart';
import 'package:BlueEra/features/common/more/widget/home_screen_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/get_own_product_model.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/visiting_card_helper.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductHomeScreenCard extends StatefulWidget {
  final List<OwnProductData> allProducts;

  const ProductHomeScreenCard({super.key, required this.allProducts});

  @override
  State<ProductHomeScreenCard> createState() => _ProductHomeScreenCardState();
}

class _ProductHomeScreenCardState extends State<ProductHomeScreenCard> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
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
                      Get.toNamed(RouteHelper.getMoreCardsScreenRoute(),
                          arguments: {ApiKeys.isFromHomeScreen: false});
                    },
                    child: SizedBox(
                      height: SizeConfig.size300,
                      child: CarouselSlider.builder(
                        carouselController: _carouselController,
                        itemCount: widget.allProducts.length,
                        itemBuilder: (context, index, realIndex) {
                          final product = widget.allProducts[index];
                          final productPhoto = product.product.details?.media[0] ?? '';

                          return homeScreenCard(imagePath: productPhoto);
                        },
                        options: CarouselOptions(
                          height: SizeConfig.size300,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: true,
                          autoPlay: widget.allProducts.length > 1,
                          autoPlayInterval: const Duration(seconds: 3),
                          autoPlayAnimationDuration:
                          const Duration(milliseconds: 800),
                          viewportFraction: 1.0,
                          // show one card fully
                          onPageChanged: (i, reason) {
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
                        "Share This Card To Your Friend Or Family",
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
                        VisitingCardHelper.buildAndShareProductCard(
                          context,
                          currentProduct,
                          index: _currentIndex,
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: SizeConfig.size5,right: SizeConfig.size5,top: SizeConfig.size5),
                        child: LocalAssets(imagePath: AppIconAssets.share_bold),
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
