import 'dart:ui';

class ServiceItem {
  final String name;
  final String slugId;
  final String icon;
  final Color bgColor;
  final Color labelColor;
  const ServiceItem(

      {  required this.name,
        required this.slugId,
        required this.icon,
        required this.bgColor,
        required this.labelColor,
      });
}