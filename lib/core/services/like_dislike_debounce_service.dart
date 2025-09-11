import 'dart:async';
import 'package:get/get.dart';

/// Service to handle optimistic UI for like/dislike operations with debouncing
class LikeDislikeDebounceService extends GetxService {
  static LikeDislikeDebounceService get instance => Get.find<LikeDislikeDebounceService>();

  // Map to store pending API calls for each item
  final Map<String, Future<void>?> _pendingLikeCalls = {};
  
  // Map to store the last intended state for each item
  final Map<String, bool> _lastIntendedLikeState = {};

  Future<void> handleLikeDislike({
    required String itemId,
    required bool currentIsLiked,
    required int currentLikesCount,
    required Function(bool newIsLiked, int newLikesCount) onOptimisticUpdate,
    required Future<void> Function() onApiCall,
    int debounceMs = 400,
  }) async {
    // Calculate new state
    final newIsLiked = !currentIsLiked;
    final newLikesCount = currentLikesCount + (newIsLiked ? 1 : -1);

    // Store the user's last intended state
    _lastIntendedLikeState[itemId] = newIsLiked;

    // Apply optimistic update immediately
    onOptimisticUpdate(newIsLiked, newLikesCount);

    // If there's already a pending call, just update the intended state and return
    if (_pendingLikeCalls[itemId] != null) {
      return; // The pending call will check _lastIntendedLikeState before making API call
    }

    // Start the debounced API call
    _pendingLikeCalls[itemId] = _debouncedApiCall(
      itemId: itemId,
      onApiCall: onApiCall,
      debounceMs: debounceMs,
    );
  }

  Future<void> _debouncedApiCall({
    required String itemId,
    required Future<void> Function() onApiCall,
    required int debounceMs,
  }) async {
    // Wait for debounce period (let user finish rapid tapping)
    await Future.delayed(Duration(milliseconds: debounceMs));

    try {
      // Get the user's FINAL intended state
      final finalIntendedState = _lastIntendedLikeState[itemId];
      if (finalIntendedState == null) return;

      // Make the API call
      await onApiCall();

      // Clear the intended state after successful API call
      _lastIntendedLikeState.remove(itemId);
    } catch (e) {
      // Handle error - you might want to revert the optimistic update here
      print('Error in debounced API call for $itemId: $e');
    } finally {
      // Clear the pending call
      _pendingLikeCalls.remove(itemId);
    }
  }

  /// Cancel any pending like/dislike operation for a specific item
  void cancelPendingOperation(String itemId) {
    _pendingLikeCalls.remove(itemId);
    _lastIntendedLikeState.remove(itemId);
  }

  /// Clear all pending operations (useful for cleanup)
  void clearAllPendingOperations() {
    _pendingLikeCalls.clear();
    _lastIntendedLikeState.clear();
  }

  /// Check if there's a pending operation for a specific item
  bool hasPendingOperation(String itemId) {
    return _pendingLikeCalls.containsKey(itemId);
  }
}
