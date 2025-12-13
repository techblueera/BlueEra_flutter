import 'package:BlueEra/features/chat/view/add_symbol/widgets/bottom_caption_field.dart';

import 'package:BlueEra/features/chat/view/add_symbol/widgets/status_preview.dart';
import 'package:BlueEra/features/chat/view/add_symbol/widgets/top_left_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controller/add_chat_symbol_controller.dart';


class AddChatSymbolScreen extends StatelessWidget {
  AddChatSymbolScreen({super.key});

  final controller = Get.put(AddChatSymbolController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.0,vertical: 8),
              child: StatusPreview(),
            ),

            TopLeftOptions(),

            BottomCaptionField(),

          ],
        ),
      ),
    );
  }
}
