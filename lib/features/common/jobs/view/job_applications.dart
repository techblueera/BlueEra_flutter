import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/model/get_all_jobs_model.dart';
import 'package:BlueEra/features/common/jobs/controller/application_card_controller.dart';
import 'package:BlueEra/features/common/jobs/widget/candidate_job_application_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JobApplicationsScreen extends StatefulWidget {
  final Jobs? jobsData;
  final Function(bool isVisible)? onHeaderVisibilityChanged;
  final double headerHeight;

  const JobApplicationsScreen(
      {super.key,
      required this.jobsData,
        this.onHeaderVisibilityChanged,
        required this.headerHeight
      });

  @override
  State<JobApplicationsScreen> createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  final controller = Get.put(ApplicationsController());
  Jobs? jobData;

  final List<ApplicationJobCategory> jobApplicationTab =
      ApplicationJobCategory.values;
  int selectedIndex = 0;
  bool _isVisible = true;
  double _headerHeight = 0;
  final GlobalKey _headerKey = GlobalKey();

  @override
  void initState() {
    // TODO: implement initState
    jobData = widget.jobsData;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateHeaderHeight();
    });
    super.initState();
  }

  void _calculateHeaderHeight() {
    final renderBox =
        _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && mounted) {
      setState(() {
        _headerHeight = renderBox.size.height + 20;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(
        title: jobData?.jobTitle,
        isLeading: true,
        isPDFExport: true,
        jobID: jobData?.sId,
        jobStatus: selectedIndex==1?AppConstants.Shortlisted:"",

      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            /// Main Scrollable Area with Dynamic Padding
            AnimatedPadding(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              padding: EdgeInsets.only(top: _isVisible ? _headerHeight : 0),
              child: _buildApplicationTabContent(),
            ),

            // Animated Sliding Header
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              top: _isVisible ? 0 : -_headerHeight,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.only(
                    top: SizeConfig.size10, left: SizeConfig.size5),
                child: KeyedSubtree(
                  key: _headerKey,
                  child: HorizontalTabSelector(
                    tabs: jobApplicationTab,
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

  Widget _buildApplicationTabContent() {
    switch (selectedIndex) {
      case 0:
        return CandidateJobApplicationCard(
          key: ValueKey(0),
          onHeaderVisibilityChanged: _toggleAppBarBottomButtons,
          status: '',
          jobId: jobData?.sId,
          headerHeight: widget.headerHeight,
        );
      case 1:
        return CandidateJobApplicationCard(
          key: ValueKey(1),
          onHeaderVisibilityChanged: _toggleAppBarBottomButtons,
          status: AppConstants.Shortlisted,
          jobId: jobData?.sId,
          headerHeight: widget.headerHeight,
        );
      case 2:
        return CandidateJobApplicationCard(
          key: ValueKey(2),
          onHeaderVisibilityChanged: _toggleAppBarBottomButtons,
          status: AppConstants.InterviewScheduled,
          jobId: jobData?.sId,
          headerHeight: widget.headerHeight,
        );
      // case 3:
      //   return CandidateJobApplicationCard(
      //     key: ValueKey(3),
      //
      //     onHeaderVisibilityChanged: _toggleAppBarBottomButtons,
      //     status: AppConstants.Offered,
      //     jobId: jobData?.sId,
      //   );
      case 3:
        return CandidateJobApplicationCard(
          key: ValueKey(4),
          onHeaderVisibilityChanged: _toggleAppBarBottomButtons,
          status: AppConstants.Hired,
          jobId: jobData?.sId,
          headerHeight: widget.headerHeight,
        );
      default:
        return SizedBox();
    }
  }

  void _toggleAppBarBottomButtons(bool visible) {
    if (_isVisible != visible) {
      widget.onHeaderVisibilityChanged?.call(visible);
      if (mounted) {
        setState(() => _isVisible = visible);
      }
    }
  }
}
