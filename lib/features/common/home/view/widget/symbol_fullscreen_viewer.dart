import 'dart:async';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/home/controller/symbol_feed_controller.dart';
import 'package:BlueEra/features/common/home/model/symbol_feed_model.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class SymbolFullscreenViewer extends StatefulWidget {
  final List<SymbolUserGroup> groups;
  final int initialGroupIndex;

  const SymbolFullscreenViewer({
    super.key,
    required this.groups,
    required this.initialGroupIndex,
  });

  @override
  State<SymbolFullscreenViewer> createState() => _SymbolFullscreenViewerState();
}

class _SymbolFullscreenViewerState extends State<SymbolFullscreenViewer>
    with SingleTickerProviderStateMixin {
  late int _groupIndex;
  late int _symbolIndex;
  late AnimationController _progressController;
  bool _isPaused = false;

  static const Duration _storyDuration = Duration(seconds: 5);

  SymbolFeedController get _feedController => Get.find<SymbolFeedController>();

  SymbolUserGroup get _currentGroup => widget.groups[_groupIndex];
  SymbolFeedItem get _currentSymbol =>
      _currentGroup.symbols[_symbolIndex];

  @override
  void initState() {
    super.initState();
    _groupIndex = widget.initialGroupIndex;
    _symbolIndex = 0;

    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _goToNextSymbol();
        }
      });

    _startCurrentSymbol();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _progressController.dispose();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  void _startCurrentSymbol() {
    _progressController.reset();
    _progressController.forward();

    // Mark as viewed if not yet seen
    final symbol = _currentSymbol;
    if (symbol.hasSeen != true && symbol.id != null) {
      _feedController.markAsViewed(symbol.id!);
    }
  }

  void _goToNextSymbol() {
    if (_symbolIndex < _currentGroup.symbols.length - 1) {
      // Next symbol in same user group
      setState(() => _symbolIndex++);
      _startCurrentSymbol();
    } else {
      // Move to next user group
      _goToNextGroup();
    }
  }

  void _goToPreviousSymbol() {
    if (_symbolIndex > 0) {
      setState(() => _symbolIndex--);
      _startCurrentSymbol();
    } else {
      // Move to previous user group
      _goToPreviousGroup();
    }
  }

  void _goToNextGroup() {
    if (_groupIndex < widget.groups.length - 1) {
      setState(() {
        _groupIndex++;
        _symbolIndex = 0;
      });
      _startCurrentSymbol();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goToPreviousGroup() {
    if (_groupIndex > 0) {
      setState(() {
        _groupIndex--;
        _symbolIndex = widget.groups[_groupIndex].symbols.length - 1;
      });
      _startCurrentSymbol();
    } else {
      setState(() => _symbolIndex = 0);
      _startCurrentSymbol();
    }
  }

  void _onTapDown(TapDownDetails details) {
    _isPaused = true;
    _progressController.stop();
  }

  void _onTapUp(TapUpDetails details) {
    if (!_isPaused) return;
    _isPaused = false;

    final screenWidth = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < screenWidth / 3) {
      _goToPreviousSymbol();
    } else {
      _goToNextSymbol();
    }
  }

  void _onTapCancel() {
    if (!_isPaused) return;
    _isPaused = false;
    _progressController.forward();
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.black;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.tryParse('0x$hex') ?? 0xFF000000);
  }

  void _pauseTimer() {
    _isPaused = true;
    _progressController.stop();
  }

  void _resumeTimer() {
    _isPaused = false;
    _progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = _currentSymbol;
    final bgColor = _parseColor(symbol.backgroundColor);
    final user = _currentGroup.user ?? symbol.user;
    final String? profileImage = user?.profileImage;
    final totalSymbols = _currentGroup.symbols.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
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

              /// Top gradient
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

              /// Bottom gradient
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 160,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
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
                    /// Progress indicators for current user's symbols
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Row(
                        children: List.generate(totalSymbols, (i) {
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 1.5),
                              child: AnimatedBuilder(
                                animation: _progressController,
                                builder: (context, child) {
                                  double value;
                                  if (i < _symbolIndex) {
                                    value = 1.0;
                                  } else if (i == _symbolIndex) {
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
                                  user?.name ?? AppStrings.userFallback.tr,
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
                                placeholderWidget:
                                    _buildLinkPlaceholder(symbol.content!),
                                errorWidget:
                                    _buildLinkFallback(symbol.content!),
                                itemBuilder: (context, metadata, imageProvider,
                                    svgImage) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (imageProvider != null)
                                        SizedBox(
                                          height: 120,
                                          width: double.infinity,
                                          child: Image(
                                              image: imageProvider,
                                              fit: BoxFit.cover),
                                        )
                                      else if (svgImage != null)
                                        SizedBox(
                                            height: 80,
                                            width: double.infinity,
                                            child: svgImage),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (metadata.title != null &&
                                                metadata.title!.isNotEmpty)
                                              CustomText(
                                                metadata.title!,
                                                fontSize: SizeConfig.small,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    AppColors.mainTextColor,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            if (metadata.desc != null &&
                                                metadata
                                                    .desc!.isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              CustomText(
                                                metadata.desc!,
                                                fontSize:
                                                    SizeConfig.extraSmall,
                                                color: AppColors
                                                    .secondaryTextColor,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.link,
                                                    size: 13,
                                                    color: AppColors
                                                        .secondaryTextColor),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: CustomText(
                                                    Uri.tryParse(symbol
                                                                .content!)
                                                            ?.host ??
                                                        symbol.content!,
                                                    fontSize:
                                                        SizeConfig.extraSmall,
                                                    color: AppColors
                                                        .primaryColor,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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

              /// Bottom action bar: like, comment, seen count
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Obx(() {
                    // Access userGroups to register reactive dependency
                    _feedController.userGroups.length;
                    return _BottomActionBar(
                      symbol: symbol,
                      onLike: () => _feedController.toggleLike(symbol),
                      onComment: () => _showCommentSheet(symbol),
                      onPause: _pauseTimer,
                      onResume: _resumeTimer,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCommentSheet(SymbolFeedItem symbol) {
    _pauseTimer();
    _feedController.fetchComments(symbol.id!);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CommentSheet(
        symbol: symbol,
        controller: _feedController,
      ),
    ).whenComplete(() {
      _resumeTimer();
    });
  }

  Widget _buildContent(SymbolFeedItem symbol, Color bgColor) {
    if (symbol.type == 'image' && symbol.content != null) {
      return Center(
        child: CachedNetworkImage(
          imageUrl: symbol.content!,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) => const Center(
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
      child: (symbol.content != null &&
              symbol.content!.isNotEmpty &&
              symbol.type != 'embeddedUrl')
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
          const Icon(Icons.link_rounded,
              color: AppColors.primaryColor, size: 20),
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
          const Icon(Icons.open_in_new,
              size: 16, color: AppColors.secondaryTextColor),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return AppStrings.justNow.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${AppStrings.minutesAgo.tr}';
    if (diff.inHours < 24) return '${diff.inHours} ${AppStrings.hoursAgo.tr}';
    return '${diff.inDays} ${AppStrings.daysAgo.tr}';
  }
}

/// Bottom action bar with like, comment, and seen count
class _BottomActionBar extends StatelessWidget {
  final SymbolFeedItem symbol;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const _BottomActionBar({
    required this.symbol,
    required this.onLike,
    required this.onComment,
    required this.onPause,
    required this.onResume,
  });

  SymbolFeedItem _findLiveSymbol() {
    final controller = Get.find<SymbolFeedController>();
    // Access the RxList length to register GetX dependency
    final groups = controller.userGroups;
    for (int i = 0; i < groups.length; i++) {
      for (final s in groups[i].symbols) {
        if (s.id == symbol.id) return s;
      }
    }
    return symbol;
  }

  @override
  Widget build(BuildContext context) {
    final s = _findLiveSymbol();
    final bool isLiked = s.hasLiked == true;
    final int likesCount = s.likesCount ?? 0;
    final int commentsCount = s.commentsCount ?? 0;
    final int seenCount = s.seenCount ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          /// Like button
          GestureDetector(
            onTap: onLike,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.white,
                  size: 26,
                ),
                if (likesCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(likesCount),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),

          /// Comment button
          GestureDetector(
            onTap: onComment,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline,
                    color: Colors.white, size: 24),
                if (commentsCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(commentsCount),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          /// Seen count
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.visibility_outlined,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 4),
              Text(
                _formatCount(seenCount),
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

/// Comment bottom sheet
class _CommentSheet extends StatefulWidget {
  final SymbolFeedItem symbol;
  final SymbolFeedController controller;

  const _CommentSheet({required this.symbol, required this.controller});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final TextEditingController _textController = TextEditingController();
  String? _editingCommentId;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: bottomInset > 0 ? bottomInset : bottomPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            /// Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CustomText(
                    AppStrings.symbolComments,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                  const Spacer(),
                  Obx(() {
                    // Access comments RxList to register dependency
                    final count = widget.controller.comments.length;
                    return CustomText(
                      '$count',
                      fontSize: 14,
                      color: AppColors.secondaryTextColor,
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1),

            /// Comments list
            Expanded(
              child: Obx(() {
                if (widget.controller.isLoadingComments.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryColor),
                  );
                }
                if (widget.controller.comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            color: Colors.grey[300], size: 48),
                        const SizedBox(height: 8),
                        CustomText(
                          AppStrings.noCommentsYet.tr,
                          fontSize: 14,
                          color: AppColors.secondaryTextColor,
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                          AppStrings.beTheFirstToComment.tr,
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: widget.controller.comments.length,
                  itemBuilder: (context, index) {
                    final comment = widget.controller.comments[index];
                    final isOwn = widget.controller.isOwnComment(comment);

                    return _CommentTile(
                      comment: comment,
                      isOwn: isOwn,
                      onEdit: isOwn
                          ? () {
                              setState(() {
                                _editingCommentId = comment.id;
                                _textController.text = comment.comment ?? '';
                              });
                            }
                          : null,
                      onDelete: isOwn
                          ? () => _deleteComment(comment)
                          : null,
                    );
                  },
                );
              }),
            ),

            /// Input field
            Container(
              padding: const EdgeInsets.only(
                  left: 12, right: 12, top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: AppStrings.addAComment.tr,
                        hintStyle: TextStyle(
                            color: Colors.grey[400], fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppColors.primaryColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _submitComment,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (_editingCommentId != null) {
      final success = await widget.controller
          .editComment(widget.symbol.id!, _editingCommentId!, text);
      if (success) {
        _textController.clear();
        setState(() => _editingCommentId = null);
      }
    } else {
      final success =
          await widget.controller.addComment(widget.symbol.id!, text);
      if (success) {
        _textController.clear();
      }
    }
  }

  void _deleteComment(SymbolComment comment) {
    showCommonDialog(
      context: context,
      header: AppStrings.confirm.tr,
      text: AppStrings.deleteCommentConfirm.tr,
      confirmCallback: () {
        Navigator.of(context).pop();
        if (comment.id != null) {
          widget.controller.deleteComment(widget.symbol.id!, comment.id!);
        }
      },
      cancelCallback: () {
        Navigator.of(context).pop();
      },
      confirmText: AppStrings.yes,
      cancelText: AppStrings.no,
    );
  }
}

/// Individual comment tile
class _CommentTile extends StatelessWidget {
  final SymbolComment comment;
  final bool isOwn;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CommentTile({
    required this.comment,
    required this.isOwn,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String? profileImage = comment.user?.profileImage;
    final String name = comment.user?.name ?? AppStrings.userFallback.tr;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[200],
            backgroundImage:
                (profileImage != null && profileImage.isNotEmpty)
                    ? CachedNetworkImageProvider(profileImage)
                    : null,
            child: (profileImage == null || profileImage.isEmpty)
                ? Icon(Icons.person, color: Colors.grey[400], size: 18)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomText(
                      name,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                    ),
                    const SizedBox(width: 8),
                    if (comment.createdAt != null)
                      CustomText(
                        _timeAgo(comment.createdAt!),
                        fontSize: 11,
                        color: AppColors.secondaryTextColor,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                CustomText(
                  comment.comment ?? '',
                  fontSize: 13,
                  color: AppColors.mainTextColor,
                ),
              ],
            ),
          ),
          if (isOwn)
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: Icon(Icons.more_vert,
                  color: Colors.grey[400], size: 18),
              onSelected: (value) {
                if (value == 'edit') onEdit?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                    value: 'edit', child: Text(AppStrings.editComment.tr)),
                PopupMenuItem(
                    value: 'delete',
                    child:
                        Text(AppStrings.deleteComment.tr, style: const TextStyle(color: Colors.red))),
              ],
            ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return AppStrings.justNow.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${AppStrings.minutesAgo.tr}';
    if (diff.inHours < 24) return '${diff.inHours} ${AppStrings.hoursAgo.tr}';
    return '${diff.inDays} ${AppStrings.daysAgo.tr}';
  }
}
