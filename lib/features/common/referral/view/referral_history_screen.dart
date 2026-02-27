import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/model/wallet_referral_history_response.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReferralHistoryScreen extends StatefulWidget {
  const ReferralHistoryScreen({super.key});

  @override
  State<ReferralHistoryScreen> createState() => _ReferralHistoryScreenState();
}

class _ReferralHistoryScreenState extends State<ReferralHistoryScreen> {

  final controller = Get.find<ReferralController>();

  @override
  initState() {
    super.initState();
    controller.getWalletReferralHistoryApi(controller.selectedFilter.value);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: _buildAppBar(),
      body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.paddingM),
        _buildFilterTabs(),
        SizedBox(height: SizeConfig.paddingM),
        Expanded(
            child: Obx((){
              if(controller.walletReferralHistoryResponse.value.status == Status.INITIAL){
                return Center(
                    child: CircularProgressIndicator()
                );
              }

              if(controller.walletReferralHistoryResponse.value.status == Status.ERROR){
                return Center(
                    child: CustomText(
                      'Oops Something went wrong',
                      fontSize: SizeConfig.extraLarge,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w400,
                    )
                );
              };

              return controller.referralHistoryData.isNotEmpty
              ? SingleChildScrollView(
              child: CustomFormCard(
              padding: EdgeInsets.all(SizeConfig.size10),
              child: Column(
              children: [
              _buildHeaderInfo(),
              ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              itemCount: controller.referralHistoryData.length,
              primary: false,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
              var historyData = controller.referralHistoryData[index];
              return _buildRefHistoryCard(historyData);
              },
              ),
              ],
              ),
              ),
              )
                  : EmptyStateWidget(
              message: 'No ${controller.selectedFilter.value} found.'
              );
              })


        ),
       ],
      )
    );
  }

  // --- APP BAR ---
  PreferredSizeWidget _buildAppBar() {
    return CommonBackAppBar(
      title: 'History',
      buildCustomActionWidget: ()=> Row(
        children: [
          _buildAppbarActionIcon(Icons.calendar_today_outlined),
          const SizedBox(width: 8),
          _buildAppbarActionIcon(Icons.ios_share),
          const SizedBox(width: 16),
        ],
      )
    );
  }

  Widget _buildAppbarActionIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.whiteE5),
      ),
      child: Icon(icon, color: AppColors.secondaryTextColor, size: 20),
    );
  }

  // --- FILTER TABS ---
  Widget _buildFilterTabs() {
    return Obx(()=> SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: controller.filters.map((filter) {
          bool isSelected = controller.selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                if(controller.selectedFilter.value == filter) return;
                controller.selectedFilter.value = filter;
                controller.getWalletReferralHistoryApi(filter);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryColor : Colors.grey.shade400,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ));
  }

  // --- MAIN CONTAINER HEADER ---
  Widget _buildHeaderInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            (controller.selectedFilter.value == 'All' ||
                controller.selectedFilter.value == 'Subscribe')
                ? "Subscribe User"
                  : controller.selectedFilter.value == 'Un-Subscribe'
                    ? "Un-Subscribe User" : "Expired",
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
          Row(
            children: [
              Icon(Icons.people_outline, color: AppColors.secondaryTextColor, size: 22),
              const SizedBox(width: 4),
              CustomText(
                controller.selectedFilter.value == 'All'
                    ? '${
                        controller.referralHistoryData
                            .where((item) => item.subscriptionStatus == 'subscribed')
                            .toList()
                            .length
                      }'
                    : '${controller.referralHistoryData.length}',
                fontSize: SizeConfig.extraLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- INDIVIDUAL USER CARD ---
  Widget _buildRefHistoryCard(WalletReferralHistoryData historyData) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: AppColors.whiteE5, width: 0.5),
      ),
      child: Row(
        children: [
          // 1. Profile Image
          CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(historyData.profileImage??''),
            backgroundColor: AppColors.whiteFE,
          ),
          const SizedBox(width: 12),

          // 2. Name & Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  historyData.name,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 6),
                CustomText(
                  historyData.profession,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),

          // 3. Trailing Actions (Chat Icon & Amount)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Chat Icon
              LocalAssets(
                imagePath: AppIconAssets.chat, // Closest match to your UI
                imgColor: AppColors.primaryColor,
                height: 20,
                width: 20,
              ),
              const SizedBox(height: 8),

              // Pricing format
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${historyData.referralIncome} ",
                      style: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w400,
                        fontSize: SizeConfig.small,
                      ),
                    ),
                    TextSpan(
                      text: "/ ${historyData.planCost}",
                      style: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: SizeConfig.small,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}