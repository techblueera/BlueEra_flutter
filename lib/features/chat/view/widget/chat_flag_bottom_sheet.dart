import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/custom_text_cm.dart';
import '../../auth/controller/chat_flag_controller.dart';
import '../../auth/model/chat_flag_model.dart';

class ChatFlagBottomSheet extends StatefulWidget {
  final String conversationId;

  const ChatFlagBottomSheet({super.key, required this.conversationId});

  @override
  State<ChatFlagBottomSheet> createState() => _ChatFlagBottomSheetState();
}

class _ChatFlagBottomSheetState extends State<ChatFlagBottomSheet> {
  final flagController = Get.find<ChatFlagController>();
  String? selectedFlagId;

  @override
  void initState() {
    super.initState();
    final existing = flagController.getFlagForConversation(widget.conversationId);
    selectedFlagId = existing?.id;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CustomText(
                "Label Chat",
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              TextButton(
                onPressed: () => _showAddNewLabelDialog(context),
                child: const CustomText(
                  "+ New Label",
                  color: AppColors.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: flagController.allFlags.length,
                itemBuilder: (context, index) {
                  final flag = flagController.allFlags[index];
                  final isSelected = selectedFlagId == flag.id;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (selectedFlagId == flag.id) {
                          selectedFlagId = null;
                        } else {
                          selectedFlagId = flag.id;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? flag.color.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: flag.color, width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: flag.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              flag.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomText(
                              flag.label,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle,
                                color: flag.color, size: 22),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              if (flagController.getFlagForConversation(widget.conversationId) !=
                  null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      flagController
                          .removeFlagFromConversation(widget.conversationId);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const CustomText(
                      "Remove Label",
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (flagController.getFlagForConversation(widget.conversationId) !=
                  null)
                const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: selectedFlagId == null
                      ? null
                      : () {
                          final flag = flagController.allFlags
                              .firstWhere((f) => f.id == selectedFlagId);
                          flagController.assignFlagToConversation(
                              widget.conversationId, flag);
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const CustomText(
                    "Apply",
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showAddNewLabelDialog(BuildContext context) {
    _showAddLabelDialog(context, flagController);
  }
}

void _showAddLabelDialog(BuildContext context, ChatFlagController flagController) {
  final nameController = TextEditingController();
  final emojiController = TextEditingController();
  Color selectedColor = Colors.blue;

  final List<Color> colorOptions = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.blueGrey,
  ];

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text("Add New Label"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Label Name",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emojiController,
                  decoration: InputDecoration(
                    labelText: "Emoji (e.g. \uD83D\uDCCC)",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Pick Color",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colorOptions.map((color) {
                    final isColorSelected = selectedColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isColorSelected
                              ? Border.all(color: Colors.black, width: 2.5)
                              : null,
                        ),
                        child: isColorSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final emoji = emojiController.text.trim();
                  if (name.isEmpty) return;

                  final flag = ChatFlagModel(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    label: name,
                    emoji: emoji.isEmpty ? '\uD83C\uDFF7\uFE0F' : emoji,
                    colorValue: selectedColor.toARGB32(),
                  );
                  flagController.addCustomFlag(flag);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                child: const Text("Add",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    },
  );
}

class ChatFlagDropdown extends StatefulWidget {
  final String conversationId;

  const ChatFlagDropdown({super.key, required this.conversationId});

  @override
  State<ChatFlagDropdown> createState() => _ChatFlagDropdownState();
}

class _ChatFlagDropdownState extends State<ChatFlagDropdown> {
  final flagController = Get.find<ChatFlagController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 6, top: 10, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CustomText(
                  "Label",
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                InkWell(
                  onTap: () {
                    Get.back();
                    _showAddLabelDialog(context, flagController);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: CustomText(
                      "+ New",
                      color: AppColors.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: Obx(() {
              final existingFlag =
                  flagController.getFlagForConversation(widget.conversationId);
              return ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: flagController.allFlags.length,
                itemBuilder: (context, index) {
                  final flag = flagController.allFlags[index];
                  final isSelected = existingFlag?.id == flag.id;
                  return InkWell(
                    onTap: () {
                      if (isSelected) {
                        flagController
                            .removeFlagFromConversation(widget.conversationId);
                      } else {
                        flagController.assignFlagToConversation(
                            widget.conversationId, flag);
                      }
                      Get.back();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 14),
                      color: isSelected
                          ? flag.color.withValues(alpha: 0.08)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          Text(flag.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomText(
                              flag.label,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check, color: flag.color, size: 18),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          Obx(() {
            final existingFlag =
                flagController.getFlagForConversation(widget.conversationId);
            if (existingFlag == null) return const SizedBox.shrink();
            return Column(
              children: [
                const Divider(height: 1),
                InkWell(
                  onTap: () {
                    flagController
                        .removeFlagFromConversation(widget.conversationId);
                    Get.back();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    child: Row(
                      children: [
                        Icon(Icons.close, color: AppColors.red, size: 16),
                        SizedBox(width: 10),
                        CustomText(
                          "Remove Label",
                          color: AppColors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
