import 'package:flutter/material.dart';

class CommonDeleteDialog extends StatelessWidget {
  final VoidCallback onDeleteForMe;
  final VoidCallback? onDeleteForEveryone;
  final bool showDeleteForEveryone;
  final String title;

  const CommonDeleteDialog({
    super.key,
    required this.onDeleteForMe,
    this.onDeleteForEveryone,
    this.showDeleteForEveryone = false,
    this.title = "Are you sure you want to delete?",
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.black),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Delete for me
          _deleteButton(
            text: "Delete for me",
            onTap: onDeleteForMe,
          ),

          if (showDeleteForEveryone && onDeleteForEveryone != null) ...[
            const SizedBox(height: 10),

            /// Delete for everyone
            _deleteButton(
              text: "Delete for everyone",
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
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}