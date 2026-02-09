import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../core/api/apiService/api_response.dart';
import '../../../core/constants/getx_utils.dart';
import '../../../widgets/custom_btn.dart';
import '../auth/controller/subscription_controller.dart';
import '../auth/model/subscription_list_details_model.dart';

class SubscriptionScreenNew extends StatefulWidget {
  const SubscriptionScreenNew({super.key});

  @override
  State<SubscriptionScreenNew> createState() => _SubscriptionScreenNewState();
}

class _SubscriptionScreenNewState extends State<SubscriptionScreenNew> {
  int selectedIndex = 0;
  final controller = getOrPut(() => SubscriptionController());
  @override
  void initState() {
    controller.subscriptionPlansGetApi();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,

      appBar: CommonBackAppBar(

          appBarColor: AppColors.white,

          title: "Subscription"
      ),

      body: Obx(() {
        if(controller.getSubscriptionOfferResponse.value.status==Status.COMPLETE){
          List<SubscriptionPlanData>? subsList=controller.subscriptionPlanDetailsNewModel.value.data;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _header(),
                const SizedBox(height: 16),
                Expanded(child: ListView.separated(
                  itemCount: subsList?.length??0,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final isSelected = selectedIndex == index;
                    SubscriptionPlanData? details=subsList?[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedIndex = index);
                      },
                      child: isSelected
                          ? _selectedCard(details)
                          : _unSelectedCard(details),
                    );
                  },
                )),
                _payButton(),
              ],
            ),
          );
        }else{
          return Center(
            child: CircularProgressIndicator(),
          );
        }

      }),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              "Go Premium ",
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.rating,
            ),
            LocalAssets(
              imagePath: "assets/images/premium.png",
              height: 32,
              width: 32,
            ),
          ],
        ),
        const SizedBox(height: 6),
        const CustomText(
          "No commitment, cancel anytime",
          fontSize: 16,
          fontWeight: FontWeight.w400,

          color: AppColors.secondaryTextColor,
        ),
      ],
    );
  }



  Widget _selectedCard(SubscriptionPlanData? details) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: LocalAssets(
            imagePath: "assets/images/subscription_card_bg.png",
            // height: 155,
            width: double.infinity,
            boxFix: BoxFit.cover,
          ),
        ),

        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              // crossAxisAlignment: CrossAxisAlignment.center,
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _priceBlock(isDark: true,details: details),
                //_verticalDivider(isDark: true),
                const SizedBox(width: 34,),
                Expanded(child: _features(isDark: true,details: details)),
              ],
            ),
          ),
        ),

        Positioned(

          left: 36,top: 16,
            child: _basicTag(isDark: true)),
      ],
    );
  }

  Widget _unSelectedCard(SubscriptionPlanData? details) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.whiteE5),
      ),
      child: Row(
        children: [

          Column(
            children: [
              _basicTag(isDark: false),

              _priceBlock(isDark: false,details:details),
            ],
          ),
          _verticalDivider(isDark: false),
          Expanded(child: _features(isDark: false,details: details)),
        ],
      ),
    );
  }

  Widget _priceBlock({
    required bool isDark,
    required SubscriptionPlanData? details,
  }) {
    return SizedBox(
      width: 110,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomText(
            "₹${details?.amount ?? ''}",
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.secondaryTextColor,
          ),
          const SizedBox(height: 8),
          CustomText(
            details?.name ?? "",
            fontSize: 12,
            textAlign: TextAlign.center,
            color: isDark
                ? AppColors.white
                : AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }
  Widget _verticalDivider({required bool isDark}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 1,
      height: 110,
      color: isDark
          ? AppColors.white.withOpacity(0.4)
          : AppColors.whiteE5,
    );
  }
  Widget _features({required bool isDark,required SubscriptionPlanData? details}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "Features",
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.white : AppColors.secondaryTextColor,
        ),
        const SizedBox(height: 6),
        _featureItem("${details?.description==''?"N/A":details?.description}", isDark),
        // _featureItem("Cancel Subscription any time", isDark),
        // _featureItem("Cancel Subscription any time", isDark),
        // _featureItem("Cancel Subscription any time", isDark),
      ],
    );
  }

  Widget _featureItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: isDark
                ? AppColors.white
                : AppColors.secondaryTextColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: CustomText(
              text,
              fontSize: 12,
              maxLines: 1,
              fontWeight: FontWeight.w400,

              color: isDark
                  ? AppColors.white
                  : AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _basicTag({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.white.withOpacity(0.15)
            : AppColors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: CustomText(
        "BASIC",
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.white : AppColors.secondaryTextColor,
      ),
    );
  }
  Widget _payButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: CustomBtn(
        height: 48,
        width: double.infinity,
        bgColor: AppColors.primaryColor,
        borderColor: AppColors.primaryColor,
        textColor: AppColors.white,
        title: "Pay",
        onTap: () {
        },
      ),
    );
  }}