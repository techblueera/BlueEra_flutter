import 'dart:async';
import 'package:flutter/material.dart';

class AutoScrollMarquee<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double speed;
  final double gap; // 🟢 Space between loops

  const AutoScrollMarquee({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.speed = 1.0,
    this.gap = 50.0, // Default gap size
  });

  @override
  State<AutoScrollMarquee<T>> createState() => _AutoScrollMarqueeState<T>();
}

class _AutoScrollMarqueeState<T> extends State<AutoScrollMarquee<T>> {
  late ScrollController _scrollController;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_scrollController.hasClients) {
        // Move content from Left to Right (reverse: true)
        double newOffset = _scrollController.offset + widget.speed;
        _scrollController.jumpTo(newOffset);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox();

    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,

      // 🟢 Left-to-Right Animation
      reverse: false,
      itemCount: null, // Infinite

      itemBuilder: (context, index) {
        // 1. Calculate length including the "Gap"
        // If we have 3 items, the cycle length is 4 (3 items + 1 gap)
        final int totalLength = widget.items.length + 1;
        final int actualIndex = index % totalLength;

        // 2. Render Gap if it's the last slot in the cycle
        if (actualIndex == widget.items.length) {
          return SizedBox(width: widget.gap);
        }

        // 3. Render Actual Item
        final T item = widget.items[actualIndex];
        return widget.itemBuilder(context, item, actualIndex);
      },
    );
  }
}