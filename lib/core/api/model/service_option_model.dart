import 'package:flutter/material.dart';

class ServiceMenuItem {
  final String? key;
  final String title;
  final String icon;
  final Widget Function() page;

  ServiceMenuItem({
     this.key,
    required this.title,
    required this.icon,
    required this.page,
  });
}