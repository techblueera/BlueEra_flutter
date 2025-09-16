import 'dart:async';

import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/jobs/controller/applied_job_controller.dart';
import 'package:BlueEra/features/common/jobs/controller/job_screen_controller.dart';
import 'package:BlueEra/features/common/jobs/view/all_job_post_screen.dart';
import 'package:BlueEra/features/common/jobs/view/all_saved_job_post_screen.dart';
import 'package:BlueEra/features/common/jobs/view/applied_screen/applied_jobs_screen.dart';
import 'package:BlueEra/features/common/jobs/widget/job_card.dart';
import 'package:BlueEra/features/common/jobs/widget/job_filter_dialog.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_enum.dart';
import '../../../../core/constants/size_config.dart';

class JobsScreen extends StatefulWidget {
  final bool isHeaderVisible;
  final Function(bool isVisible) onHeaderVisibilityChanged;

  JobsScreen({
    super.key,
    required this.isHeaderVisible,
    required this.onHeaderVisibilityChanged
  });

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<JobBusinessCategory> jobBusinessCategory =
      JobBusinessCategory.values;
  final List<JobIndividualCategory> jobIndividualCategory =
      JobIndividualCategory.values;
  int selectedIndex = 0;
  double _headerHeight = 0;
  final GlobalKey _headerKey = GlobalKey();
  final appliedJobController = Get.put(AppliedJobController());
  final jobScreenController = Get.put(JobScreenController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateHeaderHeight();
    });
    
    // Add listener to search text
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant JobsScreen oldWidget) {
    if (oldWidget.isHeaderVisible != widget.isHeaderVisible) {
      jobScreenController.isHeaderVisible.value = widget.isHeaderVisible;
      jobScreenController.headerOffset.value = 0.0;
    }
    super.didUpdateWidget(oldWidget);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    // Trigger rebuild to update cursor visibility
    setState(() {});
    // Debounce search to avoid too many API calls
    _debounceSearch();
  }
  
  // Debounce timer
  Timer? _debounce;
  
  void _debounceSearch() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Get status filter based on selected tab and account type
      String? status;
      
      if (isIndividual()) {
        // For PERSONAL accounts
        switch (selectedIndex) {
          case 0: // All Jobs
            status = 'all';
            break;
          case 1: // Applied
            status = 'applied';
            break;
          case 2: // Scheduled
            status = 'scheduled';
            break;
          case 3: // Saved
            status = 'saved';
            break;
        }
      } else if (isBusiness()) {
        // For BUSINESS accounts
        switch (selectedIndex) {
          case 0: // All Jobs
            status = 'all';
            break;
          case 1: // Scheduled
            status = 'scheduled';
            break;
          case 2: // Saved
            status = 'saved';
            break;
        }
      }
      // Execute search with status filter
      jobScreenController.searchJobsApi(_searchController.text, status: status);
    });
  }

  void _calculateHeaderHeight() {
    final renderBox =
        _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && mounted) {
      setState(() {
        _headerHeight = renderBox.size.height;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Obx(()=> Stack(
          children: [
            /// Main Scrollable Area with Dynamic Padding
            AnimatedPadding(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              padding: EdgeInsets.only(
                  top: (selectedIndex==3) ? _headerHeight * (1 - jobScreenController.headerOffset.value) + SizeConfig.size30 : _headerHeight * (1 - jobScreenController.headerOffset.value)),
                 child: isIndividual()
                  ? _buildSelectedIndividualJobTabContent()
                  : isBusiness()
                  ? _buildSelectedBusinessJobTabContent()
                  : SizedBox(),
            ),
        
            // Animated Sliding Header
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              top: -jobScreenController.headerOffset.value * _headerHeight,
              left: 0,
              right: 0,
              child: KeyedSubtree(
                key: _headerKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonBackAppBar(
                      isSearch: true,
                      isLeading: false,
                      controller: _searchController,
                      isShowCursor: _searchController.text.isNotEmpty, // Show cursor only when searching
                      onClearCallback: () {
                        _searchController.clear();
                        jobScreenController.clearSearch();
                        // Force rebuild to show original content
                        setState(() {});
                      },
                      isNotification: true,
                      onNotificationTap: () => Navigator.pushNamed(
                        context,
                        RouteHelper.getNotificationScreenRoute(),
                      ),
                      isResumeCardButton: (accountTypeGlobal.toUpperCase() ==
                          AppConstants.individual)
                          ? true
                          : false,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    (isIndividual())
                        ? HorizontalTabSelector(
                      tabs: jobIndividualCategory,
                      selectedIndex: selectedIndex,
                      onTabSelected: (index, value) {
                        _searchController.clear();
                        jobScreenController.clearSearch();
        
                        setState(() {
                          selectedIndex = index;
                        });
        
                        resetScrollingOnTabChanged();
        
                      },
                      labelBuilder: (jobCategory) {
                        return jobCategory.label;
                      },
                      isFilterIconShow: false,
                      onFitterTab: () => showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return JobFilterDialog();
                        },
                      ),
                    )
                        : (isBusiness())
                        ? HorizontalTabSelector(
                      tabs: jobBusinessCategory,
                      selectedIndex: selectedIndex,
                      onTabSelected: (index, value) {
                        _searchController.clear();
                        jobScreenController.clearSearch();
                        setState(() {
                          selectedIndex = index;
                        });
        
                        resetScrollingOnTabChanged();
                      },
                      labelBuilder: (jobCategory) {
                        return jobCategory.label;
                      },
                      isFilterIconShow: false,
                      onFitterTab: () => showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return JobFilterDialog();
                        },
                      ),
                    )
                        : SizedBox()
                  ],
                ),
              ),
            ),
          ],
         )
        ),
      ),
    );
  }

  // Update the tab content builders to handle search results
  Widget _buildSelectedBusinessJobTabContent() {
    // If searching, show search results filtered by tab
    if (jobScreenController.isSearching.value || 
        _searchController.text.isNotEmpty) {
      return Obx(() {
        if (jobScreenController.isSearching.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        final filteredResults = jobScreenController.getFilteredSearchResults(selectedIndex, false);
        
        if (filteredResults.isEmpty && _searchController.text.isNotEmpty) {
          return Center(child: CustomText("No search results found"));
        } else if (_searchController.text.isEmpty) {
          // If search is cleared, show original content
          return _getBusinessTabContent();
        }
        
        return ListView.builder(
          itemCount: filteredResults.length,
          padding: EdgeInsets.all(SizeConfig.size12),

          itemBuilder: (context, index) {
            return JobCard(
                job: filteredResults[index],
                headerHeight: _headerHeight,
            );
          },
        );
      });
    }

    // Otherwise show regular tab content
    return _getBusinessTabContent();
  }
  
  Widget _getBusinessTabContent() {
    switch (selectedIndex) {
      case 0:
        return AllJobPostScreen(
          key: ValueKey(AppConstants.All),
          onHeaderVisibilityChanged: _toggleAppBarBottomButtons,
          headerHeight: _headerHeight,
        );
      case 1:
        return AllJobPostScreen(
          key: ValueKey(AppConstants.SCHEDULES),
          onHeaderVisibilityChanged: _toggleAppBarBottomButtons,
          tabName: AppConstants.SCHEDULES,
          headerHeight: _headerHeight,
        );
      case 2:
        return AllSavedJobPostScreen(
            onHeaderVisibilityChanged: _toggleAppBarBottomButtons,
            headerHeight: _headerHeight,
        );
      default:
        return SizedBox();
    }
  }

  Widget _buildSelectedIndividualJobTabContent() {
    // If searching, show search results filtered by tab
    if (jobScreenController.isSearching.value || 
        _searchController.text.isNotEmpty) {
      return Obx(() {
        if (jobScreenController.isSearching.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        final filteredResults = jobScreenController.getFilteredSearchResults(selectedIndex, true);
        if (filteredResults.isEmpty && _searchController.text.isNotEmpty) {
          return Center(child: CustomText("No search results found"));
        } else if (_searchController.text.isEmpty) {
          // If search is cleared, show original content
          return _getIndividualTabContent();
        }
        
        return ListView.builder(
          itemCount: filteredResults.length,
          padding: EdgeInsets.all(SizeConfig.size12),

          itemBuilder: (context, index) {
            return JobCard(
                job: filteredResults[index],
              headerHeight: _headerHeight,
            );
          },
        );
      });
    }
    
    // Otherwise show regular tab content
    return _getIndividualTabContent();
  }
  
  Widget _getIndividualTabContent() {
    switch (selectedIndex) {
      case 0:
        return AllJobPostScreen(
          key: ValueKey(AppConstants.All),
          onHeaderVisibilityChanged: _toggleAppBarBottomButtons,
          headerHeight: _headerHeight,
        );
      case 1:
        return AppliedJobsScreen(
            key: ValueKey(AppConstants.Applied),
            onHeaderVisibilityChanged: _toggleAppBarBottomButtons,
            headerHeight: _headerHeight,
        );
      case 2:
        return AllJobPostScreen(
          key: ValueKey(AppConstants.SCHEDULES,),
           onHeaderVisibilityChanged: _toggleAppBarBottomButtons,
           tabName: AppConstants.SCHEDULES,
           headerHeight: _headerHeight,
        );
      case 3:
        return AllSavedJobPostScreen(
            key: ValueKey("SAVED"),
            onHeaderVisibilityChanged: _toggleAppBarBottomButtons,
            headerHeight: _headerHeight,
        );
      default:
        return SizedBox();
    }
  }

  void _toggleAppBarBottomButtons(bool visible) {
    if (widget.isHeaderVisible != visible && mounted) {
      jobScreenController.isHeaderVisible.value = visible;
      widget.onHeaderVisibilityChanged.call(visible); // Notify parent to hide/show bottom nav
    }
  }

  void resetScrollingOnTabChanged(){
    jobScreenController.isHeaderVisible.value = true;
    widget.onHeaderVisibilityChanged.call(jobScreenController.isHeaderVisible.value);
    jobScreenController.headerOffset.value = 0.0;
  }

}
