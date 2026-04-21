import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// Single to-do entry persisted in Hive.
class TodoItem {
  TodoItem({
    required this.id,
    required this.title,
    required this.notes,
    required this.dueAt,
    required this.createdAt,
    this.isCompleted = false,
    this.completedAt,
  });

  final String id;
  String title;
  String notes;
  DateTime dueAt;
  final DateTime createdAt;
  bool isCompleted;
  DateTime? completedAt;

  TodoItem copyWith({
    String? title,
    String? notes,
    DateTime? dueAt,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueAt: dueAt ?? this.dueAt,
      createdAt: createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'dueAt': dueAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
        dueAt: DateTime.tryParse(json['dueAt']?.toString() ?? '') ??
            DateTime.now(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        isCompleted: json['isCompleted'] == true,
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.tryParse(json['completedAt'].toString()),
      );
}

/// Bucket used for sectioning the list view.
enum TodoBucket { overdue, today, tomorrow, upcoming, completed }

/// Controller for the "To Do List" tab. Persists to a Hive box so entries
/// survive app restarts and are available offline.
class TodoController extends GetxController {
  static const String _boxName = 'todoBox';
  static const String _itemsKey = 'items';

  final RxList<TodoItem> todos = <TodoItem>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<Box<String>> get _boxRef async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box<String>(_boxName);
    return await Hive.openBox<String>(_boxName);
  }

  Future<void> _load() async {
    try {
      final box = await _boxRef;
      final raw = box.get(_itemsKey);
      if (raw == null || raw.isEmpty) {
        todos.clear();
        return;
      }
      final List decoded = jsonDecode(raw) as List;
      final parsed = decoded
          .whereType<Map>()
          .map((m) => TodoItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      todos.assignAll(parsed);
    } catch (e) {
      debugPrint('[TodoController] load failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _persist() async {
    try {
      final box = await _boxRef;
      final serialized =
          jsonEncode(todos.map((t) => t.toJson()).toList(growable: false));
      await box.put(_itemsKey, serialized);
    } catch (e) {
      debugPrint('[TodoController] persist failed: $e');
    }
  }

  Future<TodoItem> addTodo({
    required String title,
    required String notes,
    required DateTime dueAt,
  }) async {
    final item = TodoItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      notes: notes.trim(),
      dueAt: dueAt,
      createdAt: DateTime.now(),
    );
    todos.add(item);
    await _persist();
    return item;
  }

  Future<void> updateTodo(
    String id, {
    String? title,
    String? notes,
    DateTime? dueAt,
  }) async {
    final idx = todos.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    todos[idx] = todos[idx].copyWith(
      title: title?.trim() ?? todos[idx].title,
      notes: notes?.trim() ?? todos[idx].notes,
      dueAt: dueAt ?? todos[idx].dueAt,
    );
    todos.refresh();
    await _persist();
  }

  Future<void> toggleComplete(String id) async {
    final idx = todos.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final current = todos[idx];
    todos[idx] = current.copyWith(
      isCompleted: !current.isCompleted,
      completedAt: current.isCompleted ? null : DateTime.now(),
    );
    todos.refresh();
    await _persist();
  }

  Future<void> deleteTodo(String id) async {
    todos.removeWhere((t) => t.id == id);
    await _persist();
  }

  /// Oldest-due-first ordering for pending items; completed items sink to
  /// the bottom, ordered by most-recently-completed.
  List<TodoItem> get sorted {
    final pending =
        todos.where((t) => !t.isCompleted).toList(growable: false)
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    final done = todos.where((t) => t.isCompleted).toList(growable: false)
      ..sort((a, b) {
        final ac = a.completedAt ?? a.createdAt;
        final bc = b.completedAt ?? b.createdAt;
        return bc.compareTo(ac);
      });
    return [...pending, ...done];
  }

  TodoBucket bucketOf(TodoItem item, {DateTime? now}) {
    if (item.isCompleted) return TodoBucket.completed;
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfter = tomorrow.add(const Duration(days: 1));
    final due = DateTime(item.dueAt.year, item.dueAt.month, item.dueAt.day);
    if (item.dueAt.isBefore(ref) && due.isBefore(today)) {
      return TodoBucket.overdue;
    }
    if (due == today) {
      if (item.dueAt.isBefore(ref)) return TodoBucket.overdue;
      return TodoBucket.today;
    }
    if (due == tomorrow) return TodoBucket.tomorrow;
    if (due.isBefore(dayAfter)) return TodoBucket.today;
    return TodoBucket.upcoming;
  }

  /// Returns items grouped by bucket, preserving the [sorted] ordering
  /// inside each group. Callers iterate in the enum declaration order to
  /// render sections top-to-bottom.
  Map<TodoBucket, List<TodoItem>> groupedByBucket() {
    final out = <TodoBucket, List<TodoItem>>{
      for (final b in TodoBucket.values) b: <TodoItem>[],
    };
    for (final t in sorted) {
      out[bucketOf(t)]!.add(t);
    }
    return out;
  }
}
