import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/controller/add_chat_symbol_controller.dart';

class PostButton extends StatelessWidget {
  const PostButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AddChatSymbolController>();

    return GestureDetector(
      onTap: () => c.submitPost(),
      child: Container(
        width: 50,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.arrow_forward_ios_outlined,
          color: AppColors.primaryColor,
          size: 26,
        ),
      ),
    );
  }
}
