import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'reminder_chat_list.dart';

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
          "Reminder & To Do",
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        bottom: TabBar(
          controller: _tabController,
          dividerColor: AppColors.primaryColor.withOpacity(0.4),
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
                    "Reminder",
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
                    "To Do List",
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
          const SizedBox(),
        ],
      ),
    );
  }
}
