import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/feed/controller/shorts_controller.dart';
import 'package:BlueEra/features/common/reel/view/shorts/nearby_shorts_view_all.dart';
import 'package:BlueEra/features/common/reel/view/shorts/personalization_shorts_view_all.dart';
import 'package:BlueEra/features/common/reel/view/shorts/shorts_shimmer_striip.dart';
import 'package:BlueEra/features/common/reel/view/shorts/trending_shorts_view_all.dart';
import 'package:BlueEra/features/common/reel/widget/shorts_section_title.dart';
import 'package:BlueEra/features/common/reel/widget/single_shorts_structure.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/load_error_widget.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShortsFeedScreen extends StatefulWidget {
  final String? query;
  final Function(bool isVisible)? onHeaderVisibilityChanged;
  final double? headerHeight;

  ShortsFeedScreen({
    super.key,
    this.query,
    this.onHeaderVisibilityChanged,
    this.headerHeight
  });

  @override
  State<ShortsFeedScreen> createState() => _ShortsFeedScreenState();
}

class _ShortsFeedScreenState extends State<ShortsFeedScreen>
    with WidgetsBindingObserver {
  final ShortsController shortsFeedController = Get.put(ShortsController());
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchInitialFeeds();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Handle header visibility if callback is provided
      widget.onHeaderVisibilityChanged?.call(_scrollController.offset <= 50);
    });
  }

  void _fetchInitialFeeds() async {
    shortsFeedController.getAllFeedTrending(
        isInitialLoad: true, refresh: true, query: widget.query ?? '');
    shortsFeedController.getAllFeedPersonalized(
        isInitialLoad: true, refresh: true);
    _checkLocationOnStart();
  }

  Future<void> _checkLocationOnStart() async {
    try {
      // 🔁 Get location and then call nearby feed
      final location =
      await shortsFeedController.fetchLocation(context: context);

      if (location.lat != null && location.lng != null) {
        await shortsFeedController.getAllFeedNearBy(
            lat: location.lat!,
            lng: location.lng!,
            isInitialLoad: true,
            refresh: true);
      }
    } catch (e) {
      debugPrint('Error loading feeds: $e');
    }
  }

  // this will if changes in sort by cause page is already loaded
  @override
  void didUpdateWidget(covariant ShortsFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// this is the case when search query changes
    if (oldWidget.query != widget.query) {
      _onQueryChanged(widget.query);
    }
  }

  void _onQueryChanged(String? newQuery) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      // call the same method you already use
      if (!_areAllListsEmpty)
        shortsFeedController.getAllFeedTrending(
            isInitialLoad: true, refresh: true, query: widget.query ?? '');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  bool get _areAllListsEmpty {
    return shortsFeedController.trendingVideoFeedPosts.isEmpty &&
        shortsFeedController.nearByVideoFeedPosts.isEmpty &&
        shortsFeedController.personalizedVideoFeedPosts.isEmpty;
  }

  bool get _allShortsFeedResponseError {
    return shortsFeedController.trendingShortsResponse.status == Status.ERROR &&
        shortsFeedController.nearByShortsResponse.status == Status.ERROR &&
        shortsFeedController.personalizedShortsResponse.status == Status.ERROR;
  }

  bool get _allShortsFeedResponseComplete {
    return shortsFeedController.trendingShortsResponse.status ==
        Status.COMPLETE &&
        shortsFeedController.nearByShortsResponse.status == Status.COMPLETE &&
        shortsFeedController.personalizedShortsResponse.status ==
            Status.COMPLETE;
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.resumed) {
  //     // Called when app returns from background or settings
  //     _checkLocationOnStart(); // Re-fetch location
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      /// Show empty state when ALL three lists are empty
      if (_allShortsFeedResponseComplete) {
        if (_areAllListsEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LocalAssets(
                  imagePath: AppIconAssets.emptyIcon,
                  height: SizeConfig.size80,
                  width: SizeConfig.size80,
                ),
                SizedBox(height: SizeConfig.size16),
                CustomText(
                  'No shorts available right now.',
                  color: AppColors.mainTextColor,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: SizeConfig.size8),
                CustomText(
                  'Check back later for new content!',
                  color: AppColors.mainTextColor.withValues(alpha: 0.7),
                  fontSize: SizeConfig.medium,
                  textAlign: TextAlign.center,
                )
              ],
            ),
          );
        }
      }

      if (_allShortsFeedResponseError)
        return LoadErrorWidget(
            errorMessage: 'Failed to load posts', onRetry: _fetchInitialFeeds);

      return SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trending Section
              if (shortsFeedController.trendingVideoFeedPosts.isNotEmpty) ...[
                if (shortsFeedController.trendingShortsResponse.status ==
                    Status.COMPLETE) ...[
                  ShortsSectionTitle(
                      title: "🔥 Trending", topPadding: 0, onViewAll: () {
                    Get.to(TrendingShortsViewAll(query: widget.query ?? ""));
                  }),
                  _buildTrendingSection(),
                ]
              ] else
                if (shortsFeedController.isFirstLoadTrending.isTrue) ...[
                  ShortsSectionTitle(
                      title: "🔥 Trending", topPadding: 0, onViewAll: () {
                    Get.to(TrendingShortsViewAll(query: widget.query ?? ""));
                  }),
                  const ShimmerShortsStrip(),
                ],

              // Near By Section
              if (shortsFeedController.nearByVideoFeedPosts.isNotEmpty) ...[
                if (shortsFeedController.nearByShortsResponse.status ==
                    Status.COMPLETE) ...[
                  ShortsSectionTitle(
                      title: "📍 Near By",
                      topPadding: SizeConfig.size15,
                      onViewAll: () {
                        Get.to(NearByShortsViewAll(query: widget.query ?? ""));
                      }),
                  _buildNearBySection(),
                ]
              ] else
                if (shortsFeedController.isFirstLoadNearBy.isTrue) ...[
                  ShortsSectionTitle(
                      title: "📍 Near By",
                      topPadding: SizeConfig.size15,
                      onViewAll: () {
                        Get.to(NearByShortsViewAll(query: widget.query ?? ""));
                      }),
                  const ShimmerShortsStrip(),
                ],

              // Personalized Section
              if (shortsFeedController
                  .personalizedVideoFeedPosts.isNotEmpty) ...[
                if (shortsFeedController.personalizedShortsResponse.status ==
                    Status.COMPLETE) ...[
                  ShortsSectionTitle(
                      title: "✨ For You",
                      topPadding: SizeConfig.size15,
                      onViewAll: () {
                        Get.to(PersonalizationShortsViewAll(
                            query: widget.query ?? ""));
                      }),
                  _buildPersonalizedSection(),
                ]
              ] else
                if (shortsFeedController
                    .isFirstLoadPersonalized.isTrue) ...[
                  ShortsSectionTitle(
                      title: "✨ For You",
                      topPadding: SizeConfig.size15,
                      onViewAll: () {
                        Get.to(PersonalizationShortsViewAll(query: widget.query ?? ""));
                      }),
                  const ShimmerShortsStrip(),
                ],

              SizedBox(height: SizeConfig.size20),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTrendingSection() {
    return SizedBox(
      // height for 2 rows of grid (adjust as per UI)
      // height: SizeConfig.size150,
      // height: SizeConfig.size160 * 2 + 50,
      child: Obx(() {
        final trendingShorts = shortsFeedController.trendingVideoFeedPosts;
        final isLoading = shortsFeedController.trendingVideoFeedIsLoadingMore;

        // show max 6 + loader (if needed)
        int itemCount = trendingShorts.length;
        if (itemCount > 6) itemCount = 6;
        // if (isLoading) itemCount += 1;

        return GridView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.paddingXSL,
            vertical: 8,
          ),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 columns
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
            childAspectRatio: 0.63, // square cells
          ),
          itemCount: itemCount >= 6 ? 6 : itemCount,
          itemBuilder: (context, index) {
            if (trendingShorts.isNotEmpty) {
              // ✅ Normal grid items (up to 5)
              final item = trendingShorts[index];
              return SingleShortStructure(
                shorts: Shorts.trending,
                allLoadedShorts: trendingShorts,
                initialIndex: index,
                shortItem: item,
                withBackground: true,
              );
            } else {
              // ✅ Loading indicator if API is fetching more
              return buildLoadingIndicator();
            }
          },
        );
      }),
    );

    //
    // return NotificationListener<ScrollNotification>(
    //   onNotification: (scrollNotification) {
    //     final metrics = scrollNotification.metrics;
    //     if (metrics.pixels >= metrics.maxScrollExtent - 50) {
    //       if (shortsFeedController.trendingVideoFeedHasMore &&
    //           !shortsFeedController.trendingVideoFeedIsLoadingMore) {
    //         shortsFeedController.getAllFeedTrending(query: widget.query ?? '');
    //       }
    //     }
    //     return false;
    //   },
    //   child: SizedBox(
    //     height: SizeConfig.size150,
    //     child: Obx(() {
    //       final trendingShorts = shortsFeedController.trendingVideoFeedPosts;
    //       final isLoading = shortsFeedController.trendingVideoFeedIsLoadingMore;
    //
    //       return Container(
    //         width: SizeConfig.screenWidth,
    //         child: ListView.builder(
    //           keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    //           padding: EdgeInsets.symmetric(horizontal: SizeConfig.paddingXSL),
    //           physics: const ClampingScrollPhysics(),
    //           shrinkWrap: true,
    //           scrollDirection: Axis.horizontal,
    //           itemCount: trendingShorts.length + (isLoading ? 1 : 0),
    //           itemBuilder: (context, index) {
    //             if (index < trendingShorts.length) {
    //               final item = trendingShorts[index];
    //               return SingleShortStructure(
    //                 shorts: Shorts.trending,
    //                 allLoadedShorts: trendingShorts,
    //                 initialIndex: index,
    //                 shortItem: item,
    //                 withBackground: true,
    //               );
    //             } else {
    //               return buildLoadingIndicator();
    //             }
    //           },
    //         ),
    //       );
    //     }),
    //   ),
    // );
  }

  Widget _buildNearBySection() {
    return SizedBox(
      // height for 2 rows of grid (adjust as per UI)
      // height: SizeConfig.size150,
      // height: SizeConfig.size160 * 2 + 50,
      child: Obx(() {
        final nearByShorts = shortsFeedController.nearByVideoFeedPosts;
        // final isLoading = shortsFeedController.nearByVideoFeedIsLoadingMore;

        // show max 6 + loader (if needed)
        int itemCount = nearByShorts.length;
        if (itemCount > 6) itemCount = 6;
        // if (isLoading) itemCount += 1;

        return GridView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.paddingXSL,
            vertical: 8,
          ),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 columns
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
            childAspectRatio: 0.63, // square cells
          ),
          itemCount: itemCount >= 6 ? 6 : itemCount,
          itemBuilder: (context, index) {
            if (nearByShorts.isNotEmpty) {
              // ✅ Normal grid items (up to 5)
              final item = nearByShorts[index];
              return SingleShortStructure(
                shorts: Shorts.nearBy,
                allLoadedShorts: nearByShorts,
                initialIndex: index,
                shortItem: item,
                withBackground: true,
              );
            } else {
              // ✅ Loading indicator if API is fetching more
              return buildLoadingIndicator();
            }
          },
        );
      }),
    );

    // Widget _buildNearBySection() {
    //   return NotificationListener<ScrollNotification>(
    //     onNotification: (ScrollNotification? scrollNotification) {
    //       if (scrollNotification == null) return false;
    //       final metrics = scrollNotification.metrics;
    //       if (metrics.pixels >= metrics.maxScrollExtent - 50) {
    //         if (shortsFeedController.nearByVideoFeedHasMore &&
    //             !shortsFeedController.nearByVideoFeedIsLoadingMore) {
    //           shortsFeedController.getAllFeedNearBy();
    //         }
    //       }
    //       return false;
    //     },
    //     child: SizedBox(
    //       height: SizeConfig.size150,
    //       child: Obx(() {
    //         final nearByShorts = shortsFeedController.nearByVideoFeedPosts;
    //         final isLoading = shortsFeedController.nearByVideoFeedIsLoadingMore;
    //
    //         return Container(
    //           width: SizeConfig.screenWidth,
    //           child: ListView.builder(
    //             keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior
    //                 .onDrag,
    //             padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
    //             scrollDirection: Axis.horizontal,
    //             physics: const ClampingScrollPhysics(),
    //             shrinkWrap: true,
    //             itemCount: nearByShorts.length + (isLoading ? 1 : 0),
    //             itemBuilder: (context, index) {
    //               if (index < nearByShorts.length) {
    //                 final nearByVideoFeedItem = nearByShorts[index];
    //                 return SingleShortStructure(
    //                   shorts: Shorts.nearBy,
    //                   allLoadedShorts: nearByShorts,
    //                   initialIndex: index,
    //                   shortItem: nearByVideoFeedItem,
    //                   withBackground: true,
    //                 );
    //               } else {
    //                 return buildLoadingIndicator();
    //               }
    //             },
    //           ),
    //         );
    //       }),
    //     ),
    //   );
    // }
  }


  Widget _buildPersonalizedSection() {
    return SizedBox(
      // height for 2 rows of grid (adjust as per UI)
      // height: SizeConfig.size150,
      // height: SizeConfig.size160 * 2 + 50,
      child: Obx(() {
        final personalizedShorts = shortsFeedController
            .personalizedVideoFeedPosts;
        // final isLoading = shortsFeedController.personalizedVideoIsLoadingMore;

        // show max 6 + loader (if needed)
        int itemCount = personalizedShorts.length;
        if (itemCount > 6) itemCount = 6;
        // if (isLoading) itemCount += 1;

        return GridView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.paddingXSL,
            vertical: 8,
          ),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 columns
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
            childAspectRatio: 0.63, // square cells
          ),
          itemCount: itemCount >= 6 ? 6 : itemCount,
          itemBuilder: (context, index) {
            if (personalizedShorts.isNotEmpty) {
              // ✅ Normal grid items (up to 5)
              final item = personalizedShorts[index];
              return SingleShortStructure(
                shorts: Shorts.personalized,
                allLoadedShorts: personalizedShorts,
                initialIndex: index,
                shortItem: item,
                withBackground: true,
              );
            } else {
              // ✅ Loading indicator if API is fetching more
              return buildLoadingIndicator();
            }
          },
        );
      }),
    );

    // Widget _buildPersonalizedSection() {
    //   return NotificationListener<ScrollNotification>(
    //     onNotification: (scrollNotification) {
    //       if (scrollNotification.metrics.pixels >=
    //           scrollNotification.metrics.maxScrollExtent - 50) {
    //         if (shortsFeedController.personalizedVideoFeedHasMore &&
    //             !shortsFeedController.personalizedVideoIsLoadingMore) {
    //           shortsFeedController.getAllFeedPersonalized();
    //         }
    //       }
    //       return false;
    //     },
    //     child: SizedBox(
    //       height: SizeConfig.size150,
    //       child: Obx(() {
    //         final personalizedShorts =
    //             shortsFeedController.personalizedVideoFeedPosts;
    //         final isLoadingMore =
    //             shortsFeedController.personalizedVideoIsLoadingMore;
    //
    //         return Container(
    //           width: SizeConfig.screenWidth,
    //           child: ListView.builder(
    //             keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior
    //                 .onDrag,
    //             padding: EdgeInsets.symmetric(horizontal: SizeConfig.size15),
    //             physics: const ClampingScrollPhysics(),
    //             shrinkWrap: true,
    //             scrollDirection: Axis.horizontal,
    //             itemCount: personalizedShorts.length + (isLoadingMore ? 1 : 0),
    //             itemBuilder: (context, index) {
    //               if (index < personalizedShorts.length) {
    //                 VideoFeedItem item = personalizedShorts[index];
    //                 return SingleShortStructure(
    //                   shorts: Shorts.personalized,
    //                   allLoadedShorts: personalizedShorts,
    //                   initialIndex: index,
    //                   shortItem: item,
    //                   withBackground: true,
    //                 );
    //               } else {
    //                 return buildLoadingIndicator();
    //               }
    //             },
    //           ),
    //         );
    //       }),
    //     ),
    //   );
    // }
  }
}

Widget buildLoadingIndicator() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
        ),
      ),
    ),
  );
}