import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:get/get.dart';
import 'reminder_chat_list.dart';
import 'todo_list_view.dart';

class ReminderTodoScreen extends StatefulWidget {
  const ReminderTodoScreen({super.key});

  @override
  State<ReminderTodoScreen> createState() => _ReminderTodoScreenState();
}

class _ReminderTodoScreenState extends State<ReminderTodoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fillColor,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomText(
          AppStrings.reminderAndToDo.tr,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        bottom: TabBar(
          controller: _tabController,
          dividerColor: AppColors.primaryColor.withValues(alpha: 0.4),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.lightBlue,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LocalAssets(
                    imagePath: AppIconAssets.clock_new,
                    height: 18,
                    width: 18,
                  ),
                  const SizedBox(width: 12),
                  CustomText(
                    AppStrings.reminderLabel.tr,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LocalAssets(
                    imagePath: AppImageAssets.chat_tab_to_do,
                    height: 18,
                    width: 18,
                  ),
                  const SizedBox(width: 12),
                  CustomText(
                    AppStrings.toDoList.tr,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ReminderChatList(),
          const TodoListView(),
        ],
      ),
    );
  }
}

/// Empty state for the Reminder tab — bell/clock themed.
class ReminderEmptyState extends StatelessWidget {
  const ReminderEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration circle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE3F2FD),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 56,
                    color: const Color(0xFF42A5F5),
                  ),
                  Positioned(
                    top: 22,
                    right: 28,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEF5350),
                      ),
                      child: const Center(
                        child: Text(
                          '0',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            CustomText(
              AppStrings.noRemindersYet.tr,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
            const SizedBox(height: 10),
            CustomText(
              AppStrings.remindersAppearHere.tr,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.grey9A,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

