import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommonDeleteDialog extends StatelessWidget {
  final VoidCallback onDeleteForMe;
  final VoidCallback? onDeleteForEveryone;
  final bool showDeleteForEveryone;
  final bool showDeleteFromDevice;
  final String title;

  const CommonDeleteDialog({
    super.key,
    required this.onDeleteForMe,
    this.onDeleteForEveryone,
    this.showDeleteForEveryone = false,
    this.showDeleteFromDevice = false,
    this.title = "",
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: CustomText(
        title.isEmpty ? AppStrings.areYouSureDelete.tr : title,
        color: Colors.black,
        fontSize: 16,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Delete for me
          _deleteButton(
            text: AppStrings.deleteForMe.tr,
            onTap: onDeleteForMe,
          ),

          if (showDeleteForEveryone && onDeleteForEveryone != null) ...[
            const SizedBox(height: 10),

            /// Delete for everyone (also removes from device if media)
            _deleteButton(
              text: showDeleteFromDevice
                  ? AppStrings.deleteForEveryoneDevice.tr
                  : AppStrings.deleteForEveryone.tr,
              onTap: onDeleteForEveryone!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _deleteButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: CustomText(
            text,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
