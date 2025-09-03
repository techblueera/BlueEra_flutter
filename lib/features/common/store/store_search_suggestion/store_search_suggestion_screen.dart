import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'store_search_suggestion_controller.dart';

class StoreSearchSuggestionScreen extends StatelessWidget {
  const StoreSearchSuggestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoreSearchSuggestionController>(
      init: StoreSearchSuggestionController(),
      builder: (controller) {
        return Scaffold(
          // backgroundColor: AppColors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Header Section with Search Bar
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16,
                    vertical: SizeConfig.size12,
                  ),
                  child: Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.black,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: SizeConfig.size12),
                      Expanded(
                        child: CommonTextField(
                          textEditController: controller.searchController,
                          onChange: (value) {
                            controller.searchBusinesses(value);
                          },
                          hintText: 'Search businesses...',
                          isValidate: false,

                        ),
                      ),
                      // Search Bar
                    /*  Expanded(
                        child: Container(
                          height: 45,
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.fillColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.greyE5,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search,
                                color: AppColors.grey9B,
                                size: 20,
                              ),
                              SizedBox(width: SizeConfig.size8),
                              Expanded(
                                child: TextField(
                                  controller: controller.searchController,
                                  style: const TextStyle(
                                    color: AppColors.black,
                                    fontSize: 14,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Search businesses...',
                                    hintStyle: TextStyle(
                                      color: AppColors.grey9B,
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (value) {
                                    controller.searchBusinesses(value);
                                  },
                                ),
                              ),
                              if (controller.searchController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    controller.searchController.clear();
                                    controller.clearSearchResults();
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: AppColors.grey9B,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),*/
                    ],
                  ),
                ),

                // Content Sections
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (controller.searchResults.isEmpty && controller.searchController.text.isNotEmpty) {
                      return Center(child: CustomText('No results found'));
                    } else if (controller.searchResults.isEmpty) {
                      return Center(child: CustomText('Search for businesses'));
                    } else {
                      return ListView.builder(
                        itemCount: controller.searchResults.length,
                        itemBuilder: (context, index) {
                          final business = controller.searchResults[index];
                          return ListTile(
                            title: CustomText(
                              business.businessName ?? 'Unknown Business',
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w500,
                            ),
                            subtitle: business.categoryOfBusiness?.name != null
                                ? CustomText(
                                    business.categoryOfBusiness!.name,
                                    fontSize: SizeConfig.small,
                                    color: AppColors.secondaryTextColor,
                                  )
                                : null,
                            onTap: () {
                              controller.onBusinessSelected(business,context);
                            },
                          );
                        },
                      );
                    }
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}