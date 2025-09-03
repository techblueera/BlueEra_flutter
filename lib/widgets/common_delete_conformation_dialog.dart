import 'package:flutter/material.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onDelete;

  const ConfirmDeleteDialog({
    super.key,
    this.title = "Confirm Delete",
    this.content = "Are you sure you want to delete this item?",
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDelete();
          },
          child: const Text(
            "Delete",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
