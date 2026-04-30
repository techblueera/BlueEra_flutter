import 'dart:convert';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:any_link_preview/any_link_preview.dart';
import '../../auth/controller/add_chat_symbol_controller.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/symbol_details_model.dart';
import '../widget/custom_video_player.dart';

class SymbolViewImages extends StatefulWidget {
  final String? userId;
  final List<SymbolDetailsModel>? mySymbols;
  final SymbolDetailsModel? initialSymbol;
  final String? profileImage;
  final String? name;

  const SymbolViewImages({
    super.key,
    this.mySymbols,
    this.initialSymbol,
    this.userId,
    this.profileImage,
    this.name,
  });

  @override
  State<SymbolViewImages> createState() => _SymbolViewImagesState();
}

class _SymbolViewImagesState extends State<SymbolViewImages> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int currentIndex = 0;
  List<SymbolDetailsModel>? allImages = [];
  final addSymbolController = Get.isRegistered<AddChatSymbolController>() ? Get.find<AddChatSymbolController>() : Get.put(AddChatSymbolController());

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  VideoPlayerController? _videoController;
  bool isPlaying = true;

  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  final Set<String> _likedSymbolIds = {};

  bool get _isMySymbols => widget.mySymbols != null;
  bool get _hasImages => allImages != null && allImages!.isNotEmpty;
  bool get _isValidIndex => _hasImages && currentIndex < allImages!.length;

  String? get _displayName {
    if (widget.name != null) return widget.name;
    if (_hasImages) {
      final user = allImages!.first.user;
      if (user?.name != null) return user!.name;
    }
    return null;
  }

  String? get _displayImage {
    if (widget.profileImage != null) return widget.profileImage;
    if (_hasImages) {
      final user = allImages!.first.user;
      if (user?.profileImage != null) return user!.profileImage;
    }
    return null;
  }

  void getSymbols() async {
    allImages = await addSymbolController.getSymbolsForOtherUser(widget.userId ?? '');
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    if (widget.mySymbols != null) {
      allImages = widget.mySymbols;
    } else if (widget.initialSymbol != null) {
      allImages = [widget.initialSymbol!];
    } else if (widget.userId != null) {
      getSymbols();
    }

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pageController.dispose();
    _fadeController.dispose();
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void goNext() {
    if (_hasImages && currentIndex < allImages!.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void goPrev() {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Color hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.black;
    hex = hex.trim();
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) return Colors.black;
    return Color(int.parse(hex, radix: 16));
  }

  void _toggleLike() {
    if (!_isValidIndex) return;
    final symbol = allImages![currentIndex];
    final id = symbol.id ?? '';
    setState(() {
      if (_likedSymbolIds.contains(id)) {
        _likedSymbolIds.remove(id);
      } else {
        _likedSymbolIds.add(id);
      }
    });
  }

  Map<String, dynamic> _buildSymbolSnapshot(SymbolDetailsModel symbol) {
    return {
      '_id': symbol.id,
      'user_id': symbol.userId,
      'type': symbol.type,
      'content': symbol.content,
      'caption': symbol.caption,
      'backgroundColor': symbol.backgroundColor,
      'fontFamily': symbol.fontFamily,
      'fontSize': symbol.fontSize,
      'fontWeight': symbol.fontWeight,
      'visibility': symbol.visibility,
      'expires_at': symbol.expiresAt?.toIso8601String(),
      'created_at': symbol.createdAt?.toIso8601String(),
      // Include author so the receiver's bubble and the reopened symbol view
      // can render the creator without a separate fetch.
      'user': symbol.user?.toJson() ??
          {
            'id': symbol.userId,
            'name': widget.name,
            'profile_image': widget.profileImage,
          },
    };
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || !_isValidIndex) return;

    final symbol = allImages![currentIndex];
    final symbolId = symbol.id;
    final authorId = symbol.userId ?? widget.userId;
    if (symbolId == null || symbolId.isEmpty || authorId == null || authorId.isEmpty) {
      return;
    }

    _replyController.clear();
    _replyFocusNode.unfocus();

    final chatViewController =
        getOrPut(() => ChatViewController());
    final params = <String, dynamic>{
      ApiKeys.message_type: 'reply_to_symbol',
      ApiKeys.message: text,
      ApiKeys.other_user_id: authorId,
      ApiKeys.symbol_id: symbolId,
      ApiKeys.symbol_snapshot: jsonEncode(_buildSymbolSnapshot(symbol)),
    };
    await chatViewController.sendMessage(params);

    // Refresh personal + business chat lists so the new symbol-reply thread
    // (which may be a brand-new conversation) shows up in both views.
    chatViewController.emitEvent(ChatEmitEvents.ChatList,
        {ApiKeys.type: AppConstants.personal_Chat_Type});
    chatViewController.emitEvent(ChatEmitEvents.ChatList,
        {ApiKeys.type: AppConstants.business_Chat_Type});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.replySent.tr),
        backgroundColor: AppColors.primaryColor,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.inAppWebView);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: _hasImages
            ? _buildContent()
            : const Center(
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        /// Content Viewer
        FadeTransition(
          opacity: _fadeAnimation,
          child: PageView.builder(
            controller: _pageController,
            itemCount: allImages!.length,
            onPageChanged: (i) => setState(() => currentIndex = i),
            itemBuilder: (_, index) {
              final url = allImages![index];

              if (url.type == 'photo' || url.type == "video") {
                final isVideo = url.content?.toLowerCase().contains('.mp4') ?? false;
                return Stack(
                  children: [
                    if (isVideo)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ChatCustomVideoPlayer(
                            videoUrl: url.content ?? "",
                          ),
                        ),
                      )
                    else
                      Positioned.fill(
                        child: InteractiveViewer(
                          child: Center(
                            child: Image.network(
                              url.content ?? "",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: _isMySymbols ? 0 : 80,
                      child: (url.caption?.isNotEmpty ?? false)
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(26, 60, 26, 20),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black87,
                                  ],
                                ),
                              ),
                              child: CustomText(
                                "${url.caption}",
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            )
                          : const SizedBox(),
                    ),
                  ],
                );
              } else if (url.type == "text" || url.type == "embeddedUrl") {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: hexToColor(url.backgroundColor),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: buildLinkPreview(url.content ?? ''),
                          ),
                          if (url.content != null && url.content!.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: url.content!.contains('http')
                                  ? GestureDetector(
                                      onTap: () => _openUrl(url.content!),
                                      child: _buildUrlChip(url.content!),
                                    )
                                  : CustomText(
                                      textAlign: TextAlign.center,
                                      "${url.content}",
                                      fontWeight: addSymbolController.getFontWeight(url.fontWeight ?? 'normal'),
                                      fontSize: (url.fontSize ?? 18) * 1.1,
                                      fontFamily: url.fontFamily,
                                      color: Colors.white,
                                      height: 1.4,
                                    ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return const SizedBox();
              }
            },
          ),
        ),

        /// LEFT/RIGHT TAP REGIONS
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: goPrev,
                ),
              ),
              Expanded(
                flex: 6,
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(),
                ),
              ),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: goNext,
                ),
              ),
            ],
          ),
        ),

        /// Top bar: Profile info (left) + Close (right)
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Row(
            children: [
              // Profile image + Name
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white38, width: 1.5),
                        ),
                        child: ClipOval(
                          child: _buildProfileImage(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              _displayName ?? AppStrings.unknownLabel.tr,
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_isValidIndex && allImages![currentIndex].createdAt != null)
                              CustomText(
                                _formatTime(allImages![currentIndex].createdAt!),
                                color: Colors.white60,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Close button
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  color: Colors.black38,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Delete button for my symbols
        if (_isMySymbols && _isValidIndex)
          _deleteWidget(allImages![currentIndex]),

        /// Page indicator
        if (allImages!.length > 1)
          Positioned(
            bottom: _isMySymbols ? 25 : 90,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                allImages!.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: currentIndex == i ? 22 : 8,
                  decoration: BoxDecoration(
                    color: currentIndex == i ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),

        /// Bottom reply bar + like button (only for other's symbols)
        if (!_isMySymbols)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            bottom: MediaQuery.of(context).viewInsets.bottom > 0
                ? MediaQuery.of(context).viewInsets.bottom - MediaQuery.of(context).padding.bottom
                : 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 22),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  // Reply text field
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              focusNode: _replyFocusNode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: AppStrings.replyHint.tr,
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              textInputAction: TextInputAction.newline,
                              maxLines: null,
                            ),
                          ),
                          GestureDetector(
                            onTap: _sendReply,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.send_rounded,
                                color: Colors.white.withValues(alpha: 0.85),
                                size: 26,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Like (heart) button
                  GestureDetector(
                    onTap: _toggleLike,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: _isCurrentLiked()
                          ? const Icon(
                              Icons.favorite_rounded,
                              key: ValueKey('liked'),
                              color: Colors.redAccent,
                              size: 34,
                            )
                          : Icon(
                              Icons.favorite_border_rounded,
                              key: const ValueKey('unliked'),
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 34,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  bool _isCurrentLiked() {
    if (!_isValidIndex) return false;
    final symbol = allImages![currentIndex];
    return _likedSymbolIds.contains(symbol.id ?? '');
  }

  Widget _buildProfileImage() {
    final img = _displayImage;
    if (img == null || img.isEmpty) return _defaultAvatar();

    // Check if it's a local file path
    if (!img.startsWith('http')) {
      final file = File(img);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: 40,
          height: 40,
          errorBuilder: (_, __, ___) => _defaultAvatar(),
        );
      }
      return _defaultAvatar();
    }

    return Image.network(
      img,
      fit: BoxFit.cover,
      width: 40,
      height: 40,
      errorBuilder: (_, __, ___) => _defaultAvatar(),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 40,
      height: 40,
      color: Colors.grey.shade700,
      child: const Icon(Icons.person, color: Colors.white54, size: 24),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  Widget _buildUrlChip(String url) {
    String domain = url;
    try {
      domain = Uri.parse(url).host;
      if (domain.startsWith('www.')) domain = domain.substring(4);
    } catch (_) {}

    final faviconUrl = 'https://www.google.com/s2/favicons?domain=$domain&sz=64';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            faviconUrl,
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) => const Icon(Icons.language, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Text(
            domain,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget buildLinkPreview(String message) {
    final hasLink = message.contains("http");
    if (!hasLink) return const SizedBox.shrink();

    String link = message;
    final regExp = RegExp(r'(https?://\S+)');
    final match = regExp.firstMatch(message);
    if (match != null) {
      link = match.group(0)!;
    }

    final double squareSize = MediaQuery.of(context).size.width - 40;

    return GestureDetector(
      onTap: () => _openUrl(link),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: -10,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AnyLinkPreview.builder(
            link: link,
            cache: const Duration(days: 7),
            placeholderWidget: Container(
              height: squareSize,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade100, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor)),
            ),
            errorWidget: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.link_rounded, color: AppColors.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      link,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            itemBuilder: (context, metadata, imageProvider, svgImage) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageProvider != null)
                    SizedBox(
                      height: squareSize,
                      width: double.infinity,
                      child: Image(image: imageProvider, fit: BoxFit.cover),
                    )
                  else if (svgImage != null)
                    SizedBox(height: squareSize, width: double.infinity, child: svgImage),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (metadata.title != null && metadata.title!.isNotEmpty)
                          Text(
                            metadata.title!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1.2,
                              letterSpacing: -0.2,
                            ),
                          ),
                        if (metadata.desc != null && metadata.desc!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            metadata.desc!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _deleteWidget(SymbolDetailsModel symbol) {
    return Positioned(
      top: 14,
      right: 60,
      child: InkWell(
        onTap: () async {
          final deletedIndex = currentIndex;
          allImages = await addSymbolController.deleteSymbol(symbolData: symbol);

          if (allImages == null || allImages!.isEmpty) {
            Get.back();
            return;
          }

          if (deletedIndex >= allImages!.length) {
            currentIndex = allImages!.length - 1;
          } else {
            currentIndex = deletedIndex;
          }

          setState(() {});
          _pageController.jumpToPage(currentIndex);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Container(
            color: Colors.black26,
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
