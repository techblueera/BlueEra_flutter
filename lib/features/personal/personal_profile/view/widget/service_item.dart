import 'dart:ui';

class ServiceItem {
  final String label;
  final String name;
  final String icon;
  final Color bgColor;
  final Color labelColor;
  const ServiceItem(

      {  required this.label,
        required this.name,
        required this.icon,
        required this.bgColor,
        required this.labelColor,
      });
}