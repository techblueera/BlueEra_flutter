import 'package:BlueEra/core/api/model/video_post_model.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/comment/view/comment_bottom_sheet.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/home/view/video_feed_listing/video_feed_controller.dart';
import 'package:BlueEra/features/common/home/view/video_feed_listing/video_player_item.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Import your other files: VideoFeedController, FeedController, VideoPlayerItem, etc.

class VideoFeedScreen extends StatefulWidget {
  final VideoPost videoData; // Assuming VideoPost is your model
  const VideoFeedScreen({super.key, required this.videoData});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  // Use 'tag' if you want separate feed instances, otherwise standard put is fine
  final controller = Get.put(VideoFeedController());
  final feedController = Get.put(FeedController());
  final PageController _pageController = PageController();

  // Local state for the UI index (faster than controller updates for animations)
  final RxInt currentIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    _setupInitialVideo();
  }

  void _setupInitialVideo() {
    // 1. Reset or prepare logic to avoid duplicates if controller stays alive
    if (controller.videos.isEmpty || controller.videos.first.id != widget.videoData.id) {
      // Only insert if it's not already the first item
      if (controller.videos.contains(widget.videoData)) {
        controller.videos.remove(widget.videoData);
      }
      // controller.videos.insert(0, widget.videoData);
    }

    // 2. Fetch API videos
    controller.fetchVideos(feedId: widget.videoData.id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // 3. REMOVED Obx() from here. Don't rebuild the whole PageView on change.
      body: SafeArea(
        child: Obx(() {
          // We wrap PageView in Obx ONLY to listen to 'controller.videos' changes (API load)
          // We do NOT listen to 'currentIndex' here.
          logs("controller.isLoading.value=== ${controller.isLoading.value}");
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: controller.videos.length,
            onPageChanged: (index) {
              // Update the reactive index for the items
              currentIndex.value = index;

              // Smart Pre-caching logic
              controller.updateCurrentIndex(index);
              controller.disposeDistantVideos(index);

              // Pagination
              if (index == controller.videos.length - 2 && controller.hasMore.value) {
                controller.fetchVideos(loadMore: true, feedId: '');
              }
            },
            itemBuilder: (context, index) {
              final video = controller.videos[index];

              // 4. Wrap ONLY the item in Obx to check 'isActive'.
              // This isolates the rebuild to just this specific video cell.
              return Obx(() {
                bool isActive = currentIndex.value == index;

                return VideoPlayerItem(
                  // 5. Key is CRITICAL for PageView stability
                  key: ValueKey(video.id),
                  video: video,
                  isActive: isActive,
                  onLikeToggle: () {
                    feedController.postLikeDislike(
                      postId: video.id,
                      type: PostType.all,
                    );
                    controller.toggleLike(index);
                  },
                  onCommentTap: () {
                    onCommentPressed(context, video);
                  },
                );
              });
            },
          );
        }),
      ),
    );
  }

  void onCommentPressed(BuildContext context, VideoPost _post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: CommentBottomSheet(
            id: _post.id,
            totalComments: _post.comments_count,
            commentType: CommentType.post,
            onNewCommentCount: (int newCommentCount) {
              feedController.updateCommentCount(
                  postId: _post.id,
                  type: PostType.all,
                  newCommentCount: newCommentCount);
            }),
      ),
    );
  }
}
/*
class VideoFeedScreenNew extends StatefulWidget {
  const VideoFeedScreenNew(
      {Key? key, required this.videoData, required this.likeFeed})
      : super(key: key);
  final VideoPost videoData;
  final VoidCallback likeFeed;

  @override
  State<VideoFeedScreenNew> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreenNew> {
  final controller = Get.put(VideoFeedController());
  final feedController = Get.put(FeedController());
  final PageController _pageController = PageController();
  final RxInt currentIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    _setupInitialVideo();
  }

  void _setupInitialVideo() {
    // Add clicked video first

    controller.videos.insert(0, widget.videoData);
    controller.fetchVideos(); // Load API videos after that
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        return SafeArea(
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: controller.videos.length,
            onPageChanged: (index) {
              currentIndex.value = index;

              // ✅ Update controller's current index for smart precaching
              controller.updateCurrentIndex(index);

              // ✅ Dispose distant videos to free memory
              controller.disposeDistantVideos(index);

              // Pagination trigger
              if (index == controller.videos.length - 2 &&
                  controller.hasMore.value) {
                controller.fetchVideos(loadMore: true);
              }
            },
            itemBuilder: (context, index) {
              final video = controller.videos[index];

              // 🟢 No Obx here
              return VideoPlayerItem(
                key: ValueKey(video.id),
                video: video,
                isActive: currentIndex.value == index,
                onLikeToggle: () {
                  feedController.postLikeDislike(
                    postId: video.id,
                    type: PostType.all,
                  );
                  controller.toggleLike(index);
                },
                onCommentTap: () {
                  onCommentPressed(context, video);
                },
              );
            },
          ),
        );
      }),
    );
  }


  void onCommentPressed(BuildContext context, VideoPost _post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          FractionallySizedBox(
            heightFactor: 0.8,
            child: CommentBottomSheet(
                id: _post.id,
                totalComments: _post.comments_count ?? 0,
                commentType: CommentType.post,
                onNewCommentCount: (int newCommentCount) {
                  feedController.updateCommentCount(
                      postId: _post.id,
                      type: PostType.all,
                      newCommentCount: newCommentCount);
                }),
          ),
    );
  }
}
*/

/*
/// Simple Video model
class VideoModel {
  final String id;
  final String url;
  final String avatar;
  final String authorName;
  final String title;
  int likes;
  int comments;
  bool isLiked;

  VideoModel({
    required this.id,
    required this.url,
    required this.avatar,
    required this.authorName,
    required this.title,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
  });
}



class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PageController _pageController = PageController();
  final FeedController controller = FeedController();

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    controller.loadInitialVideos();
    // Preload first page
    controller.preloadAtIndex(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar removed for immersive feel
      body: SafeArea(
        child: ValueListenableBuilder<List<VideoModel>>(
          valueListenable: controller.videosNotifier,
          builder: (context, videos, _) {
            if (videos.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: videos.length,
              onPageChanged: (index) {
                _currentIndex = index;
                controller.preloadAtIndex(index);
                controller.disposeDistant(index, keepRange: 1);
                // optionally fetch more when near end
                if (index >= videos.length - 2) {
                  controller.appendMore();
                }
              },
              itemBuilder: (context, index) {
                final v = videos[index];
                return VideoPlayerItem(
                  key: ValueKey(v.id),
                  video: v,
                  onLikeToggle: () {
                    controller.toggleLike(index);
                  },
                  onOpenComments: () {
                    _openCommentsSheet(context, v);
                  },
                  onShare: () {
                    // implement share logic or show snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share tapped')),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openCommentsSheet(BuildContext context, VideoModel video) {
    // Show a modal bottom sheet with DraggableScrollableSheet (TikTok style)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollCtrl) {
          return CommentSheet(video: video, scrollController: scrollCtrl);
        },
      ),
    );
  }
}

/// Controller manages list and video player controllers for preloading/disposal.
class FeedController {
  // list of videos (in real app fetch from backend)
  final ValueNotifier<List<VideoModel>> videosNotifier = ValueNotifier([]);
  final Map<int, VideoPlayerController> _playerControllers = {};

  // use to avoid double initialization
  final Set<int> _initializing = {};

  void loadInitialVideos() {
    // Replace these URLs with reachable H.264-encoded videos for best compatibility.
    final list = <VideoModel>[
      VideoModel(
        id: '1',
        url:
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        avatar:
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&q=80',
        authorName: 'Alice',
        title: 'Cute bee',
        likes: 123,
        comments: 4,
      ),
      VideoModel(
        id: '2',
        url:
        'https://interactive-examples.mdn.mozilla.net/media/examples/flower.mp4',
        avatar:
        'https://images.unsplash.com/photo-1545996124-1b9b1a7f4d4a?w=100&q=80',
        authorName: 'Bob',
        title: 'Flower timelapse',
        likes: 240,
        comments: 12,
      ),
      VideoModel(
        id: '3',
        url:
        'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
        avatar:
        'https://images.unsplash.com/photo-1545998037-4b5d9b2bd6ea?w=100&q=80',
        authorName: 'Carol',
        title: 'Short sample',
        likes: 12,
        comments: 1,
      ),
    ];

    videosNotifier.value = list;
  }

  /// preload current index and immediate neighbors
  void preloadAtIndex(int index) {
    for (int i = index - 1; i <= index + 1; i++) {
      if (i >= 0 && i < videosNotifier.value.length) {
        _ensureControllerForIndex(i);
      }
    }
  }

  /// Dispose controllers far away from the current index
  void disposeDistant(int index, {int keepRange = 1}) {
    final toRemove = <int>[];
    for (final k in _playerControllers.keys) {
      if ((k < index - keepRange) || (k > index + keepRange)) {
        _playerControllers[k]?.dispose();
        toRemove.add(k);
      }
    }
    for (final k in toRemove) _playerControllers.remove(k);
  }

  /// Append more mock videos
  void appendMore() {
    // in real app: fetch from backend
    final current = videosNotifier.value;
    final newOnes = List<VideoModel>.generate(2, (i) {
      final id = (current.length + i + 1).toString();
      return VideoModel(
        id: id,
        url:
        'https://samplelib.com/lib/preview/mp4/sample-10s.mp4',
        avatar:
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&q=80',
        authorName: 'User $id',
        title: 'More content $id',
        likes: 0,
        comments: 0,
      );
    });
    videosNotifier.value = [...current, ...newOnes];
  }

  /// Toggle like for a given video index
  void toggleLike(int index) {
    final list = [...videosNotifier.value];
    final v = list[index];
    v.isLiked = !v.isLiked;
    v.likes += v.isLiked ? 1 : -1;
    videosNotifier.value = list;
  }

  /// Ensure there is a VideoPlayerController for an index (init if needed)
  Future<VideoPlayerController?> _ensureControllerForIndex(int index) async {
    if (_playerControllers.containsKey(index)) {
      return _playerControllers[index];
    }
    if (_initializing.contains(index)) return _playerControllers[index];
    final videos = videosNotifier.value;
    if (index < 0 || index >= videos.length) return null;

    _initializing.add(index);

    try {
      final controller = VideoPlayerController.network(videos[index].url);
      _playerControllers[index] = controller;
      await controller.initialize();
      controller.setLooping(true);
      // keep paused by default; player widget will play when visible
    } catch (e) {
      // initialization failed
      debugPrint('Error init video at $index: $e');
      _playerControllers.remove(index);
    } finally {
      _initializing.remove(index);
    }
    return _playerControllers[index];
  }

  /// Get controller if initialized (may be null)
  VideoPlayerController? getController(int index) {
    return _playerControllers[index];
  }

  /// Optionally a public API for VideoPlayerItem to request init
  Future<VideoPlayerController?> requestController(int index) {
    return _ensureControllerForIndex(index);
  }

  void dispose() {
    for (final c in _playerControllers.values) {
      try {
        c.dispose();
      } catch (_) {}
    }
    _playerControllers.clear();
    videosNotifier.dispose();
  }
}

/// Video player item widget
class VideoPlayerItem extends StatefulWidget {
  final VideoModel video;
  final VoidCallback onLikeToggle;
  final VoidCallback onOpenComments;
  final VoidCallback onShare;

  const VideoPlayerItem({
    super.key,
    required this.video,
    required this.onLikeToggle,
    required this.onOpenComments,
    required this.onShare,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _initialized = false;
  bool _showCenterPlay = false;

  // double tap heart
  bool _showHeart = false;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScale;

  Timer? _positionTimer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _heartAnimController, curve: Curves.elasticOut),
    );
    // controller will be requested when this item becomes visible (VisibilityDetector)
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    try {
      _controller?.pause();
      // do not dispose controller here if it's managed by FeedController in a real app.
      _controller?.dispose();
    } catch (_) {}
    _heartAnimController.dispose();
    super.dispose();
  }

  Future<void> _initialize(String url) async {
    // initialize local controller (we allow each widget to init its own controller)
    // In production you might use a shared controller from central FeedController to avoid multiple downloads.
    if (_controller != null) return;

    _controller = VideoPlayerController.network(url);

    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
      setState(() {
        _initialized = true;
        _duration = _controller!.value.duration;
      });
      _startPositionTimer();
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) {
        setState(() => _initialized = false);
      }
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      if (_controller != null && _controller!.value.isInitialized) {
        final pos = _controller!.value.position;
        if (mounted) setState(() => _position = pos);
      }
    });
  }

  String _formatTime(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _togglePlay() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() {
        _isPlaying = false;
        _showCenterPlay = true;
      });
    } else {
      _controller!.play();
      setState(() {
        _isPlaying = true;
        _showCenterPlay = false;
      });
    }
    // hide center icon after a bit
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showCenterPlay = false);
    });
  }

  void _onDoubleTap() {
    // like
    widget.onLikeToggle();
    setState(() {
      _showHeart = true;
    });
    _heartAnimController.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('visibility-${widget.video.id}'),
      onVisibilityChanged: (info) async {
        final visible = info.visibleFraction > 0.6;

        if (visible && !_initialized) {
          await _initialize(widget.video.url);
        }

        if (_controller != null && _controller!.value.isInitialized) {
          if (visible) {
            await _controller!.play();
            setState(() {
              _isPlaying = true;
            });
          } else {
            await _controller!.pause();
            setState(() => _isPlaying = false);
          }
        }
      },
      child: Stack(
        children: [
          // video area
          Positioned.fill(
            child: _controller != null && _controller!.value.isInitialized
                ? GestureDetector(
              onDoubleTap: _onDoubleTap,
              onTap: _togglePlay,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  ),

                  // center play/pause overlay
                  if (_showCenterPlay || !_isPlaying)
                    AnimatedOpacity(
                      opacity: (_showCenterPlay || !_isPlaying) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // big heart animation
                  if (_showHeart)
                    ScaleTransition(
                      scale: _heartScale,
                      child: const Icon(
                        Icons.favorite,
                        size: 120,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            )
                : const Center(child: CircularProgressIndicator()),
          ),

          // Top-left author row
          Positioned(
            left: 12,
            top: 12,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[700],
                  backgroundImage: CachedNetworkImageProvider(widget.video.avatar),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.video.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.video.title,
                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),

          // Bottom timeline & title
          Positioned(
            left: 12,
            right: 12,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_controller != null && _controller!.value.isInitialized)
                  VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    colors: const VideoProgressColors(
                      playedColor: Colors.white,
                      backgroundColor: Colors.white30,
                      bufferedColor: Colors.grey,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatTime(_position)} / ${_formatTime(_duration)}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: widget.onShare,
                          icon: const Icon(Icons.share, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: widget.onOpenComments,
                          icon: const Icon(Icons.comment, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right side action column (like, comment count, share)
          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: widget.onLikeToggle,
                  child: Column(
                    children: [
                      Icon(
                        widget.video.isLiked ? Icons.favorite : Icons.favorite_outline,
                        color: widget.video.isLiked ? Colors.red : Colors.white,
                        size: 36,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.video.likes.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: widget.onOpenComments,
                  child: Column(
                    children: [
                      const Icon(Icons.comment, color: Colors.white, size: 36),
                      const SizedBox(height: 6),
                      Text(widget.video.comments.toString(),
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: widget.onShare,
                  child: Column(
                    children: const [
                      Icon(Icons.share, color: Colors.white, size: 32),
                      SizedBox(height: 6),
                      Text('Share', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple comment sheet widget (replace with your real backend & UI)
class CommentSheet extends StatefulWidget {
  final VideoModel video;
  final ScrollController scrollController;
  const CommentSheet({super.key, required this.video, required this.scrollController});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _text = TextEditingController();
  final List<String> _mockComments = [
    'Nice video!',
    'Loved this 😊',
    'Where did you film this?',
    'Awesome content — keep it up!'
  ];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _postComment() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _mockComments.insert(0, text);
      widget.video.comments += 1;
      _text.clear();
    });
    // hide keyboard
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // top bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: _mockComments.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(widget.video.avatar),
                    ),
                    title: Text(widget.video.authorName),
                    subtitle: Text('${widget.video.comments} comments'),
                  );
                }
                final comment = _mockComments[index - 1];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(comment),
                  subtitle: const Text('1h'),
                );
              },
            ),
          ),

          // input
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.white10,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _postComment,
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text('Post'),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/
