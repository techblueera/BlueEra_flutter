import 'dart:ui';

class ServiceItem {
  final String label;
  final String icon;
  final Color bgColor;
  final Color labelColor;
  final String? id;
  const ServiceItem(this.label, this.icon, {required this.bgColor, required this.labelColor, this.id});
}