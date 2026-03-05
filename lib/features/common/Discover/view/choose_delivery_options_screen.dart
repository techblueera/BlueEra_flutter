import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/features/common/Discover/view/self_pickup_store_screen.dart';
import 'package:BlueEra/features/common/Discover/view/widget/sliver_header_delegate.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_store/rider_store_screen.dart';
import 'package:BlueEra/features/common/franchise/view/franchise_home.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChooseDeliveryOptionsScreen extends StatefulWidget {
  final String optionId;
  const ChooseDeliveryOptionsScreen({super.key, required this.optionId});

  @override
  State<ChooseDeliveryOptionsScreen> createState() => _ChooseDeliveryOptionsScreenState();
}

class _ChooseDeliveryOptionsScreenState extends State<ChooseDeliveryOptionsScreen> {
  String _selectedOptionId = '';

  @override
  void initState() {
    _selectedOptionId = widget.optionId;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Android Black
        statusBarBrightness: Brightness.light,    // iOS Black
      ),
      child: Scaffold(
        backgroundColor: AppColors.whiteF3,
        body: SafeArea(
          child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    pinned: false,
                    floating: true,
                    snap: true,
                    automaticallyImplyLeading: false,
                    forceElevated: innerBoxIsScrolled,
                    leading: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: LocalAssets(
                          imagePath: AppIconAssets.back_arrow,
                          height: SizeConfig.paddingL,
                          width: SizeConfig.paddingL,
                          imgColor: Colors.black,
                        )),
                    centerTitle: false,
                    title: Row(
                      children: [
                        LocalAssets(
                          imagePath: AppIconAssets.currentLocationIcon,
                          height: SizeConfig.size24,
                          width: SizeConfig.size24,
                        ),
                        SizedBox(width: SizeConfig.size10),
                        Expanded(
                          child: CustomText(
                            [
                              LocationService.userCurrentAddress.value.subLocality,
                              LocationService.userCurrentAddress.value.city,
                            ].where((e) => e.isNotEmpty).join(', '),
                            fontSize: SizeConfig.medium,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      Padding(
                        padding: EdgeInsets.only(right: SizeConfig.size16),
                        child: InkWell(
                          onTap: () {
                            // ... your existing tap logic ...
                          },
                          child: LocalAssets(
                            imagePath: AppIconAssets.location_new,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: SizeConfig.size16),
                        child: InkWell(
                          onTap: () {
                              commonSnackBar(message: "Coming soon....");
                            // ... your existing tap logic ...
                          },
                          child: LocalAssets(imagePath: AppIconAssets.cartIcon),
                        ),
                      ),
                    ],
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: SliverHeaderDelegate(
                      child: Container(
                        color: AppColors.whiteF3,
                        child: ListView.builder(
                          itemCount: chooseDeliveryOptions.length,
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.size8,
                              vertical: SizeConfig.size10,
                          ),
                          itemBuilder: (context, index){
                            var option = chooseDeliveryOptions[index];

                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: _buildDeliveryOption(
                                id: option['id']!,
                                icon: option['icon']!,
                                title: option['title']!,
                                subtitle: option['subtitle']!,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: (_selectedOptionId == 'SELF')
                  ? SelfPickupStoreScreen()
                  : (_selectedOptionId == 'RIDER')
                  ? RiderStoreScreen()
                  : FranchiseHome(
                  onBackPressed: (){
                    _selectedOptionId = 'RIDER';
                    setState(() {});
                  }
              )
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryOption({
    required String id,
    required String icon,
    required String title,
    required String subtitle,
  }) {
    bool isSelected = _selectedOptionId == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedOptionId = id;
        });
      },
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: isSelected ? AppColors.primaryColor : AppColors.white,
            border: Border.all(
                color: AppColors.greyE5,
                width: 1.0
            ),
            boxShadow: [AppShadows.textFieldShadow]
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            isSelected ?
            Container(
              width: SizeConfig.size40,
              height: SizeConfig.size40,
              padding: EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white
              ),
              child: LocalAssets(
                  imagePath: icon,
                  boxFix: BoxFit.contain),
            ) : LocalAssets(
                imagePath: icon,
                width: SizeConfig.size40,
                height: SizeConfig.size40,
                boxFix: BoxFit.contain),
            SizedBox(width: isSelected ? SizeConfig.paddingXS : SizeConfig.paddingXSmall),
            CustomText(
                title,
                fontSize: isSelected ? SizeConfig.large : SizeConfig.medium,
                color: isSelected ? AppColors.white : AppColors.secondaryTextColor,
                fontWeight: FontWeight.w400),

          ],
        ),
      ),
    );
  }


}
