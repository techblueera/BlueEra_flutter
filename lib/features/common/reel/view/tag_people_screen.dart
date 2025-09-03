import 'dart:async';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/reel/controller/tag_people_controller.dart';
import 'package:BlueEra/features/common/reel/widget/selectable_common_list_view.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
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
  final tagPeopleController = Get.put<TagPeopleController>(TagPeopleController());
  final TextEditingController searchController = TextEditingController();
  final List<String> allFriends = List.generate(6, (i) => 'Username');
  late Map<String, String> selectedItems;
  bool validate = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Attach listener
    searchController.addListener(_onSearchChanged);
    if(widget.previouslySelectedItems != null ){
      selectedItems = Map<String, String>.from(widget.previouslySelectedItems!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
       validateForm();
    });
    }else{
      selectedItems = {};
    }

  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _filterList(searchController.text.trim());
    });
  }

  void _filterList(String query) {
    if (query.isEmpty) {
      tagPeopleController.filteredUsers.assignAll(tagPeopleController.usersData);
      return;
    }

    final result = tagPeopleController.usersData.where((item) {
      final isIndividual = item.accountType.toUpperCase() == AppConstants.individual;
      final targetText = isIndividual
          ? '${item.username ?? ''} ${item.name ?? ''}'
          : item.businessName ?? '';
      return targetText.toLowerCase().contains(query.toLowerCase());
    }).toList();

    tagPeopleController.filteredUsers.assignAll(result);
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
      onTap: ()=> unFocus(),
      child: Scaffold(
        bottomNavigationBar:
        // Save button
        SafeArea(
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
                  child: CustomBtn(
                    title: "Save",
                    onTap: validate ? () {
                      Navigator.pop(context, selectedItems);
                    } : null,
                    isValidate: validate,
                  ),
                ),
              ],
            ),
          ),
        ),
        appBar: CommonBackAppBar(
          isSearch: true,
          controller: searchController,
          onClearCallback: (){
            searchController.clear();
          }
        ),
        body: Obx(
                ()=> tagPeopleController.isLoading.isFalse
            ? SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
                    child: Column(
                      children: [

                        // List of people
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: SizeConfig.size6),
                            child: tagPeopleController.filteredUsers.isNotEmpty ? // Declare this at the top of your state

                    SelectableCommonListView(
                    allItems: tagPeopleController.usersData,
                    isScrollable: true,
                    showSubTitle: true,
                    selectedIndexes: selectedItems.keys.toSet(),
                    onSelectionChanged: (String id, String name, bool isSelected) {
                      setState(() {
                        if (isSelected) {
                          selectedItems.remove(id);
                        } else {
                          selectedItems[id] = name;
                        }
                        validateForm();
                      });
                    },
                  )
                        : EmptyStateWidget(message: 'Not found any user'),
                          ),
                        ),

                        SizedBox(
                          height: SizeConfig.size8,
                        ),
                      ],
                    ),
                  ),
                ) : CircularProgressIndicator()
         ),
      ),
    );
  }

  ///VALIDATE FORM...
  void validateForm() {
    final hasSelectedItems = selectedItems.isNotEmpty;

    validate = hasSelectedItems;
    setState(() {});
  }


}
