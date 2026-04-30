
import 'package:BlueEra/core/api/model/support_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/help_and_support_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/widgets/create_support_query_page.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../core/api/apiService/api_response.dart';

class QueriesCard extends StatefulWidget {
  @override
  _QueriesCardState createState() => _QueriesCardState();
}

class _QueriesCardState extends State<QueriesCard> {
  List<SupportCase> filteredList = [];
  final HelpAndSupportController helpController =
  Get.put(HelpAndSupportController());

  int selectedIndex = 0;

  final List<String> postTab = [
    "All",
    "Resolved",
    "In Progress",
    "Needs Attention"
  ];

  final TextEditingController _searchController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    helpController.getSupportQueries();

    _searchController.addListener(() {
      _applyFilter();
    });
  }
  void _applyFilter() {
    List<SupportCase> tempList = List.from(helpController.allList);

    /// STATUS FILTER
    if (selectedIndex != 0) {
      String status = '';
      switch (selectedIndex) {
        case 1:
          status = 'resolved';
          break;
        case 2:
          status = 'in-progress';
          break;
        case 3:
          status = 'open'; // Needs Attention
          break;
      }

      tempList = tempList.where((e) => e.status == status).toList();
      final searchText = _searchController.text.trim().toLowerCase();
      if (searchText.isNotEmpty) {
        tempList = tempList
            .where((e) =>
            (e.subject?.toLowerCase() ?? '').toLowerCase().contains(searchText.toLowerCase()))
            .toList();
      }

      setState(() {
        filteredList = tempList;
      });
    }

    /// SEARCH FILTER

  }
  //
  // Future<void> _performSearch(String caseId) async {
  //   setState(() {
  //     isLoading = true;
  //     list.clear();
  //   });
  //
  //   await helpController.getSearchById(caseId);
  //
  //   setState(() {
  //     list = helpController.allList;
  //     isLoading = false;
  //   });
  // }

  // Future<void> _fetchDataForTab(int index) async {
  //   setState(() {
  //     selectedIndex = index;
  //     isLoading = true;
  //     list.clear();
  //   });
  //
  //   final statusMap = {
  //     0: '--',
  //     1: "Resolved",
  //     2: "In Progress",
  //     3: "Needs Attention",
  //   };
  //
  //   final query = statusMap[index] ?? "--"; // "--" for All tab
  //
  //   await helpController.getSupportQuery(query);
  //
  //   setState(() {
  //     list = helpController.allList;
  //     isLoading = false;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Queries",
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.white
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    // width: 300,
                    child: CommonSearchBar(
                      backgroundColor: AppColors.whiteE5.withValues(alpha: 0.5),
                      controller: _searchController,
                      onSearchTap: () {
                        FocusScope.of(context).unfocus();
                        _applyFilter();
                      },
                      onClearCallback: () {
                        _searchController.clear();
                        _applyFilter();
                      },
                    ),
                  ),
                  SizedBox(width: 10,),
                  CustomBtn(
                      height: 40,
                      width: 90,
                      isValidate: true,
                      onTap: () {
                        Get.to(()=>CreateSupportQueryPage());
                      },
                      title: "Ask Queries")
                ],
              ),
              SizedBox(height: SizeConfig.size20),
              Row(
                children: [
                  for (int i = 0; i < postTab.length; i++)
                    InkWell(
                      onTap: () {
                        setState(() {
                          selectedIndex = i;
                        });
                        _applyFilter();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: CustomText(
                          postTab[i],
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          color: selectedIndex==i?AppColors.primaryColor:AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              // HorizontalTabSelector(
              //   tabs: postTab,
              //   selectedIndex: selectedIndex,
              //   onTabSelected: (index, value) {
              //     setState(() {
              //       selectedIndex = index;
              //     });
              //     _applyFilter();
              //   },
              //   labelBuilder: (label) => label,
              // ),
              SizedBox(height: SizeConfig.size10),
              Obx(() {
                if (helpController.getQueryResponse.value.status ==
                    Status.COMPLETE) {

                  if (filteredList.isEmpty&&selectedIndex==0) {
                    filteredList = helpController.allList;
                  }

                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.white,
                      ),
                      // padding: const EdgeInsets.all(16),
                      child: buildQueryList(filteredList),
                    ),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  //
  // Widget _buildSelectedTabContent(List<SupportCase> list) {
  //   switch (selectedIndex) {
  //     case 0:
  //       return buildQueryList(list);
  //     case 1:
  //       return buildQueryList(list);
  //     case 2:
  //       return buildQueryList(list);
  //     case 3:
  //       return buildQueryList(list);
  //     default:
  //       return SizedBox();
  //   }
  // }
  Color getStatusColor(String? status) {
    switch (status) {
      case 'open':
        return Colors.orange;

      case 'in-progress':
        return Colors.blue;

      case 'resolved':
        return Colors.green;

      case 'closed':
        return Colors.grey;

      default:
        return Colors.black54;
    }
  }
  Widget buildQueryList(List<SupportCase> list) {
    if (list.isEmpty) {
      return Center(child: Text("No data found."));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    item.subject,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  CustomText(
                    DateFormat('MMM d')
                        .format(DateTime.parse(item.createdAt.toString())),
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                    color:AppColors.secondaryTextColor,
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    "Priority: ${item.priority}",
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                    color:AppColors.secondaryTextColor,

                  ),
                  CustomText(
                    item.status,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w400,
                    color: getStatusColor(item.status),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Divider(height: 20, thickness: 1,
              color: AppColors.whiteE5,),
            ],
          ),
        );
      },
    );
  }

}
