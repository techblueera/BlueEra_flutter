import 'dart:ui';
import 'package:flutter/material.dart';
class ChatTheme {
  final String id;
  final String name;

  final String backgroundColorPath;
  final String? wallpaper;

  ChatTheme({
    required this.id,
    required this.name,
    required this.backgroundColorPath,
    this.wallpaper,
  });
}
