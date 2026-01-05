import 'package:flutter/material.dart';

import '../../auth/model/chat_theme_model.dart';
class ThemePreviewScreen extends StatefulWidget {
  final List<ChatTheme> themes;
  final int initialIndex;

  const ThemePreviewScreen({
    super.key,
    required this.themes,
    required this.initialIndex,
  });

  @override
  State<ThemePreviewScreen> createState() => _ThemePreviewScreenState();
}

class _ThemePreviewScreenState extends State<ThemePreviewScreen> {
  late PageController _controller;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preview"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () {
              // SAVE THEME HERE
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (index) {
          setState(() => currentIndex = index);
        },
        itemCount: widget.themes.length,
        itemBuilder: (_, index) {
          final theme = widget.themes[index];
          return ChatPreview(theme: theme);
        },
      ),
    );
  }
}
class ChatPreview extends StatelessWidget {
  final ChatTheme theme;

  const ChatPreview({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage(theme.backgroundColorPath)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: const Text(
                "This will replace your existing default chat theme.",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
