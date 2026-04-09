import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/earn_service_controller.dart';
import 'package:BlueEra/widgets/collapsible_grid_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class _EarnOption {
  final String title;
  final String subtitle;
  final String icon;
  final String slugId;
  final List<String> chips;

  const _EarnOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.slugId,
    required this.chips,
  });
}

class chooseEarnServiceScreen extends StatefulWidget {
  const chooseEarnServiceScreen({super.key});

  @override
  State<chooseEarnServiceScreen> createState() =>
      _chooseEarnServiceScreenState();
}

class _chooseEarnServiceScreenState
    extends State<chooseEarnServiceScreen> {
  final controller = getOrPut(() => EarnServiceController());
  int _selectedIndex = 0;

  // Not const because some `AppImageAssets` entries are declared as plain
  // `static String` (non-const), so the list itself can't be const.
  final List<_EarnOption> _options = [
    _EarnOption(
      title: 'Home Made Food',
      subtitle: 'Sell Homemade Food, Earn Daily',
      icon: AppImageAssets.homeMadeFood,
      slugId: HOME_MADE_FOOD,
      chips: const [
        'Tiffin Service',
        'Bakery',
        'Sweets',
        'Breakfast',
        'Namkeens',
        'Pickles',
        'Homemade Snacks',
        'More...'
      ],
    ),
    _EarnOption(
      title: 'Home Made Product & Services',
      subtitle: 'Sell Products, Offer Local Services',
      icon: AppImageAssets.homeMadeProduct,
      slugId: HOME_MADE_PRODUCTS,
      chips: const [
        'Handicrafts',
        'Gift Items',
        'Textile & Fashion',
        'Utility Products',
        'Beauty Service',
        'Tailoring',
        'Interior Decor',
        'More...'
      ],
    ),
    _EarnOption(
      title: 'Part Time Rider',
      subtitle: 'Earn With Rides And Delivery',
      icon: AppImageAssets.deliveryPartner,
      slugId: GIG_WORKER,
      chips: const [
        'Food Delivery',
        'Product Delivery',
        'Parcel Pickup',
        'Local Delivery',
        'Bike Delivery',
        'Courier Delivery',
        'More...'
      ],
    ),
    _EarnOption(
      title: 'Earned Via Channel',
      subtitle: 'Offer Content Services, Gain Clients',
      icon: AppImageAssets.contentCreator,
      slugId: CONTENT_CREATOR,
      chips: const [
        'Video Editing',
        'Influencer Work',
        'Social Media Posts',
        'Graphic Design',
        'Script Writing',
        'More...'
      ],
    ),
    _EarnOption(
      title: 'Home Tuition & Counselling',
      subtitle: 'Teach Students, Earn From Home',
      icon: AppImageAssets.tutor,
      slugId: TUTOR,
      chips: const [
        'Online Classes',
        'Offline Tuition',
        'Exam Preparation',
        'Career Guidance',
        'Personal Mentoring',
        'More...'
      ],
    ),
    _EarnOption(
      title: 'Home Stay',
      subtitle: 'Rent Property, Earn Extra Income',
      icon: AppImageAssets.homeStay,
      slugId: RENTAL_SERVICES,
      chips: const ['Home Stay', 'Flat & Room', 'Vehicle'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.mainTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: CustomText(
          AppStrings.earnWithBlueEra,
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size16,
                  vertical: SizeConfig.size12,
                ),
                itemCount: _options.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: SizeConfig.size12),
                itemBuilder: (_, i) =>
                    _buildOptionCard(_options[i], i == _selectedIndex, i),
              ),
            ),
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(_EarnOption option, bool selected, int index) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryColor : AppColors.greyE5,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LocalAssets(
                    imagePath: option.icon,
                    width: 56,
                    height: 56,
                  ),
                ),
                SizedBox(width: SizeConfig.size12),
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
                      SizedBox(height: 2),
                      CustomText(
                        option.subtitle,
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: SizeConfig.size12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: option.chips.map(_buildChip).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.fillColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomText(
        label,
        fontSize: SizeConfig.small,
        color: AppColors.primaryColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size16,
        SizeConfig.size8,
        SizeConfig.size16,
        SizeConfig.size16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: SizeConfig.size50,
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
            Navigator.of(context).pop();
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
    );
  }
}
