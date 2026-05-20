import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/referral/view/tabs/overview_tab.dart';
import 'package:BlueEra/features/common/referral/view/tabs/post_tab.dart';
import 'package:BlueEra/features/common/referral/view/tabs/statics_tab.dart';
import 'package:BlueEra/features/common/referral/view/tabs/tutorial_tab.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

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

  static const _tabs = ['Overview', 'Tutorial', 'Post', 'Statics'];

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
        _buildPillTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              OverviewTab(controller: widget.controller),
              TutorialTab(controller: widget.controller),
              PostTab(controller: widget.controller),
              StaticsTab(controller: widget.controller),
            ],
          ),
        ),
      ],
    );
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
