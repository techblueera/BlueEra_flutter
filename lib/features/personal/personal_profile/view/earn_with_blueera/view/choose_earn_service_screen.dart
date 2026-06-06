import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/dashed_border_container.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class _EarnOption {
  final String title;
  final String subtitle;
  final String icon;
  final String slugId;
  final List<String> chips;
  final Color chipColor;

  const _EarnOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.slugId,
    required this.chips,
    required this.chipColor,
  });
}

class ChooseEarnServiceScreen extends StatefulWidget {
  const ChooseEarnServiceScreen({super.key});

  @override
  State<ChooseEarnServiceScreen> createState() =>
      _ChooseEarnServiceScreenState();
}

class _ChooseEarnServiceScreenState extends State<ChooseEarnServiceScreen> {
  final controller = getOrPut(() => EarnServiceController());
  int _selectedIndex = 0;

  final List<_EarnOption> _options = [
    _EarnOption(
      title: AppStrings.homeMadeFoodTitle,
      subtitle: AppStrings.homeMadeFoodSubtitle,
      icon: AppImageAssets.homeMadeFoodEarnService,
      slugId: HOME_MADE_FOOD,
      chipColor: const Color(0xFF2C3F25),
      chips: const [
        AppStrings.tiffinServiceChip,
        AppStrings.bakery,
        AppStrings.sweets,
        AppStrings.breakfastChip,
        AppStrings.namkeensLabel,
        AppStrings.picklesLabel,
        AppStrings.homemadeSnacksChip,
        AppStrings.moreDots,
      ],
    ),
    _EarnOption(
      title: AppStrings.homeMadeProductsTitle,
      subtitle: AppStrings.homeMadeProductsSubtitle,
      icon: AppImageAssets.homeMadeProductEarnService,
      slugId: HOME_MADE_PRODUCTS,
      chipColor: const Color(0xFF0C447C),
      chips: const [
        AppStrings.handicraftsChip,
        AppStrings.giftItemsChip,
        AppStrings.textileFashionChip,
        AppStrings.utilityProductsChip,
        AppStrings.picklesAndMasalaChip,
        AppStrings.organicProductsChip,
        AppStrings.moreDots,
      ],
    ),
    _EarnOption(
      title: AppStrings.homeServicesTitle,
      subtitle: AppStrings.homeServicesSubtitle,
      icon: AppImageAssets.homeServicesEarnService,
      slugId: HOME_SERVICES,
      chipColor: const Color(0xFF0C447C),
      chips: const [
        AppStrings.beautyServiceChip,
        AppStrings.tailoringChip,
        AppStrings.interiorDecorChip,
        AppStrings.cleaningServiceChip,
        AppStrings.repairServiceChip,
        AppStrings.tutoringChip,
        AppStrings.moreDots,
      ],
    ),
    _EarnOption(
      title: AppStrings.partTimeRiderTitle,
      subtitle: AppStrings.partTimeRiderSubtitle,
      icon: AppImageAssets.riderEarnService,
      slugId: GIG_WORKER,
      chipColor: const Color(0xFF3C3489),
      chips: const [
        AppStrings.foodDeliveryChip,
        AppStrings.productDeliveryChip,
        AppStrings.parcelPickupChip,
        AppStrings.localDeliveryChip,
        AppStrings.bikeDeliveryChip,
        AppStrings.courierDeliveryChip,
        AppStrings.moreDots,
      ],
    ),
    _EarnOption(
      title: AppStrings.earnedViaChannelTitle,
      subtitle: AppStrings.earnedViaChannelSubtitle,
      icon: AppImageAssets.channelEarnService,
      slugId: CONTENT_CREATOR,
      chipColor: const Color(0xFF7E2DC4),
      chips: const [
        AppStrings.videoEditingChip,
        AppStrings.influencerWorkChip,
        AppStrings.socialMediaPostsChip,
        AppStrings.graphicDesignChip,
        AppStrings.scriptWritingChip,
        AppStrings.moreDots,
      ],
    ),
    _EarnOption(
      title: AppStrings.homeTuitionCounsellingTitle,
      subtitle: AppStrings.homeTuitionCounsellingSubtitle,
      icon: AppImageAssets.homeTuitionEarnService,
      slugId: TUTOR,
      chipColor: const Color(0xFF893489),
      chips: const [
        AppStrings.onlineClassesChip,
        AppStrings.offlineTuitionChip,
        AppStrings.examPreparationChip,
        AppStrings.careerGuidanceChip,
        AppStrings.personalMentoringChip,
        AppStrings.moreDots,
      ],
    ),
    _EarnOption(
      title: AppStrings.homeStayTitle,
      subtitle: AppStrings.homeStaySubtitle,
      icon: AppImageAssets.homeStayEarnService,
      slugId: RENTAL_SERVICES,
      chipColor: const Color(0xFF89343F),
      chips: const [
        AppStrings.homeStayChip,
        AppStrings.flatAndRoomChip,
        AppStrings.vehicleChip,
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: AppStrings.earnWithBlueEra
      ),
      bottomNavigationBar: _buildContinueButton(),
      body: SafeArea(
        child: ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size8,
            vertical: SizeConfig.size16,
          ),
          itemCount: _options.length,
          separatorBuilder: (_, __) =>
              SizedBox(height: SizeConfig.size10),
          itemBuilder: (_, i) =>
              _buildOptionCard(_options[i], i == _selectedIndex, i),
        ),
      ),
    );
  }

  Widget _buildOptionCard(_EarnOption option, bool selected, int index) {
    return InkWell(
      borderRadius: BorderRadius.circular(10.0),
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: selected ? AppColors.primaryColor : AppColors.greyE5,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LocalAssets(
                    imagePath: option.icon,
                    width: 60,
                    height: 60,
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        option.title,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                      SizedBox(height: 6),
                      CustomText(
                        option.subtitle,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
              child: DashedHorizontalLine(color: AppColors.greyE5),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: option.chips
                  .map((label) => _buildChip(label, option.chipColor))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color chipColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: AppColors.greyE5,
            width: 0.5
        ),
      ),
      child: CustomText(
        label,
        fontSize: SizeConfig.small,
        color: chipColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size8,
        SizeConfig.size10,
        SizeConfig.size8,
        SizeConfig.size10,
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: SizeConfig.size40,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () {
              final option = _options[_selectedIndex];
              controller.handleServiceTap(
                context,
                CollapsibleGridModel(
                  name: option.title,
                  slugId: option.slugId,
                  icon: option.icon,
                ),
              );
            },
            child: CustomText(
              AppStrings.continueText.tr,
              fontSize: SizeConfig.large,
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

