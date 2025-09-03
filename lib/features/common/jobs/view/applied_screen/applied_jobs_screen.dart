import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/jobs/view/applied_screen/applied_all_screen.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';


class AppliedJobsScreen extends StatefulWidget {
  final Function(bool isVisible) onHeaderVisibilityChanged;
  final double headerHeight;

  const AppliedJobsScreen({
    super.key,
    required this.onHeaderVisibilityChanged,
    required this.headerHeight
  });

  @override
  State<StatefulWidget> createState() => _AppliedJobs();
}

class _AppliedJobs extends State<AppliedJobsScreen> {
  bool _isVisible = true;
  double _headerHeight = 0;
  int selectedIndex = 0;
  final List<JobAppliedCategoryTab> jobAppliedCategory =
      JobAppliedCategoryTab.values;
  final GlobalKey _headerKey = GlobalKey();


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateHeaderHeight();
    });
  }

  void _calculateHeaderHeight() {
    final renderBox =
    _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && mounted) {
      setState(() {
        _headerHeight = renderBox.size.height+10;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            /// Main Scrollable Area with Dynamic Padding
            AnimatedPadding(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              padding: EdgeInsets.only(top: _isVisible ? _headerHeight : 0),
              child: _buildSelectedAppliedJobTabContent(),
            ),
            // Animated Sliding Header
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              top: _isVisible ? 0 : -_headerHeight,
              left: 0,
              right: 0,
              child: Padding(
                padding:  EdgeInsets.only(top: SizeConfig.size10,left: 0),
                child: KeyedSubtree(
                  key: _headerKey,
                  child: HorizontalTabSelector(
                    tabs: jobAppliedCategory,
                    selectedIndex: selectedIndex,
                    onTabSelected: (index, value) {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    labelBuilder: (jobCategory) {
                      return jobCategory.label;
                    },
                    // isFilterIconShow: true,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildSelectedAppliedJobTabContent() {
    switch (selectedIndex) {
      case 0:
        return AppliedAllScreen(key: Key("0"),onHeaderVisibilityChanged:_toggleAppBarBottomButtons, status: '', headerHeight: widget.headerHeight);
      case 1:
        return AppliedAllScreen(key: Key("1"),onHeaderVisibilityChanged:_toggleAppBarBottomButtons, status: AppConstants.Applied,  headerHeight: widget.headerHeight);

      case 2:
        return AppliedAllScreen(key: Key("2"),onHeaderVisibilityChanged:_toggleAppBarBottomButtons, status: AppConstants.InterviewScheduled,  headerHeight: widget.headerHeight);

      case 3:
        return AppliedAllScreen(key: Key("3"),onHeaderVisibilityChanged:_toggleAppBarBottomButtons, status: AppConstants.Hired,  headerHeight: widget.headerHeight);


      default:
        return SizedBox();
    }
  }

  void _toggleAppBarBottomButtons(bool visible) {
    if (_isVisible != visible) {
      widget.onHeaderVisibilityChanged.call(visible);
      if (mounted) {
        setState(() => _isVisible = visible);
      }
    }
  }
}
