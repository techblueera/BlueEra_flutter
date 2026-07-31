import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/view/tabs/creator_tab.dart';
import 'package:BlueEra/features/common/referral/view/tabs/overview_tab.dart';
import 'package:BlueEra/features/common/referral/view/tabs/statics_tab.dart';
import 'package:BlueEra/features/common/referral/view/tabs/tutorial_tab.dart';
import 'package:BlueEra/features/common/referral/view/update_referral_page.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReferralDashboardPage extends StatefulWidget {
  final ReferralController controller;
  const ReferralDashboardPage({super.key, required this.controller});

  @override
  State<ReferralDashboardPage> createState() => _ReferralDashboardPageState();
}

class _ReferralDashboardPageState extends State<ReferralDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTab = 0;

  // Raw keys, not `.tr` values — `CustomText` translates on build, so the
  // strip re-renders in the new language on a locale switch.
  static const _tabs = [
    AppStrings.overviewTab,
    AppStrings.tutorialTab,
    AppStrings.creatorTab,
    AppStrings.staticsTab,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_selectedTab != _tabController.index) {
      setState(() => _selectedTab = _tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SizeConfig.paddingXSL),
        _buildUpdateCodeAction(),
        _buildPillTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              OverviewTab(controller: widget.controller),
              TutorialTab(controller: widget.controller),
              CreatorTab(controller: widget.controller),
              StaticsTab(controller: widget.controller),
            ],
          ),
        ),
      ],
    );
  }

  /// "Update Referral Code" affordance — only rendered while the
  /// profile's `referralCodeEditable` flag is true (backend allows a
  /// single change). Opens [UpdateReferralPage], whose submit button
  /// calls `PUT wallet/referral`.
  Widget _buildUpdateCodeAction() {
    return Obx(() {
      if (!widget.controller.referralCodeEditable.value) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: EdgeInsets.fromLTRB(
          SizeConfig.size10,
          0,
          SizeConfig.size10,
          SizeConfig.paddingXSL,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => Get.to(
            () => UpdateReferralPage(controller: widget.controller),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomText(
                    AppStrings.updateReferralCode,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.primaryColor),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Pill-style tab strip matching the mockup — single rounded white
  /// container with a light border, each tab a 36-px chip (solid
  /// primary blue + white label when active, transparent + dark label
  /// when inactive).
  Widget _buildPillTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
      padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: Offset(0, 2)
          )
        ]
      ),
      child: SizedBox(
        height: 32,
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final selected = _selectedTab == i;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (i == _selectedTab) return;
                  _tabController.animateTo(i);
                  setState(() => _selectedTab = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  margin: EdgeInsets.symmetric(
                      horizontal: i == 0 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryColor
                        : Colors.transparent,
                    border: Border.all(
                      color: selected ? AppColors.primaryColor
                       : AppColors.greyE5
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: CustomText(
                    _tabs[i],
                    fontSize: SizeConfig.small,
                    fontWeight:
                        selected ? FontWeight.w400 : FontWeight.w400,
                    color: selected
                        ? AppColors.white
                        : AppColors.secondaryTextColor,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
