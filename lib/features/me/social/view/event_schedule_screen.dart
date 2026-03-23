import 'package:BlueEra/core/api/model/social_event_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/social/controller/social__event_controller.dart';
import 'package:BlueEra/features/me/social/view/social_create_event_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EventScheduleScreen extends StatelessWidget {
  final controller = Get.put(SocialEventController());

  EventScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.eventsSchedule),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.resetForm();
          Get.to(() => SocialCreateEventScreen());
        },
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: CustomText(AppStrings.createEvent,
            color: Colors.white,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600),
      ),
      body: Obx(() {
        if (controller.isListLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.eventList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                CustomText(AppStrings.noEventsFound,
                    color: AppColors.secondaryTextColor,
                    fontSize: SizeConfig.medium),
                const SizedBox(height: 8),
                CustomText("Tap + to create your first event",
                    color: Colors.grey[400], fontSize: SizeConfig.small),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(SizeConfig.paddingM),
          itemCount: controller.eventList.length,
          itemBuilder: (context, index) {
            final event = controller.eventList[index];
            return _buildEventCard(context, event);
          },
        );
      }),
    );
  }

  Widget _buildEventCard(BuildContext context, SocialEventData event) {
    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event header with gradient
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withValues(alpha: 0.8),
                  AppColors.primaryColor.withValues(alpha: 0.5),
                ],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        event.title ?? "No Title",
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.eventType != null &&
                          event.eventType!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CustomText(event.eventType ?? "",
                              color: Colors.white,
                              fontSize: SizeConfig.extraSmall),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  height: 28,
                  width: 28,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.more_vert,
                        color: Colors.white, size: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    onSelected: (value) {
                      if (value == 'edit') {
                        controller.initForEdit(event);
                        Get.to(() => SocialCreateEventScreen());
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context, event);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                color: AppColors.primaryColor, size: 18),
                            const SizedBox(width: 8),
                            CustomText(AppStrings.edit),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            CustomText(AppStrings.delete,
                                color: Colors.red),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Event details
          Padding(
            padding: EdgeInsets.all(SizeConfig.paddingM),
            child: Column(
              children: [
                _buildDetailRow(
                    Icons.calendar_today_outlined,
                    AppStrings.date,
                    event.startDate != null
                        ? _formatDate(event.startDate!)
                        : "N/A"),
                SizedBox(height: SizeConfig.paddingXS),
                _buildDetailRow(
                    Icons.access_time,
                    AppStrings.timing,
                    "${event.timing?.from ?? ''} to ${event.timing?.to ?? ''}"),
                SizedBox(height: SizeConfig.paddingXS),
                _buildDetailRow(Icons.location_on_outlined,
                    AppStrings.location, event.venue?.name ?? "N/A"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryTextColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: CustomText(
            "$label:",
            color: AppColors.secondaryTextColor,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: CustomText(
            value,
            color: AppColors.mainTextColor,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w600,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, SocialEventData event) async {
    await showCommonDialog(
        context: context,
        text: AppStrings.deleteEventConfirm,
        confirmCallback: () async {
          Get.back();
          controller.eventId = event.sId;
          controller.deleteEvent();
        },
        cancelCallback: () {
          Navigator.of(context).pop();
        },
        confirmText: AppStrings.yes,
        cancelText: AppStrings.no);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
