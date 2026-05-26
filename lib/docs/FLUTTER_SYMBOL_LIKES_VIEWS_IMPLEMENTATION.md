# Flutter Implementation: Symbol Liked Users & Viewed Users

## Overview

This guide covers implementing two bottom sheets that show **who liked** and **who viewed** a particular symbol (status/story). Two API approaches available — pick based on your needs.

---

## API Endpoints

### Approach 1: Standalone Endpoints (Simple, No Pagination)

Returns full list in one call.

```
GET /symbols/:symbolId/likes
GET /symbols/:symbolId/views
```

**Headers:**
```
Authorization: Bearer <token>
   OR
x-session-id: <sessionId>
```

### Approach 2: Symbol Detail with Opt-in Population (Paginated)

Returns paginated likes/views as part of symbol detail.

```
GET /symbols/:symbolId?include=likes,seen&likesPage=1&likesLimit=20&seenPage=1&seenLimit=20
```

| Query Param   | Default | Max | Description             |
|---------------|---------|-----|-------------------------|
| include       | creator | -   | CSV: creator,comments,likes,seen,tagged_users |
| likesPage     | 1       | -   | Page number for likes   |
| likesLimit    | 10      | 100 | Items per page for likes|
| seenPage      | 1       | -   | Page number for views   |
| seenLimit     | 10      | 100 | Items per page for views|

---

## Response Structures

### GET /symbols/:symbolId/likes (Standalone)

```json
[
  {
    "_id": "6654abc123def456",
    "user_id": "usr_abc123",
    "symbol_id": "6654abc123def789",
    "created_at": "2026-05-26T10:30:00.000Z",
    "updated_at": "2026-05-26T10:30:00.000Z",
    "user": {
      "id": "usr_abc123",
      "name": "John Doe",
      "profile_image": "https://s3.amazonaws.com/bucket/profile/abc.jpg",
      "contact_no": "+919876543210",
      "account_type": "PERSONAL",
      "email": "john@example.com"
    }
  }
]
```

### GET /symbols/:symbolId/views (Standalone)

```json
[
  {
    "_id": "6654abc123def456",
    "user_id": "usr_xyz789",
    "symbol_id": "6654abc123def789",
    "seen_at": "2026-05-26T11:00:00.000Z",
    "updated_at": "2026-05-26T11:00:00.000Z",
    "user": {
      "id": "usr_xyz789",
      "name": "Jane Smith",
      "profile_image": "https://s3.amazonaws.com/bucket/profile/xyz.jpg",
      "contact_no": "+919876543211",
      "account_type": "BUSINESS",
      "email": "jane@example.com"
    }
  }
]
```

### GET /symbols/:symbolId?include=likes,seen (Paginated)

```json
{
  "status": true,
  "message": "Symbol fetched successfully",
  "data": {
    "symbol": {
      "_id": "6654abc123def789",
      "user_id": "usr_owner",
      "type": "photo",
      "content": "https://s3.amazonaws.com/bucket/symbol/img.jpg",
      "caption": "Hello world",
      "visibility": "public",
      "likes_count": 42,
      "comments_count": 5,
      "seen_count": 120,
      "has_liked": true,
      "has_seen": true,
      "created_at": "2026-05-26T08:00:00.000Z"
    },
    "likes": {
      "items": [
        {
          "_id": "6654abc123def456",
          "user_id": "usr_abc123",
          "symbol_id": "6654abc123def789",
          "created_at": "2026-05-26T10:30:00.000Z",
          "user": {
            "id": "usr_abc123",
            "name": "John Doe",
            "profile_image": "https://s3.amazonaws.com/bucket/profile/abc.jpg",
            "contact_no": "+919876543210",
            "account_type": "PERSONAL"
          }
        }
      ],
      "pagination": {
        "page": 1,
        "limit": 20,
        "total": 42,
        "totalPages": 3,
        "hasNextPage": true,
        "hasPrevPage": false
      }
    },
    "seen": {
      "items": [
        {
          "_id": "6654abc123def456",
          "user_id": "usr_xyz789",
          "symbol_id": "6654abc123def789",
          "seen_at": "2026-05-26T11:00:00.000Z",
          "user": {
            "id": "usr_xyz789",
            "name": "Jane Smith",
            "profile_image": "https://s3.amazonaws.com/bucket/profile/xyz.jpg",
            "contact_no": "+919876543211",
            "account_type": "BUSINESS"
          }
        }
      ],
      "pagination": {
        "page": 1,
        "limit": 20,
        "total": 120,
        "totalPages": 6,
        "hasNextPage": true,
        "hasPrevPage": false
      }
    }
  }
}
```

---

## User Object Fields

Every populated user object has this shape:

| Field           | Type   | Description                                          |
|-----------------|--------|------------------------------------------------------|
| id              | String | User platform ID                                     |
| name            | String | Resolved display name (see priority below)           |
| profile_image   | String | S3 URL or null                                       |
| contact_no      | String | Phone number                                         |
| account_type    | String | "PERSONAL" or "BUSINESS"                             |
| email           | String | Email (may be null)                                  |

**Name Resolution Priority** (server handles this — you always get `name`):
1. Viewer's saved contact name (from your phone contacts synced to app)
2. Business name (if account_type is BUSINESS)
3. User's profile name
4. Phone number as fallback

---

## Full Flutter Implementation

### 1. Models

```dart
// lib/models/symbol_user_interaction.dart

class SymbolLikeUser {
  final String id;
  final String userId;
  final String symbolId;
  final DateTime createdAt;
  final InteractionUser? user;

  SymbolLikeUser({
    required this.id,
    required this.userId,
    required this.symbolId,
    required this.createdAt,
    this.user,
  });

  factory SymbolLikeUser.fromJson(Map<String, dynamic> json) {
    return SymbolLikeUser(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      symbolId: json['symbol_id'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      user: json['user'] != null ? InteractionUser.fromJson(json['user']) : null,
    );
  }
}

class SymbolViewUser {
  final String id;
  final String userId;
  final String symbolId;
  final DateTime seenAt;
  final InteractionUser? user;

  SymbolViewUser({
    required this.id,
    required this.userId,
    required this.symbolId,
    required this.seenAt,
    this.user,
  });

  factory SymbolViewUser.fromJson(Map<String, dynamic> json) {
    return SymbolViewUser(
      id: json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      symbolId: json['symbol_id'] ?? '',
      seenAt: DateTime.parse(json['seen_at'] ?? DateTime.now().toIso8601String()),
      user: json['user'] != null ? InteractionUser.fromJson(json['user']) : null,
    );
  }
}

class InteractionUser {
  final String id;
  final String name;
  final String? profileImage;
  final String? contactNo;
  final String? accountType;
  final String? email;

  InteractionUser({
    required this.id,
    required this.name,
    this.profileImage,
    this.contactNo,
    this.accountType,
    this.email,
  });

  factory InteractionUser.fromJson(Map<String, dynamic> json) {
    return InteractionUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      profileImage: json['profile_image'],
      contactNo: json['contact_no'],
      accountType: json['account_type'],
      email: json['email'],
    );
  }

  bool get isBusiness => accountType?.toUpperCase() == 'BUSINESS';
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
    );
  }
}

class PaginatedResult<T> {
  final List<T> items;
  final PaginationInfo pagination;

  PaginatedResult({required this.items, required this.pagination});
}
```

### 2. API Service

```dart
// lib/services/symbol_interaction_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/symbol_user_interaction.dart';

class SymbolInteractionService {
  final String baseUrl;
  final String Function() getAuthToken; // or getSessionId

  SymbolInteractionService({
    required this.baseUrl,
    required this.getAuthToken,
  });

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${getAuthToken()}',
    // OR use: 'x-session-id': getSessionId(),
  };

  // ── Standalone: Full list, no pagination ──

  Future<List<SymbolLikeUser>> getLikedUsers(String symbolId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/symbols/$symbolId/likes'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => SymbolLikeUser.fromJson(e)).toList();
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<List<SymbolViewUser>> getViewedUsers(String symbolId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/symbols/$symbolId/views'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => SymbolViewUser.fromJson(e)).toList();
    }
    throw ApiException(response.statusCode, response.body);
  }

  // ── Paginated: Via symbol detail endpoint ──

  Future<PaginatedResult<SymbolLikeUser>> getLikedUsersPaginated(
    String symbolId, {
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/symbols/$symbolId').replace(
      queryParameters: {
        'include': 'likes',
        'likesPage': page.toString(),
        'likesLimit': limit.toString(),
      },
    );

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final likesData = body['data']['likes'];
      final items = (likesData['items'] as List)
          .map((e) => SymbolLikeUser.fromJson(e))
          .toList();
      final pagination = PaginationInfo.fromJson(likesData['pagination']);
      return PaginatedResult(items: items, pagination: pagination);
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<PaginatedResult<SymbolViewUser>> getViewedUsersPaginated(
    String symbolId, {
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/symbols/$symbolId').replace(
      queryParameters: {
        'include': 'seen',
        'seenPage': page.toString(),
        'seenLimit': limit.toString(),
      },
    );

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final seenData = body['data']['seen'];
      final items = (seenData['items'] as List)
          .map((e) => SymbolViewUser.fromJson(e))
          .toList();
      final pagination = PaginationInfo.fromJson(seenData['pagination']);
      return PaginatedResult(items: items, pagination: pagination);
    }
    throw ApiException(response.statusCode, response.body);
  }

  // ── Fetch both likes + views in single call (paginated) ──

  Future<({PaginatedResult<SymbolLikeUser> likes, PaginatedResult<SymbolViewUser> views})>
      getLikesAndViewsPaginated(
    String symbolId, {
    int likesPage = 1,
    int likesLimit = 20,
    int seenPage = 1,
    int seenLimit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/symbols/$symbolId').replace(
      queryParameters: {
        'include': 'likes,seen',
        'likesPage': likesPage.toString(),
        'likesLimit': likesLimit.toString(),
        'seenPage': seenPage.toString(),
        'seenLimit': seenLimit.toString(),
      },
    );

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final data = body['data'];

      final likesData = data['likes'];
      final likeItems = (likesData['items'] as List)
          .map((e) => SymbolLikeUser.fromJson(e))
          .toList();
      final likesPagination = PaginationInfo.fromJson(likesData['pagination']);

      final seenData = data['seen'];
      final viewItems = (seenData['items'] as List)
          .map((e) => SymbolViewUser.fromJson(e))
          .toList();
      final viewsPagination = PaginationInfo.fromJson(seenData['pagination']);

      return (
        likes: PaginatedResult(items: likeItems, pagination: likesPagination),
        views: PaginatedResult(items: viewItems, pagination: viewsPagination),
      );
    }
    throw ApiException(response.statusCode, response.body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
```

### 3. State Management (Provider)

```dart
// lib/providers/symbol_interaction_provider.dart

import 'package:flutter/material.dart';
import '../models/symbol_user_interaction.dart';
import '../services/symbol_interaction_service.dart';

class SymbolInteractionProvider extends ChangeNotifier {
  final SymbolInteractionService _service;

  SymbolInteractionProvider(this._service);

  // ── Likes State ──
  List<SymbolLikeUser> _likedUsers = [];
  List<SymbolLikeUser> get likedUsers => _likedUsers;

  PaginationInfo? _likesPagination;
  PaginationInfo? get likesPagination => _likesPagination;

  bool _isLoadingLikes = false;
  bool get isLoadingLikes => _isLoadingLikes;

  bool _isLoadingMoreLikes = false;
  bool get isLoadingMoreLikes => _isLoadingMoreLikes;

  // ── Views State ──
  List<SymbolViewUser> _viewedUsers = [];
  List<SymbolViewUser> get viewedUsers => _viewedUsers;

  PaginationInfo? _viewsPagination;
  PaginationInfo? get viewsPagination => _viewsPagination;

  bool _isLoadingViews = false;
  bool get isLoadingViews => _isLoadingViews;

  bool _isLoadingMoreViews = false;
  bool get isLoadingMoreViews => _isLoadingMoreViews;

  String? _error;
  String? get error => _error;

  // ── Load likes (first page) ──
  Future<void> loadLikedUsers(String symbolId, {bool paginated = true}) async {
    _isLoadingLikes = true;
    _error = null;
    notifyListeners();

    try {
      if (paginated) {
        final result = await _service.getLikedUsersPaginated(symbolId, page: 1, limit: 20);
        _likedUsers = result.items;
        _likesPagination = result.pagination;
      } else {
        _likedUsers = await _service.getLikedUsers(symbolId);
        _likesPagination = null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingLikes = false;
      notifyListeners();
    }
  }

  // ── Load more likes (next page) ──
  Future<void> loadMoreLikedUsers(String symbolId) async {
    if (_likesPagination == null || !_likesPagination!.hasNextPage || _isLoadingMoreLikes) return;

    _isLoadingMoreLikes = true;
    notifyListeners();

    try {
      final result = await _service.getLikedUsersPaginated(
        symbolId,
        page: _likesPagination!.page + 1,
        limit: _likesPagination!.limit,
      );
      _likedUsers.addAll(result.items);
      _likesPagination = result.pagination;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMoreLikes = false;
      notifyListeners();
    }
  }

  // ── Load views (first page) ──
  Future<void> loadViewedUsers(String symbolId, {bool paginated = true}) async {
    _isLoadingViews = true;
    _error = null;
    notifyListeners();

    try {
      if (paginated) {
        final result = await _service.getViewedUsersPaginated(symbolId, page: 1, limit: 20);
        _viewedUsers = result.items;
        _viewsPagination = result.pagination;
      } else {
        _viewedUsers = await _service.getViewedUsers(symbolId);
        _viewsPagination = null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingViews = false;
      notifyListeners();
    }
  }

  // ── Load more views (next page) ──
  Future<void> loadMoreViewedUsers(String symbolId) async {
    if (_viewsPagination == null || !_viewsPagination!.hasNextPage || _isLoadingMoreViews) return;

    _isLoadingMoreViews = true;
    notifyListeners();

    try {
      final result = await _service.getViewedUsersPaginated(
        symbolId,
        page: _viewsPagination!.page + 1,
        limit: _viewsPagination!.limit,
      );
      _viewedUsers.addAll(result.items);
      _viewsPagination = result.pagination;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMoreViews = false;
      notifyListeners();
    }
  }

  // ── Load both in single API call ──
  Future<void> loadBothLikesAndViews(String symbolId) async {
    _isLoadingLikes = true;
    _isLoadingViews = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getLikesAndViewsPaginated(symbolId);
      _likedUsers = result.likes.items;
      _likesPagination = result.likes.pagination;
      _viewedUsers = result.views.items;
      _viewsPagination = result.views.pagination;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingLikes = false;
      _isLoadingViews = false;
      notifyListeners();
    }
  }

  void clear() {
    _likedUsers = [];
    _viewedUsers = [];
    _likesPagination = null;
    _viewsPagination = null;
    _error = null;
    notifyListeners();
  }
}
```

### 4. UI — Bottom Sheet with Tabs

```dart
// lib/widgets/symbol_interactions_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/symbol_user_interaction.dart';
import '../providers/symbol_interaction_provider.dart';

class SymbolInteractionsSheet extends StatefulWidget {
  final String symbolId;
  final int likesCount;
  final int viewsCount;
  final int initialTab; // 0 = likes, 1 = views

  const SymbolInteractionsSheet({
    super.key,
    required this.symbolId,
    required this.likesCount,
    required this.viewsCount,
    this.initialTab = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required String symbolId,
    required int likesCount,
    required int viewsCount,
    int initialTab = 0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SymbolInteractionsSheet(
        symbolId: symbolId,
        likesCount: likesCount,
        viewsCount: viewsCount,
        initialTab: initialTab,
      ),
    );
  }

  @override
  State<SymbolInteractionsSheet> createState() => _SymbolInteractionsSheetState();
}

class _SymbolInteractionsSheetState extends State<SymbolInteractionsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _likesScrollController;
  late ScrollController _viewsScrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _likesScrollController = ScrollController()..addListener(_onLikesScroll);
    _viewsScrollController = ScrollController()..addListener(_onViewsScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SymbolInteractionProvider>();
      provider.loadBothLikesAndViews(widget.symbolId);
    });
  }

  void _onLikesScroll() {
    if (_likesScrollController.position.pixels >=
        _likesScrollController.position.maxScrollExtent - 200) {
      context.read<SymbolInteractionProvider>().loadMoreLikedUsers(widget.symbolId);
    }
  }

  void _onViewsScroll() {
    if (_viewsScrollController.position.pixels >=
        _viewsScrollController.position.maxScrollExtent - 200) {
      context.read<SymbolInteractionProvider>().loadMoreViewedUsers(widget.symbolId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _likesScrollController.dispose();
    _viewsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Tab bar
              Consumer<SymbolInteractionProvider>(
                builder: (context, provider, _) {
                  final likesTotal = provider.likesPagination?.total ?? widget.likesCount;
                  final viewsTotal = provider.viewsPagination?.total ?? widget.viewsCount;
                  return TabBar(
                    controller: _tabController,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).primaryColor,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite, size: 18),
                            const SizedBox(width: 6),
                            Text('Likes ($likesTotal)'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.visibility, size: 18),
                            const SizedBox(width: 6),
                            Text('Views ($viewsTotal)'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const Divider(height: 1),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _LikesTab(
                      scrollController: _likesScrollController,
                    ),
                    _ViewsTab(
                      scrollController: _viewsScrollController,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Likes Tab ──

class _LikesTab extends StatelessWidget {
  final ScrollController scrollController;

  const _LikesTab({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<SymbolInteractionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingLikes) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.likedUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => provider.loadLikedUsers(
                    (context.findAncestorWidgetOfExactType<SymbolInteractionsSheet>())!.symbolId,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.likedUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('No likes yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          itemCount: provider.likedUsers.length + (provider.isLoadingMoreLikes ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.likedUsers.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final like = provider.likedUsers[index];
            return _UserTile(
              user: like.user,
              subtitle: timeago.format(like.createdAt),
              trailingIcon: Icons.favorite,
              trailingColor: Colors.red,
            );
          },
        );
      },
    );
  }
}

// ── Views Tab ──

class _ViewsTab extends StatelessWidget {
  final ScrollController scrollController;

  const _ViewsTab({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<SymbolInteractionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingViews) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.viewedUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => provider.loadViewedUsers(
                    (context.findAncestorWidgetOfExactType<SymbolInteractionsSheet>())!.symbolId,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (provider.viewedUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_off, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('No views yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          itemCount: provider.viewedUsers.length + (provider.isLoadingMoreViews ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.viewedUsers.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final view = provider.viewedUsers[index];
            return _UserTile(
              user: view.user,
              subtitle: timeago.format(view.seenAt),
              trailingIcon: Icons.visibility,
              trailingColor: Colors.blue,
            );
          },
        );
      },
    );
  }
}

// ── Reusable User Tile ──

class _UserTile extends StatelessWidget {
  final InteractionUser? user;
  final String subtitle;
  final IconData trailingIcon;
  final Color trailingColor;

  const _UserTile({
    required this.user,
    required this.subtitle,
    required this.trailingIcon,
    required this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const ListTile(
        leading: CircleAvatar(child: Icon(Icons.person)),
        title: Text('Unknown User'),
      );
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user!.profileImage != null
            ? NetworkImage(user!.profileImage!)
            : null,
        child: user!.profileImage == null
            ? Text(
                user!.name.isNotEmpty ? user!.name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user!.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (user!.isBusiness) ...[
            const SizedBox(width: 4),
            Icon(Icons.verified, size: 16, color: Colors.blue[600]),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      trailing: Icon(trailingIcon, color: trailingColor, size: 20),
      onTap: () {
        // Navigate to user profile
        // Navigator.pushNamed(context, '/profile', arguments: user!.id);
      },
    );
  }
}
```

### 5. How to Trigger the Sheet

```dart
// From your symbol/status viewer screen:

// When user taps on likes count
GestureDetector(
  onTap: () => SymbolInteractionsSheet.show(
    context,
    symbolId: symbol.id,
    likesCount: symbol.likesCount,
    viewsCount: symbol.seenCount,
    initialTab: 0, // opens on Likes tab
  ),
  child: Row(
    children: [
      const Icon(Icons.favorite, color: Colors.red, size: 20),
      const SizedBox(width: 4),
      Text('${symbol.likesCount}'),
    ],
  ),
),

// When user taps on views count (owner only)
GestureDetector(
  onTap: () => SymbolInteractionsSheet.show(
    context,
    symbolId: symbol.id,
    likesCount: symbol.likesCount,
    viewsCount: symbol.seenCount,
    initialTab: 1, // opens on Views tab
  ),
  child: Row(
    children: [
      const Icon(Icons.visibility, color: Colors.blue, size: 20),
      const SizedBox(width: 4),
      Text('${symbol.seenCount}'),
    ],
  ),
),
```

### 6. Provider Setup

```dart
// In your main.dart or wherever you set up providers:

MultiProvider(
  providers: [
    // ... other providers
    ChangeNotifierProvider(
      create: (_) => SymbolInteractionProvider(
        SymbolInteractionService(
          baseUrl: 'https://your-api-domain.com/api', // your symbols service URL
          getAuthToken: () => authService.token, // your auth token getter
        ),
      ),
    ),
  ],
  child: const MyApp(),
);
```

---

## API Quick Reference

| Action              | Method | Endpoint                            | Paginated | Notes                        |
|---------------------|--------|-------------------------------------|-----------|------------------------------|
| Get liked users     | GET    | `/symbols/:id/likes`                | No        | Returns flat array           |
| Get viewed users    | GET    | `/symbols/:id/views`                | No        | Returns flat array           |
| Get likes paginated | GET    | `/symbols/:id?include=likes`        | Yes       | Part of symbol detail        |
| Get views paginated | GET    | `/symbols/:id?include=seen`         | Yes       | Part of symbol detail        |
| Get both paginated  | GET    | `/symbols/:id?include=likes,seen`   | Yes       | Single call, both lists      |
| Like a symbol       | POST   | `/symbols/:id/like`                 | -         | 201 new / 200 already liked  |
| Unlike a symbol     | DELETE | `/symbols/:id/like`                 | -         | 200 success / 404 not found  |
| Mark as viewed      | POST   | `/symbols/:id/view`                 | -         | 201 new / 200 already viewed |

## Error Codes

| Code | Meaning                                             |
|------|-----------------------------------------------------|
| 200  | Success                                             |
| 201  | Created (new like/view)                             |
| 400  | Invalid symbol ID                                   |
| 403  | Not allowed (private symbol, not connected)         |
| 404  | Symbol not found / Like not found for unlike        |
| 500  | Server error                                        |

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  http: ^1.2.0
  provider: ^6.1.0
  timeago: ^3.6.0
```
