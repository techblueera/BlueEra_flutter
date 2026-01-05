import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_image_assets.dart';
import '../../auth/model/chat_theme_model.dart';
import 'chat_theme_preview.dart';
class ChatThemeScreen extends StatelessWidget {
  const ChatThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ChatTheme> chatThemes = [
      ChatTheme(
        id: "light",
        name: "Light",
        backgroundColorPath: AppImageAssets.chatBgLight,
      ),
      ChatTheme(
        id: "dark",
        name: "Dark",
        backgroundColorPath: AppImageAssets.chatBgDark,
      ),
      ChatTheme(
        id: "blue_shade",
        name: "Blue Shade",
        backgroundColorPath: AppImageAssets.chatBgBlueShade,
      ),
    ];

    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Chat Themes",
      ),
      body:Column(
        children: [
          Expanded(child:
          ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: chatThemes.length,
            itemBuilder: (context, index) {
              final theme = chatThemes[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ThemePreviewScreen(
                        themes: chatThemes,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(image: AssetImage(theme.backgroundColorPath)),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:  CustomText(
                        theme.name,
                        color: Colors.white
                      ),
                    ),
                  ),
                ),
              );
            }
          ))
        ],
      ),
    );
  }
}
