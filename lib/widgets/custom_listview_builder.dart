import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CustomListViewBuilder<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool? primary;
  final ScrollController? controller;
  final Widget? separator;
  final int? itemCount;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double? cacheExtent;
  final DragStartBehavior dragStartBehavior;
  final IndexedWidgetBuilder? separatorBuilder;
  final Clip clipBehavior;

  const CustomListViewBuilder({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.primary,
    this.controller,
    this.separator,
    this.itemCount,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.dragStartBehavior = DragStartBehavior.start,
    this.separatorBuilder,
    this.clipBehavior = Clip.hardEdge,
  });

  @override
  Widget build(BuildContext context) {
    if (separator != null || separatorBuilder != null) {
      return ListView.separated(
        key: key,
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        primary: primary,
        controller: controller,
        itemCount: itemCount ?? items.length,
        addAutomaticKeepAlives: addAutomaticKeepAlives,
        addRepaintBoundaries: addRepaintBoundaries,
        addSemanticIndexes: addSemanticIndexes,
        cacheExtent: cacheExtent,
        dragStartBehavior: dragStartBehavior,
        clipBehavior: clipBehavior,
        itemBuilder: (context, index) => itemBuilder(context, items[index], index),
        separatorBuilder: separatorBuilder ?? (context, index) => separator!,
      );
    } else {
      return ListView.builder(
        key: key,
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        primary: primary,
        controller: controller,
        itemCount: itemCount ?? items.length,
        addAutomaticKeepAlives: addAutomaticKeepAlives,
        addRepaintBoundaries: addRepaintBoundaries,
        addSemanticIndexes: addSemanticIndexes,
        cacheExtent: cacheExtent,
        dragStartBehavior: dragStartBehavior,
        clipBehavior: clipBehavior,
        itemBuilder: (context, index) => itemBuilder(context, items[index], index),
      );
    }
  }
}

// Specialized version for simple string lists
class CustomStringListViewBuilder extends StatelessWidget {
  final List<String> items;
  final Widget Function(BuildContext context, String item, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool? primary;
  final ScrollController? controller;
  final Widget? separator;
  final int? itemCount;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double? cacheExtent;
  final DragStartBehavior dragStartBehavior;
  final IndexedWidgetBuilder? separatorBuilder;
  final Clip clipBehavior;

  const CustomStringListViewBuilder({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.primary,
    this.controller,
    this.separator,
    this.itemCount,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.dragStartBehavior = DragStartBehavior.start,
    this.separatorBuilder,
    this.clipBehavior = Clip.hardEdge,
  });

  @override
  Widget build(BuildContext context) {
    return CustomListViewBuilder<String>(
      key: key,
      items: items,
      itemBuilder: itemBuilder,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      primary: primary,
      controller: controller,
      separator: separator,
      itemCount: itemCount,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: cacheExtent,
      dragStartBehavior: dragStartBehavior,
      separatorBuilder: separatorBuilder,
      clipBehavior: clipBehavior,
    );
  }
} 