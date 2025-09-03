import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

Widget setupPageVisibilityNotification({
  required PageController controller,
  required Widget child,
  required void Function(bool) onVisibilityChanged,
}) {
  return NotificationListener<ScrollNotification>(
    onNotification: (notification) {
      // Only react to UserScrollNotification from this controller
      if (notification is UserScrollNotification &&
          notification.metrics.axis == Axis.vertical) {
        final direction = notification.direction;
        if (direction == ScrollDirection.reverse) {
          onVisibilityChanged(false); // scrolling down → hide header
        } else if (direction == ScrollDirection.forward) {
          onVisibilityChanged(true);  // scrolling up → show header
        }
      }
      return false;
    },
    child: child,
  );
}