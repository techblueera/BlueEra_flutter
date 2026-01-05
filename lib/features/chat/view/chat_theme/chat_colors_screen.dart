import 'package:flutter/material.dart';
class ChatColorScreen extends StatelessWidget {
  final List<Color> colors = [
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.blue,
    Colors.teal,
    Colors.red,
    Colors.black,
    Colors.brown,
  ];

  ChatColorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat color")),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: colors.length,
        itemBuilder: (_, index) {
          return GestureDetector(
            onTap: () {
              // APPLY CHAT COLOR
              Navigator.pop(context);
            },
            child: CircleAvatar(
              radius: 30,
              backgroundColor: colors[index],
            ),
          );
        },
      ),
    );
  }
}
