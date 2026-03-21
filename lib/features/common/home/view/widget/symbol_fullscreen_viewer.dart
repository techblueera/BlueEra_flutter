import 'dart:async';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/home/model/symbol_feed_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SymbolFullscreenViewer extends StatefulWidget {
  final List<SymbolFeedItem> symbols;
  final int initialIndex;

  const SymbolFullscreenViewer({
    super.key,
    required this.symbols,
    required this.initialIndex,
  });

  @override
  State<SymbolFullscreenViewer> createState() => _SymbolFullscreenViewerState();
}

class _SymbolFullscreenViewerState extends State<SymbolFullscreenViewer>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  Timer? _holdTimer;
  bool _isPaused = false;

  static const Duration _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _goToNext();
        }
      });
    _progressController.forward();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _progressController.dispose();
    _holdTimer?.cancel();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  void _goToNext() {
    if (_currentIndex < widget.symbols.length - 1) {
      setState(() => _currentIndex++);
      _progressController.reset();
      _progressController.forward();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _progressController.reset();
      _progressController.forward();
    } else {
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _onTapDown(TapDownDetails details) {
    _isPaused = true;
    _progressController.stop();
  }

  void _onTapUp(TapUpDetails details) {
    if (!_isPaused) return;
    _isPaused = false;
    _progressController.forward();
  }

  void _onTapCancel() {
    if (!_isPaused) return;
    _isPaused = false;
    _progressController.forward();
  }

  void _onHorizontalTap(TapUpDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < screenWidth / 3) {
      _goToPrevious();
    } else {
      _goToNext();
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.black;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.tryParse('0x$hex') ?? 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final symbol = widget.symbols[_currentIndex];
    final bgColor = _parseColor(symbol.backgroundColor);
    final user = symbol.user;
    final String? profileImage = user?.profileImage;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: (details) {
            _onTapUp(details);
            _onHorizontalTap(details);
          },
          onTapCancel: _onTapCancel,
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 300) {
              Navigator.of(context).pop();
            }
          },
          child: Stack(
            children: [
              /// Background content
              _buildContent(symbol, bgColor),

              /// Top gradient for readability
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 140,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              /// Progress bars + user info
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Progress indicators
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Row(
                        children: List.generate(widget.symbols.length, (i) {
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: AnimatedBuilder(
                                animation: _progressController,
                                builder: (context, child) {
                                  double value;
                                  if (i < _currentIndex) {
                                    value = 1.0;
                                  } else if (i == _currentIndex) {
                                    value = _progressController.value;
                                  } else {
                                    value = 0.0;
                                  }
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: value,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.3),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                      minHeight: 2.5,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    /// User row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[300],
                            backgroundImage:
                                (profileImage != null &&
                                        profileImage.isNotEmpty)
                                    ? CachedNetworkImageProvider(profileImage)
                                    : null,
                            child: (profileImage == null ||
                                    profileImage.isEmpty)
                                ? Icon(Icons.person,
                                    color: Colors.grey[500], size: 20)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  user?.name ?? 'User',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  maxLines: 1,
                                ),
                                if (symbol.createdAt != null)
                                  CustomText(
                                    _timeAgo(symbol.createdAt!),
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// Center: caption + link preview
              if ((symbol.caption != null && symbol.caption!.isNotEmpty) ||
                  symbol.type == 'embeddedUrl')
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (symbol.caption != null &&
                            symbol.caption!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CustomText(
                              symbol.caption!,
                              color: Colors.white,
                              fontSize: 15,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                            ),
                          ),
                        if (symbol.type == 'embeddedUrl' &&
                            symbol.content != null)
                          GestureDetector(
                            onTap: () async {
                              final uri = Uri.tryParse(symbol.content!);
                              if (uri != null && await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: AnyLinkPreview.builder(
                                link: symbol.content!,
                                cache: const Duration(days: 7),
                                placeholderWidget: _buildLinkPlaceholder(symbol.content!),
                                errorWidget: _buildLinkFallback(symbol.content!),
                                itemBuilder: (context, metadata, imageProvider, svgImage) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (imageProvider != null)
                                        SizedBox(
                                          height: 120,
                                          width: double.infinity,
                                          child: Image(image: imageProvider, fit: BoxFit.cover),
                                        )
                                      else if (svgImage != null)
                                        SizedBox(height: 80, width: double.infinity, child: svgImage),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (metadata.title != null && metadata.title!.isNotEmpty)
                                              CustomText(
                                                metadata.title!,
                                                fontSize: SizeConfig.small,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.mainTextColor,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            if (metadata.desc != null && metadata.desc!.isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              CustomText(
                                                metadata.desc!,
                                                fontSize: SizeConfig.extraSmall,
                                                color: AppColors.secondaryTextColor,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.link, size: 13, color: AppColors.secondaryTextColor),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: CustomText(
                                                    Uri.tryParse(symbol.content!)?.host ?? symbol.content!,
                                                    fontSize: SizeConfig.extraSmall,
                                                    color: AppColors.primaryColor,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(SymbolFeedItem symbol, Color bgColor) {
    if (symbol.type == 'image' && symbol.content != null) {
      return Center(
        child: CachedNetworkImage(
          imageUrl: symbol.content!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) => Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (_, __, ___) => _buildTextContent(symbol, bgColor),
        ),
      );
    }
    return _buildTextContent(symbol, bgColor);
  }

  Widget _buildTextContent(SymbolFeedItem symbol, Color bgColor) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: bgColor,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 100),
      child: (symbol.content != null && symbol.content!.isNotEmpty)
          ? CustomText(
              symbol.content!,
              color: Colors.white,
              fontSize: 18,
              textAlign: TextAlign.center,
              fontWeight: FontWeight.w500,
              maxLines: 10,
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildLinkPlaceholder(String link) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primaryColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomText(
              Uri.tryParse(link)?.host ?? link,
              fontSize: SizeConfig.extraSmall,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkFallback(String link) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.link_rounded, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: CustomText(
              Uri.tryParse(link)?.host ?? link,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.open_in_new, size: 16, color: AppColors.secondaryTextColor),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
