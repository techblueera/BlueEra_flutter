import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/reel/widget/single_shorts_structure.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShortsChannelSection extends StatefulWidget {
  final bool isOwnShorts;
  final SortBy? sortBy;
  final bool showShortsInGrid;
  final String channelId;
  final String authorId;
  final VoidCallback? onLoadMore; // Callback for pagination
  final PostVia? postVia;

  ShortsChannelSection({
    super.key,
    this.onLoadMore,
    required this.isOwnShorts,
    required this.channelId,
    required this.authorId,
    required this.showShortsInGrid,
    this.postVia,
    this.sortBy,
  });

  @override
  State<ShortsChannelSection> createState() => _ShortsChannelSectionState();
}

class _ShortsChannelSectionState extends State<ShortsChannelSection> {
  final ShortsController shortsController = Get.put<ShortsController>(ShortsController());
  Shorts shorts = Shorts.latest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchChannelShorts(isInitialLoad: true);
    });
    
    setShortsType();
  }

  setShortsType(){
     shorts = switch (widget.sortBy) {
      SortBy.Latest       => Shorts.latest,
      SortBy.Popular      => Shorts.popular,
      SortBy.Oldest       => Shorts.oldest,
      SortBy.UnderProgress=> Shorts.underProgress,
      null                => Shorts.latest, // default for null
    };
  }

  // this will if changes in sort by cause page is already loaded
  @override
  void didUpdateWidget(covariant ShortsChannelSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortBy != widget.sortBy) {
      setShortsType();
      fetchChannelShorts(isInitialLoad: true);
    }
  }

  void fetchChannelShorts({bool isInitialLoad = false, bool refresh = false}) {
    shortsController.getShortsByType(
        shorts,
        widget.channelId,
        widget.authorId,
        widget.isOwnShorts,
        isInitialLoad: isInitialLoad,
        refresh: refresh,
        postVia: widget.postVia,
    );
  }

  // Method to be called from parent for pagination
  void loadMore() {
    if (shortsController.isHasMoreData(shorts) && 
        shortsController.isMoreDataLoading(shorts).isFalse) {
      shortsController.isMoreDataLoading(shorts).value = true;
      fetchChannelShorts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {

      if(shortsController.isInitialLoading(shorts).isFalse){
        if(shortsController.shortsResponse.status == Status.COMPLETE){
          final channelShorts = shortsController.getListByType(shorts: shorts);

          if (channelShorts.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.only(top: SizeConfig.size80),
                child: EmptyStateWidget(
                  message: 'No shorts available.',
                ),
              ),
            );
          }

          return (widget.showShortsInGrid) ? GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(3),
            scrollDirection: Axis.vertical,
            itemCount: channelShorts.length,
            physics: const NeverScrollableScrollPhysics(), // Prevent scrolling conflicts
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.7,
              crossAxisSpacing: 3,   // horizontal gap between items
              mainAxisSpacing: 3,    // vertical gap between items
            ),
            itemBuilder: (context, index) {
              final channelShortsItem = channelShorts[index];
              return SingleShortStructure(
                shorts: shorts,
                allLoadedShorts: channelShorts,
                shortItem: channelShortsItem,
                initialIndex: index,
                imageHeight: SizeConfig.size200,
                // imageWidth: SizeConfig.size130,
                borderRadius: 10.0,
              );
            },
          ) :  SizedBox(
            height: SizeConfig.size190,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(), // Allow horizontal scrolling
              itemCount: channelShorts.length,
              itemBuilder: (context, index) {
                final channelShortsItem = channelShorts[index];
                return SingleShortStructure(
                  shorts: shorts,
                  allLoadedShorts: channelShorts,
                  shortItem: channelShortsItem,
                  initialIndex: index,
                  imageHeight: SizeConfig.size190,
                  imageWidth: SizeConfig.size130,
                  borderRadius: 10.0,
                );
              },
            ),
          );
        }else{
          return LoadErrorWidget(
              errorMessage: 'Failed to load shorts',
              onRetry: ()=>  fetchChannelShorts(isInitialLoad: true)
          );
        }
      }else{
        return Center(child: CircularProgressIndicator());
      }

    });
  }
}
