import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatWallpaperScreen extends StatelessWidget {
  final List<String> wallpapers = [
    "assets/wall1.png",
    "assets/wall2.png",
    "assets/wall3.png",
  ];

  ChatWallpaperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: CustomText(AppStrings.wallpaperLabel.tr)),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: wallpapers.length,
        itemBuilder: (_, index) {
          return GestureDetector(
            onTap: () {
              // APPLY WALLPAPER
              Navigator.pop(context);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                wallpapers[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
