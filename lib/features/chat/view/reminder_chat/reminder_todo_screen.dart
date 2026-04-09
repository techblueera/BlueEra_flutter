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
          const _TodoEmptyState(),
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
              "No Reminders Yet",
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
            const SizedBox(height: 10),
            CustomText(
              "Your reminders will appear here.\nSet a reminder from any chat message\nto stay on track.",
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

/// Empty state for the To Do tab — checklist themed.
class _TodoEmptyState extends StatelessWidget {
  const _TodoEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration — stacked checklist cards
            SizedBox(
              width: 140,
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back card
                  Positioned(
                    top: 10,
                    child: Container(
                      width: 110,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFC8E6C9),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  // Front card
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 120,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCheckRow(true, 68),
                          const SizedBox(height: 10),
                          _buildCheckRow(false, 80),
                          const SizedBox(height: 10),
                          _buildCheckRow(false, 52),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            CustomText(
              "No To-Do Items",
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
            const SizedBox(height: 10),
            CustomText(
              "Your to-do list is empty.\nCreate tasks to keep track of things\nyou need to get done.",
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

  Widget _buildCheckRow(bool checked, double lineWidth) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: checked ? const Color(0xFF66BB6A) : Colors.transparent,
            border: Border.all(
              color: checked ? const Color(0xFF66BB6A) : const Color(0xFFBDBDBD),
              width: 1.5,
            ),
          ),
          child: checked
              ? const Icon(Icons.check, size: 11, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 4),
        Container(
          height: 8,
          width: lineWidth-8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: checked
                ? const Color(0xFFE0E0E0)
                : const Color(0xFFEEEEEE),
          ),
        ),
      ],
    );
  }
}
