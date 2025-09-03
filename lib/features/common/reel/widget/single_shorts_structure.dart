import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/feed/models/video_feed_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SingleShortStructure extends StatefulWidget {
  final Shorts shorts;
  final List<VideoFeedItem>? allLoadedShorts;
  final VideoFeedItem? shortItem;
  final int? initialIndex;
  final double padding;
  final double? imageWidth;
  final double? imageHeight;
  final double? borderRadius;
  final bool withBackground;

  const  SingleShortStructure({
    super.key,
    required this.shorts,
    this.allLoadedShorts,
    this.shortItem,
    this.initialIndex,
    this.padding = 10.0,
    this.imageWidth,
    this.imageHeight,
    this.borderRadius,
    this.withBackground = false,
  });

  @override
  State<SingleShortStructure> createState() => _SingleShortStructureState();
}

class _SingleShortStructureState extends State<SingleShortStructure> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(0),
      // padding: EdgeInsets.all(widget.padding),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              if (widget.shorts == Shorts.underProgress) {
                return;
              }
              Navigator.pushNamed(
                context,
                RouteHelper.getShortsPlayerScreenRoute(),
                arguments: {
                  ApiKeys.shorts: widget.shorts,
                  ApiKeys.videoItem: widget.allLoadedShorts,
                  ApiKeys.initialIndex: widget.initialIndex
                },
              );
            },
            child: SizedBox(
              width: widget.imageWidth ?? SizeConfig.size220,
              height: 250,
              // height: widget.imageHeight ?? SizeConfig.size200,
              child: Stack(children: [
                ClipRRect(
                    borderRadius:
                        BorderRadius.circular(widget.borderRadius ?? 0),
                    child: CachedNetworkImage(
                      // width: imageWidth ?? SizeConfig.size90,
                      height: widget.imageHeight ?? 250,
                      // height: widget.imageHeight ?? SizeConfig.size220,
                      fit: BoxFit.cover,
                      imageUrl: widget.shortItem?.video?.coverUrl ?? '',
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.white, width: 1),
                          borderRadius:
                              BorderRadius.circular(widget.borderRadius ?? 8.0),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(widget.borderRadius ?? 8.0),
                          child: LocalAssets(
                            imagePath: AppIconAssets.blueEraIcon,
                            boxFix: BoxFit.cover,
                          ),
                        ),
                      ),
                    )),

                // total views
                Positioned(
                    bottom: SizeConfig.size8,
                    right: SizeConfig.size6,
                    child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                          vertical: SizeConfig.size2,
                          horizontal: SizeConfig.size5),
                      decoration: (widget.withBackground)
                          ? BoxDecoration(
                              color: AppColors.mainTextColor
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(5.0))
                          : null,
                      child: Row(
                        children: [
                          if (widget.withBackground) ...[
                            LocalAssets(imagePath: AppIconAssets.viewIcon),
                            SizedBox(width: SizeConfig.size1),
                          ],
                          CustomText(
                            (widget.withBackground)
                                ? "${widget.shortItem?.video?.stats?.views}"
                                : "${widget.shortItem?.video?.stats?.views} Views",
                            color: AppColors.white,
                            fontSize: SizeConfig.size13,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    )),

                // if (widget.isOwnProfile)
                //   ReelShortPopUpMenu(
                //       videoFeedItem: widget.shortItem!,
                //       sortBy: widget.sortBy,
                //       videoType: 'shorts',
                //   ),

                if (widget.shorts == Shorts.underProgress) ...[
                  Container(
                    width: widget.imageWidth ?? SizeConfig.size100,
                    height: widget.imageHeight ?? SizeConfig.size160,
                    decoration: BoxDecoration(
                      color: AppColors.black65,
                      borderRadius:
                          BorderRadius.circular(widget.borderRadius ?? 8.0),
                    ),
                    child: Center(
                      child: LocalAssets(
                          imagePath: AppIconAssets.progressIndicator),
                    ),
                  )
                ]
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
