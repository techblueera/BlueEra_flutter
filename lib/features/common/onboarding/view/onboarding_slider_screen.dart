import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/l10n/app_localizations.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class OnboardingSliderScreen extends StatefulWidget {
  @override
  State<OnboardingSliderScreen> createState() => _OnboardingSliderScreenState();
}

class _OnboardingSliderScreenState extends State<OnboardingSliderScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;
  // late Timer _onboardingTimer;

  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _onboardingTimer = Timer.periodic(Duration(seconds: 2), (Timer timer) {
  //       if (currentPage < getOnboardingPages().length - 1) {
  //         currentPage++;
  //         _pageController.animateToPage(
  //           currentPage,
  //           duration: Duration(milliseconds: 300),
  //           curve: Curves.easeInOut,
  //         );
  //       } else {
  //         // Navigator.popUntil(context, (route) => route.isFirst);
  //         // Navigator.pushReplacementNamed(context, RouteHelper.getOnboardingStartedScreenRoute());
  //         timer.cancel();
  //       }
  //     });
  //   });
  // }

  // @override
  // void dispose() {
  //   _onboardingTimer.cancel();
  //   _pageController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context);
    final onboardingPages = getOnboardingPages();
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingPages.length,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final data = onboardingPages[index];
                  return Padding(
                    padding: EdgeInsets.all(SizeConfig.paddingXL),
                    child: Column(
                      children: [
                        SizedBox(height: SizeConfig.size60),
                        CustomText(
                          "🇮🇳 ${appLocalizations?.madeInIndiaSuperApp}",
                          fontSize: SizeConfig.small,
                        ),
                        SizedBox(height: SizeConfig.size60),
                        LocalAssets(imagePath: data.imageAsset, height: SizeConfig.size250),
                        SizedBox(height: SizeConfig.size40),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
                          child: CustomText(
                            data.title,
                            textAlign: TextAlign.center,
                            fontSize: SizeConfig.title,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: SizeConfig.size15),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                          child: CustomText(
                            data.description,
                            textAlign: TextAlign.center,
                            fontSize: SizeConfig.small,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            ///Indicator
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: List.generate(
            //     onboardingPages.length,
            //     (index) => Container(
            //       margin: EdgeInsets.all(SizeConfig.paddingXSmall),
            //       width: SizeConfig.size10,
            //       height: SizeConfig.size10,
            //       decoration: BoxDecoration(
            //         shape: BoxShape.circle,
            //         color: currentPage == index ? Colors.black : Colors.transparent,
            //         border: Border.all(
            //           color: currentPage == index ? Colors.transparent : Colors.black,
            //           width: SizeConfig.size1,
            //         ),
            //       ),
            //     ),
            //   ),
            // ),

            ///SKIP AND NEXT BUTTON...
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXL, vertical: SizeConfig.paddingL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ...(currentPage == (getOnboardingPages().length - 1)
                      ? [
                          CustomBtn(
                            onTap: () => _goGetStarted(),
                            height: SizeConfig.size40,
                            width: SizeConfig.size290,
                            radius: 8,
                            title: appLocalizations?.get_started,
                            borderColor: AppColors.primaryColor,
                            bgColor: Colors.white,
                            textColor: AppColors.primaryColor,
                          ),
                        ]
                      : [
                          (currentPage > 0)
                              ? CustomBtn(
                                  onTap: () => _goPrevious(),
                                  height: SizeConfig.size40,
                                  width: SizeConfig.size140,
                                  radius: 8,
                                  title: appLocalizations?.previous,
                                  borderColor: AppColors.primaryColor,
                                  bgColor: Colors.white,
                                  textColor: AppColors.primaryColor,
                                )
                              : CustomBtn(
                                  onTap: () => _goSkip(),
                                  height: SizeConfig.size40,
                                  width: SizeConfig.size140,
                                  radius: 8,
                                  title: appLocalizations?.skip,
                                  borderColor: AppColors.primaryColor,
                                  bgColor: Colors.white,
                                  textColor: AppColors.primaryColor,
                                ),
                          CustomBtn(
                            onTap: () => _goNext(),
                            height: SizeConfig.size40,
                            width: SizeConfig.size140,
                            radius: 8,
                            title: appLocalizations?.next,
                            borderColor: AppColors.primaryColor,
                            bgColor: Colors.white,
                            textColor: AppColors.primaryColor,
                          ),
                        ]),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size20),
          ],
        ),
      ),
    );
  }

  void _goSkip() {
    Navigator.pushReplacementNamed(context, RouteHelper.getMobileNumberLoginRoute());
  }

  void _goNext() {
    currentPage = currentPage + 1;
    _pageController.animateToPage(
      currentPage,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goPrevious() {
    if (currentPage > 0) {
      currentPage = currentPage - 1;
      _pageController.animateToPage(
        currentPage,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goGetStarted() {
    Navigator.pushReplacementNamed(context, RouteHelper.getMobileNumberLoginRoute());
  }
}
