import 'package:flutter/material.dart';

class ServiceMenuItem {
  final String title;
  final String icon;
  final Widget Function() page;

  ServiceMenuItem({
    required this.title,
    required this.icon,
    required this.page,
  });
}