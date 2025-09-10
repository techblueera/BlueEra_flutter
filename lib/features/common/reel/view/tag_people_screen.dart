import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/reel/controller/tag_people_controller.dart';
import 'package:BlueEra/features/common/reel/widget/selectable_common_list_view.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TagPeopleScreen extends StatefulWidget {
  final Map<String, String>? previouslySelectedItems;
  const TagPeopleScreen({Key? key, required this.previouslySelectedItems}) : super(key: key);

  @override
  State<TagPeopleScreen> createState() => _TagPeopleScreenState();
}

class _TagPeopleScreenState extends State<TagPeopleScreen> {
  final tagPeopleController = Get.put(TagPeopleController());
  final ScrollController _scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);

    // set previously selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tagPeopleController.getAllKindOfUsers(isInitialLoad: true);
      tagPeopleController.setPreviouslySelected(widget.previouslySelectedItems);
    });

    _scrollController.addListener(_scrollListener);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _filterList(searchController.text.trim());
    });
  }

  void _filterList(String query) {
    // print("Searching for: $query");
    // print("usersData length: ${tagPeopleController.usersData.length}");

    if (query.isEmpty) {
      // Restore original list
      tagPeopleController.filteredUsers.assignAll(tagPeopleController.usersData);
      print("Reset to full list: ${tagPeopleController.filteredUsers.length}");
      return;
    }

    final result = tagPeopleController.usersData.where((item) {
      final isIndividual = item.accountType.toUpperCase() == AppConstants.individual;
      final targetText = isIndividual
          ? (item.name ?? '')
          : (item.businessName ?? '');
      return targetText.toLowerCase().contains(query.toLowerCase());
    }).toList();

    print("Found results: ${result.length}");
    tagPeopleController.filteredUsers.assignAll(result);
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAtBottom = position.pixels >= position.maxScrollExtent - 200; // 100px threshold

    if (isAtBottom) {
      // Trigger pagination for individual page
       tagPeopleController.getAllKindOfUsers();
      // api call

    }
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => unFocus(),
      child: Scaffold(
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
            child: Row(
              children: [
                Expanded(
                  child: CustomBtn(
                    title: "Cancel",
                    onTap: () {
                      Navigator.pop(context, null);
                    },
                    borderColor: AppColors.secondaryTextColor,
                    bgColor: AppColors.white,
                    isValidate: false,
                    textColor: AppColors.black,
                  ),
                ),
                SizedBox(width: SizeConfig.size10),
                Expanded(
                  child: Obx(() => CustomBtn(
                    title: "Save",
                    onTap: tagPeopleController.validate.value
                        ? () {
                      Navigator.pop(context, tagPeopleController.selectedItems);
                    }
                        : null,
                    isValidate: tagPeopleController.validate.value,
                  )),
                ),
              ],
            ),
          ),
        ),
        appBar: CommonBackAppBar(
            isSearch: true,
            controller: searchController,
            onClearCallback: () {
              searchController.clear();
            }),
        body: Obx(() {

          if(tagPeopleController.isLoading.isTrue){
            return const Center(child: CircularProgressIndicator());
          }

          if(tagPeopleController.allUsersResponse.value.status == Status.COMPLETE){
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Max tag limit text
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: SizeConfig.size8,
                              bottom: SizeConfig.size8,
                              right: SizeConfig.size15
                          ),
                          child: Obx(() => CustomText(
                            'Only ${tagPeopleController.maxTagLimit - tagPeopleController.selectedItems.length} persons You Can Tag Here',
                            fontSize: SizeConfig.size12,
                            color: Colors.grey.shade600,
                          )),
                        ),
                      ),

                      // Selected users chips
                      Padding(
                        padding: EdgeInsets.only(
                          left: SizeConfig.size15,
                          right: SizeConfig.size15,
                        ),
                        child: Obx(() => Wrap(
                          spacing: 10,
                          runSpacing: 2,
                          children: tagPeopleController.selectedItems.entries.map((entry) {
                            final id = entry.key;
                            final name = entry.value;

                            return Chip(
                              label: Text(name),
                              backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                              labelStyle: TextStyle(
                                  color: AppColors.mainTextColor,
                                  fontWeight: FontWeight.w400,
                                  fontSize: SizeConfig.large),
                              deleteIcon:
                              const Icon(Icons.close, size: 20, color: AppColors.mainTextColor),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: Colors.transparent),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              onDeleted: () {
                                tagPeopleController.removeSelected(id);
                              },
                            );
                          }).toList(),
                        )),
                      ),

                      // List of people
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
                          child: Obx(() => tagPeopleController.filteredUsers.isNotEmpty
                              ? SelectableCommonListView(
                            scrollController: _scrollController,
                            allItems: tagPeopleController.filteredUsers,
                            isScrollable: true,
                            showSubTitle: true,
                            selectedIndexes: tagPeopleController.selectedItems.keys.toSet(),
                            onSelectionChanged: (String id, String name, bool isSelected) {

                              tagPeopleController.toggleSelection(id, name);
                            },
                          )
                              : EmptyStateWidget(message: 'Not found any user')),
                        ),
                      ),
                      SizedBox(height: SizeConfig.size8),
                    ],
                  ),
                ),
              ),
            );
          }else if(tagPeopleController.allUsersResponse.value.status == Status.ERROR){
            return Center(
              child: CustomBtn(
                  onTap: (){
                    tagPeopleController.getAllKindOfUsers();
                  },
                  title: 'Retry'
              ),
            );
          }
          return SizedBox();
        }),
      ),
    );
  }
}

