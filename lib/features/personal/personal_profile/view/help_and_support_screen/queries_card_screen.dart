import 'package:BlueEra/core/api/model/support_model.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/help_and_support_screen/help_and_support_controller.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class QueriesCard extends StatefulWidget {
  @override
  _QueriesCardState createState() => _QueriesCardState();
}

class _QueriesCardState extends State<QueriesCard> {
  List<SupportCase> list = [];
  final HelpAndSupportController helpController =
  Get.put(HelpAndSupportController());

  int selectedIndex = 0;

  final List<String> postTab = [
    "All",
    "Resolved",
    "In Progress",
    "Needs Attention"
  ];

  final ValueNotifier<String> _searchTextNotifier = ValueNotifier('');
  final TextEditingController _searchController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDataForTab(0); // Initial load
  }

  Future<void> _performSearch(String caseId) async {
    setState(() {
      isLoading = true;
      list.clear();
    });

    await helpController.getSearchById(caseId);

    setState(() {
      list = helpController.allList;
      isLoading = false;
    });
  }

  Future<void> _fetchDataForTab(int index) async {
    setState(() {
      selectedIndex = index;
      isLoading = true;
      list.clear();
    });

    final statusMap = {
      0: '--',
      1: "Resolved",
      2: "In Progress",
      3: "Needs Attention",
    };

    final query = statusMap[index] ?? "--"; // "--" for All tab

    await helpController.getSupportQuery(query);

    setState(() {
      list = helpController.allList;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonSearchBar(
            backgroundColor: Colors.grey[300],
            controller: _searchController,
            onSearchTap: () {
              FocusScope.of(context).unfocus(); // Hide keyboard
              final query = _searchTextNotifier.value.trim();
              if (query.isNotEmpty) {
                _performSearch(query);
              } else {
                _fetchDataForTab(selectedIndex); // fallback to list
              }
            },
            onClearCallback: () {
              _searchController.clear();
              _searchTextNotifier.value = '';
              _fetchDataForTab(selectedIndex); // show default data again
            },
          ),
          SizedBox(height: SizeConfig.size20),
          HorizontalTabSelector(
            tabs: postTab,
            selectedIndex: selectedIndex,
            onTabSelected: (index, value) async {
              _searchController.clear(); // clear previous search
              _searchTextNotifier.value = ''; // reset
              _fetchDataForTab(index);
            },
            labelBuilder: (label) => label,
          ),
          SizedBox(height: SizeConfig.size10),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildSelectedTabContent(list),
          ),
        ],
      ),
    );
  }


  Widget _buildSelectedTabContent(List<SupportCase> list) {
    switch (selectedIndex) {
      case 0:
        return buildQueryList(list);
      case 1:
        return buildQueryList(list);
      case 2:
        return buildQueryList(list);
      case 3:
        return buildQueryList(list);
      default:
        return SizedBox();
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

        Color statusColor;
        switch (item.status) {
          case 'Resolved':
            statusColor = Colors.green;
            break;
          case 'In Progress':
            statusColor = Colors.orange;
            break;
          case 'Needs Attention':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.grey;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: CustomText(
                        item.message,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      )
                    // Text(
                    //   item.message,
                    //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    // ),
                  ),
                  CustomText(
                    DateFormat('MMM d')
                        .format(DateTime.parse(item.createdAt.toString())),
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    "Case ID: ${item.caseId}",
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                  CustomText(
                    item.status,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ],
              ),
              Divider(height: 20, thickness: 1),
            ],
          ),
        );
      },
    );
  }

}
