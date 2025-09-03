import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class CloseFriendsScreen extends StatefulWidget {
  const CloseFriendsScreen({super.key});

  @override
  State<CloseFriendsScreen> createState() => _CloseFriendsScreenState();
}

class _CloseFriendsScreenState extends State<CloseFriendsScreen> {
  final TextEditingController searchController = TextEditingController();
  final List<String> allFriends = List.generate(6, (i) => 'Username');
  final List<String> suggestedFriends = List.generate(8, (i) => 'Rahul');
  final Set<int> selectedIndexes = {0, 1, 2}; // first 3 selected by default
  final Set<int> selectedSugFrnIndexes = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        // isLeading: true,
        isSearch: true,
        controller: searchController,
        onClearCallback: (){
          searchController.clear();
        }
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding:  EdgeInsets.symmetric(horizontal: SizeConfig.size20),
          child: CustomBtn(
            title: "Save",
            onTap: () {
        
            },
            isValidate: true,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        LocalAssets(imagePath: AppIconAssets.peoplesIconYellow),
                        SizedBox(width: SizeConfig.size10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                                "Close Friends",
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w700,
                            ),
                            SizedBox(height: SizeConfig.size2),
                            CustomText(
                                "5 people",
                                fontSize: SizeConfig.extraSmall,
                                color: AppColors.primaryColor
                            ),
                          ],
                        )
                      ],
                    ),
                    TextButton(
                      onPressed: () {

                      },
                      child: CustomText(
                          "Clear all",
                          fontSize: SizeConfig.medium,
                          color: AppColors.primaryColor
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size15),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        CommonHorizontalDivider(),
                        SizedBox(
                          height: SizeConfig.size8,
                        ),

                        /// close friends
                        // SelectableCommonListView(
                        //   allItems: allFriends,
                        //   selectedIndexes: selectedIndexes,
                        //   onSelectionChanged: (index, isSelected) {
                        //     setState(() {
                        //       isSelected ? selectedIndexes.remove(index) : selectedIndexes.add(index);
                        //     });
                        //   },
                        // ),
                        SizedBox(
                          height: SizeConfig.size8,
                        ),

                        /// Suggested Close Friends
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child:
                            CustomText(
                                "Suggested",
                                fontSize: SizeConfig.large,
                                fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: SizeConfig.size20,
                        ),
                        CommonHorizontalDivider(),
                        SizedBox(
                          height: SizeConfig.size8,
                        ),
                        // SelectableCommonListView(
                        //   allItems: suggestedFriends,
                        //   selectedIndexes: selectedSugFrnIndexes,
                        //   onSelectionChanged: (index, isSelected) {
                        //     setState(() {
                        //       isSelected ? selectedSugFrnIndexes.remove(index) : selectedSugFrnIndexes.add(index);
                        //     });
                        //   },
                        // ),
                      ],
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }



}
