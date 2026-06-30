import 'dart:developer';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/services/keyed_json_cache.dart';
import 'package:BlueEra/features/chat/auth/repo/symbol_repo.dart';
import 'package:BlueEra/features/common/home/model/symbol_feed_model.dart';
import 'package:get/get.dart';

class SymbolFeedController extends GetxController {
  final RxList<SymbolUserGroup> userGroups = <SymbolUserGroup>[].obs;
  final RxBool isLoading = false.obs;

  /// Comments for the currently viewed symbol
  final RxList<SymbolComment> comments = <SymbolComment>[].obs;
  final RxBool isLoadingComments = false.obs;

  final _repo = SymbolRepo();

  @override
  void onInit() {
    super.onInit();
    fetchSymbolFeed();
  }

  Future<void> fetchSymbolFeed() async {
    try {
      // Paint the last-cached story row instantly so the Social tab strip isn't
      // blank on first open while the live symbol feed loads. The story-row
      // widget only shows its loader when [userGroups] is empty, so a cache hit
      // suppresses the spinner.
      if (userGroups.isEmpty) {
        await _hydrateSymbolsFromCache();
      }

      isLoading.value = true;

      final response = await _repo.fetchSymbolFeed(
        params: {'page': 1, 'limit': 20, 'populate': true, 'grouped': true},
      );

      if (response.isSuccess) {
        final rawData = response.response?.data['data'] ?? {};
        final parsed =
            SymbolGroupedData.fromJson(Map<String, dynamic>.from(rawData));
        final groups = parsed.groups ?? [];

        // Sort: unseen groups first, then seen groups
        groups.sort((a, b) {
          if (a.hasUnseen && !b.hasUnseen) return -1;
          if (!a.hasUnseen && b.hasUnseen) return 1;
          return 0;
        });

        userGroups.assignAll(groups);

        // Cache the raw grouped data so the next cold open paints instantly.
        await _cacheSymbols(rawData);
      }
    } catch (e, s) {
      log('fetchSymbolFeed error: $e\n$s');
    } finally {
      isLoading.value = false;
    }
  }

  /// How long a cached symbol story row stays usable offline before it's
  /// treated as stale and dropped.
  static const Duration _symbolCacheTtl = Duration(days: 1);

  /// Loads the last-cached symbol story row (first 5 user groups) so the Social
  /// tab strip renders immediately on open. No-op on a cache miss, stale entry,
  /// or parse error.
  Future<void> _hydrateSymbolsFromCache() async {
    try {
      final cached = await symbolFeedCache.get(userId);
      if (cached == null) return;
      if (_isCacheStale(cached['cachedAt'], _symbolCacheTtl)) {
        await symbolFeedCache.clear();
        return;
      }
      final rawData = cached['data'];
      if (rawData is Map) {
        final parsed =
            SymbolGroupedData.fromJson(Map<String, dynamic>.from(rawData));
        final groups = (parsed.groups ?? []).take(5).toList();
        if (groups.isNotEmpty) {
          groups.sort((a, b) {
            if (a.hasUnseen && !b.hasUnseen) return -1;
            if (!a.hasUnseen && b.hasUnseen) return 1;
            return 0;
          });
          userGroups.assignAll(groups);
        }
      }
    } catch (e) {
      log('hydrateSymbolsFromCache error: $e');
    }
  }

  /// Persists the raw symbol grouped-data JSON (with a timestamp for expiry) for
  /// the next cold open.
  Future<void> _cacheSymbols(dynamic rawData) async {
    try {
      if (rawData is Map) {
        await symbolFeedCache.save(userId, {
          'cachedAt': DateTime.now().millisecondsSinceEpoch,
          'data': Map<String, dynamic>.from(rawData),
        });
      }
    } catch (e) {
      log('cacheSymbols error: $e');
    }
  }

  /// True when [cachedAtMs] is missing or older than [ttl].
  bool _isCacheStale(dynamic cachedAtMs, Duration ttl) {
    if (cachedAtMs is! int) return true;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
    return DateTime.now().difference(cachedAt) > ttl;
  }

  /// Mark a symbol as viewed
  Future<void> markAsViewed(String symbolId) async {
    try {
      final response = await _repo.markSymbolViewed(symbolId);
      if (response.isSuccess) {
        // Update local state
        for (final group in userGroups) {
          for (final symbol in group.symbols) {
            if (symbol.id == symbolId && symbol.hasSeen != true) {
              symbol.hasSeen = true;
              symbol.seenCount = (symbol.seenCount ?? 0) + 1;
              break;
            }
          }
        }
        userGroups.refresh();
      }
    } catch (e) {
      log('markAsViewed error: $e');
    }
  }

  /// Toggle like on a symbol
  Future<void> toggleLike(SymbolFeedItem symbol) async {
    try {
      final wasLiked = symbol.hasLiked == true;

      // Optimistic update
      symbol.hasLiked = !wasLiked;
      symbol.likesCount =
          (symbol.likesCount ?? 0) + (wasLiked ? -1 : 1);
      userGroups.refresh();

      final response = wasLiked
          ? await _repo.unlikeSymbol(symbol.id!)
          : await _repo.likeSymbol(symbol.id!);

      if (!response.isSuccess) {
        // Revert on failure
        symbol.hasLiked = wasLiked;
        symbol.likesCount =
            (symbol.likesCount ?? 0) + (wasLiked ? 1 : -1);
        userGroups.refresh();
      }
    } catch (e) {
      log('toggleLike error: $e');
    }
  }

  /// Fetch comments for a symbol
  Future<void> fetchComments(String symbolId) async {
    try {
      isLoadingComments.value = true;
      comments.clear();

      final response = await _repo.getComments(symbolId);
      if (response.isSuccess) {
        final responseData = response.response?.data;
        List<dynamic> rawComments = [];

        if (responseData is List) {
          rawComments = responseData;
        } else if (responseData is Map) {
          final inner = responseData['data'];
          if (inner is List) {
            rawComments = inner;
          } else if (inner is Map) {
            rawComments = inner['comments'] is List ? inner['comments'] : [];
          }
        }


        comments.assignAll(
          rawComments
              .map((c) => SymbolComment.fromJson(Map<String, dynamic>.from(c)))
              .toList(),
        );
      }
    } catch (e) {
      log('fetchComments error: $e');
    } finally {
      isLoadingComments.value = false;
    }
  }

  /// Add a comment
  Future<bool> addComment(String symbolId, String commentText) async {
    try {
      final response = await _repo.addComment(symbolId, commentText);
      if (response.isSuccess) {
        // Update comments count locally
        _updateCommentCount(symbolId, 1);
        // Refresh comments list
        await fetchComments(symbolId);
        return true;
      }
    } catch (e) {
      log('addComment error: $e');
    }
    return false;
  }

  /// Edit own comment
  Future<bool> editComment(
      String symbolId, String commentId, String newText) async {
    try {
      final response = await _repo.editComment(commentId, newText);
      if (response.isSuccess) {
        await fetchComments(symbolId);
        return true;
      }
    } catch (e) {
      log('editComment error: $e');
    }
    return false;
  }

  /// Delete own comment
  Future<bool> deleteComment(String symbolId, String commentId) async {
    try {
      final response = await _repo.deleteComment(commentId);
      if (response.isSuccess) {
        _updateCommentCount(symbolId, -1);
        comments.removeWhere((c) => c.id == commentId);
        return true;
      }
    } catch (e) {
      log('deleteComment error: $e');
    }
    return false;
  }

  void _updateCommentCount(String symbolId, int delta) {
    for (final group in userGroups) {
      for (final symbol in group.symbols) {
        if (symbol.id == symbolId) {
          symbol.commentsCount = (symbol.commentsCount ?? 0) + delta;
          break;
        }
      }
    }
    userGroups.refresh();
  }

  /// Check if a comment belongs to the current user
  bool isOwnComment(SymbolComment comment) {
    return comment.userId == userId;
  }
}
