import 'dart:developer';

import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/home/controller/home_screen_controller.dart';
import 'package:BlueEra/features/common/reel/widget/single_shorts_structure.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/setup_scroll_visibility_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShortsSavedFeedSection extends StatefulWidget {
  final Function(bool isVisible)? onHeaderVisibilityChanged;
  final String? query;
  final double headerHeight;

  ShortsSavedFeedSection({
    super.key,
    required this.onHeaderVisibilityChanged,
    required this.query,
    required this.headerHeight
  });

  @override
  State<ShortsSavedFeedSection> createState() => _ShortsSavedFeedSectionState();
}

class _ShortsSavedFeedSectionState extends State<ShortsSavedFeedSection> with RouteAware {
  final ShortsController shortsController = Get.put<ShortsController>(ShortsController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    shortsController.getAllSavedShorts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      RouteHelper.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    RouteHelper.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // we came back to this screen
    shortsController.getAllSavedShorts();
  }


  @override
  Widget build(BuildContext context) {
    return Obx(() {

      // if(videoController.isSavedVideosLoading.isFalse){
        final savedShorts = shortsController.savedShorts
            .where((e) => e.video?.type == 'short')
            .toList();
        log("savedShorts--> $savedShorts");

          if (savedShorts.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.only(top: SizeConfig.size80),
                child: EmptyStateWidget(
                  message: 'No shorts saved.',
                ),
              ),
            );
          }

          return setupScrollVisibilityNotification(
            controller: _scrollController,
            headerHeight: widget.headerHeight,
            // onVisibilityChanged: (visible) {
            //   if (_isVisible != visible && mounted) {
            //     setState(() => _isVisible = visible);
            //     widget.onHeaderVisibilityChanged?.call(visible);
            //   }
            // },
            onVisibilityChanged: (visible, offset) {
              final controller = Get.find<HomeScreenController>();
              final currentOffset = controller.headerOffset.value;

              // Linear animation step (same speed up/down)
              const step = 0.2; // smaller = smoother, larger = faster

              double newOffset = currentOffset;

              if (visible) {
                // show header → decrease offset
                newOffset = (currentOffset - step).clamp(0.0, 1.0);
              } else {
                // hide header → increase offset
                newOffset = (currentOffset + step).clamp(0.0, 1.0);
              }

              controller.headerOffset.value = newOffset;

              controller.isVisible.value = visible;
              widget.onHeaderVisibilityChanged?.call(visible);
            },
            child: GridView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              padding: const EdgeInsets.all(3),
              scrollDirection: Axis.vertical,
              itemCount: savedShorts.length,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 3,   // horizontal gap between items
                mainAxisSpacing: 3,    // vertical gap between items
              ),
              itemBuilder: (context, index) {
                final savedShortsItem = savedShorts[index];
                return SingleShortStructure(
                  shorts: Shorts.saved,
                  allLoadedShorts: savedShorts,
                  shortItem: savedShortsItem,
                  initialIndex: index,
                  imageHeight: SizeConfig.size200,
                  imageWidth: SizeConfig.size130,
                  borderRadius: 10.0,
                );
              },
            ),
          );

      // }else{
      //   return Center(child: CircularProgressIndicator());
      // }


    });
  }
}

