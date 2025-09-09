import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/widget/user_chip.dart';
import 'package:BlueEra/features/common/post/widget/user_list_item.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TagUserScreen extends StatefulWidget {

  TagUserScreen({Key? key}) : super(key: key);

  @override
  State<TagUserScreen> createState() => _TagUserScreenState();
}

class _TagUserScreenState extends State<TagUserScreen> {
  final controller = Get.find<TagUserController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    _scrollController.addListener(_scrollListener);
    super.initState();
  }


  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAtBottom = position.pixels >= position.maxScrollExtent - 200; // 100px threshold

    if (isAtBottom) {
      controller.fetchUsers();
    }
  }

  @override
  dispose(){
    _scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Add Tag',
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: SizeConfig.size16,
            left: SizeConfig.size16,
            right: SizeConfig.size16,
          ),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag People header
                    CustomText(
                      'Tag People',
                      fontSize: SizeConfig.size16,
                      fontWeight: FontWeight.w500,
                    ),
                    const SizedBox(height: 12),

                    // Search input field
                    CommonTextField(
                      onChange: controller.updateSearchQuery,
                      hintText: 'E.g. Sujoy Ghosh',
                      isValidate: false,
                    ),
                    // Max tag limit text
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Obx(() => CustomText(
                              'Only ${controller.maxTagLimit - controller.selectedUsers.length} persons You Can Tag Here',
                              fontSize: SizeConfig.size12,
                              color: Colors.grey.shade600,
                            )),
                      ),
                    ),

                    // Selected users chips
                    Obx(() => controller.selectedUsers.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Wrap(
                              children: controller.selectedUsers
                                  .map((user) => UserChip(
                                        user: user,
                                        onRemove: () =>
                                            controller.removeSelectedUser(user),
                                      ))
                                  .toList(),
                            ),
                          )
                        : const SizedBox.shrink()),

                    const SizedBox(height: 16),

                    // User list
                    Expanded(
                      child: Obx(() {
                        if (controller.isLoading.value) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (controller.filteredUsers.isEmpty) {
                          return Center(
                            child: CustomText(
                              'No users found',
                              fontSize: SizeConfig.size16,
                              color: Colors.grey.shade600,
                            ),
                          );
                        }

                        final itemCount =
                            controller.filteredUsers.length + (controller.isLoadingMore.value ? 1 : 0);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: itemCount,
                            itemBuilder: (context, index) {
                              if (index == controller.filteredUsers.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final user = controller.filteredUsers[index];
                              return UserListItem(
                                user: user,
                                onTap: () => controller.toggleUserSelection(user),
                              );
                            },
                          ),
                        );
                      }),
                    )

                  ],
                ),
              ),
              // Save button
              SizedBox(
                height: SizeConfig.size18,
              ),
              PositiveCustomBtn(
                  onTap: () {
                    Get.back(result: controller.selectedUsers);
                  },
                  title: "Save"),
              SizedBox(
                height: SizeConfig.size20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
