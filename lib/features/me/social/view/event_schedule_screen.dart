import 'package:BlueEra/core/api/model/social_event_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/social/controller/social__event_controller.dart';
import 'package:BlueEra/features/me/social/view/social_create_event_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EventScheduleScreen extends StatelessWidget {
  final controller = Get.put(SocialEventController());

  @override
  Widget build(BuildContext context) {
    // Ensure SizeConfig is initialized if not already (though usually done in main)
    // SizeConfig.init(context);

    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: CommonBackAppBar(
        title: "Events / Schedule",
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 30.0),
        child: CommonCardWidget(
          padding: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(SizeConfig.paddingM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      "Events",
                        fontSize: SizeConfig.large18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                    ),
                    InkWell(
                      onTap: () {
                        controller.resetForm();
                        Get.to(() => SocialCreateEventScreen());
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.paddingXS,
                            vertical: SizeConfig.paddingXSmall),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add,
                                color: AppColors.primaryColor,
                                size: SizeConfig.large),
                            SizedBox(width: 4),
                            CustomText(
                              "Add More",
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: SizeConfig.small,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isListLoading.value) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (controller.eventList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy,
                              size: 64, color: Colors.grey.shade300),
                          SizedBox(height: 16),
                          CustomText(
                            "No events found",
                              color:AppColors.secondaryTextColor,
                              fontSize: SizeConfig.medium,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding:
                        EdgeInsets.symmetric(horizontal: SizeConfig.paddingM),
                    itemCount: controller.eventList.length,
                    itemBuilder: (context, index) {
                      final event = controller.eventList[index];
                      return _buildEventCard(context, event);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(SizeConfig.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header

            // --- HEADER WITH POPUP MENU ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomText(
                    event.title ?? "No Title",
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  height: 24,
                  width: 24,
                  child: PopupMenuButton<String>(
                    // 1. Remove the default padding
                    padding: EdgeInsets.zero,

                    // 2. Override default constraints to remove the minimum touch target margin
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
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
                                color: Colors.blue, size: 20),
                            SizedBox(width: 10),
                            CustomText("Edit Event"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            SizedBox(width: 10),
                            CustomText("Delete", color: Colors.red),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Divider(
                height: SizeConfig.paddingM,
                thickness: 1,
                color: Colors.grey.shade100),
            // Details
            _buildDetailRow("Title", event.title ?? "No Title"),
            SizedBox(height: SizeConfig.paddingXS),
            _buildDetailRow(
                "Date",
                event.startDate != null
                    ? _formatDate(event.startDate!)
                    : "N/A"),
            SizedBox(height: SizeConfig.paddingXS),
            _buildDetailRow("Time",
                "${event.timing?.from ?? ''} to ${event.timing?.to ?? ''}"),
            SizedBox(height: SizeConfig.paddingXS),
            _buildDetailRow("Ticket", "Free"),
            SizedBox(height: SizeConfig.paddingXS),
            _buildDetailRow("Location", event.venue?.name ?? "N/A"),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: CustomText(
            "$label:",
              color: Colors.grey.shade600,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: CustomText(
            value,
              color: Colors.black87,
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
        text:
            "Are you sure you want to delete this event?\nThis action cannot be undone.",
        confirmCallback: () async {
          Get.back();
          controller.eventId = event.sId;
          controller.deleteEvent();
        },
        cancelCallback: () {
          Navigator.of(context).pop(); // Close the dialog
        },
        confirmText: AppStrings.yes,
        cancelText: AppStrings.no);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
