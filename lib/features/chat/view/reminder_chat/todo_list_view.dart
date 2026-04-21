import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/todo_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// "To Do List" tab body — grouped, checkable list with inline add/edit.
class TodoListView extends StatelessWidget {
  const TodoListView({super.key});

  TodoController get _controller => getOrPut(() => TodoController());

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: AppColors.fillColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: SizedBox(
              height: 26,
              width: 26,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          );
        }

        if (controller.todos.isEmpty) {
          return const _TodoEmptyStateBody();
        }

        final groups = controller.groupedByBucket();

        // Build a flat list of section headers + item tiles so we can hand it
        // to a single ListView and keep everything scrollable as one unit.
        final children = <Widget>[];
        for (final bucket in TodoBucket.values) {
          final items = groups[bucket] ?? const <TodoItem>[];
          if (items.isEmpty) continue;
          children.add(_SectionHeader(bucket: bucket, count: items.length));
          for (final item in items) {
            children.add(_TodoTile(
              item: item,
              onToggle: () => controller.toggleComplete(item.id),
              onTap: () => _showEditor(context, existing: item),
              onDelete: () => _confirmDelete(context, item),
            ));
          }
        }

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 96),
          children: children,
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const CustomText(
          'New task',
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, TodoItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const CustomText('Delete task?', fontWeight: FontWeight.w700),
        content: CustomText(
          'This will permanently remove "${item.title}".',
          color: Colors.black87,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const CustomText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const CustomText('Delete', color: Colors.white),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _controller.deleteTodo(item.id);
    }
  }

  Future<void> _showEditor(BuildContext context, {TodoItem? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TodoEditorSheet(existing: existing),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────

class _TodoEmptyStateBody extends StatelessWidget {
  const _TodoEmptyStateBody();

  @override
  Widget build(BuildContext context) {
    // Reuse the illustration already defined in reminder_todo_screen.dart —
    // this keeps the look consistent with the Reminder tab.
    return const Center(child: _TodoEmptyHero());
  }
}

class _TodoEmptyHero extends StatelessWidget {
  const _TodoEmptyHero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withValues(alpha: 0.10),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 58,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const CustomText(
            'No tasks yet',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),
          const CustomText(
            'Tap the “New task” button to add a reminder for any day and time.',
            fontSize: 13,
            textAlign: TextAlign.center,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.bucket, required this.count});

  final TodoBucket bucket;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = _bucketTheme(bucket);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 18,
            decoration: BoxDecoration(
              color: theme.accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          CustomText(
            theme.label,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomText(
              '$count',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: theme.accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────

class _TodoTile extends StatelessWidget {
  const _TodoTile({
    required this.item,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  final TodoItem item;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TodoController>();
    final bucket = controller.bucketOf(item);
    final theme = _bucketTheme(bucket);
    final isDone = item.isCompleted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDone
                    ? const Color(0xFFE5E7EB)
                    : theme.accent.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CheckCircle(isDone: isDone, accent: theme.accent, onTap: onToggle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        item.title.isEmpty ? '(Untitled)' : item.title,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDone ? Colors.black38 : Colors.black87,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        decoration:
                            isDone ? TextDecoration.lineThrough : null,
                      ),
                      if (item.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        CustomText(
                          item.notes,
                          fontSize: 12.5,
                          color:
                              isDone ? Colors.black38 : Colors.black54,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _DueChip(
                        dueAt: item.dueAt,
                        accent: theme.accent,
                        muted: isDone,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  splashRadius: 20,
                  icon: const Icon(Icons.more_vert, color: Colors.black45),
                  onPressed: () => _openItemMenu(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openItemMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const CustomText('Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  onTap();
                },
              ),
              ListTile(
                leading: Icon(
                  item.isCompleted
                      ? Icons.radio_button_unchecked_rounded
                      : Icons.check_circle_outline_rounded,
                ),
                title: CustomText(
                  item.isCompleted ? 'Mark as pending' : 'Mark as done',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onToggle();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const CustomText('Delete', color: Colors.red),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({
    required this.isDone,
    required this.accent,
    required this.onTap,
  });

  final bool isDone;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone ? accent : Colors.transparent,
          border: Border.all(
            color: isDone ? accent : accent.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        child: isDone
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _DueChip extends StatelessWidget {
  const _DueChip({
    required this.dueAt,
    required this.accent,
    required this.muted,
  });

  final DateTime dueAt;
  final Color accent;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? Colors.black38 : accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          CustomText(
            _formatDue(dueAt),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ],
      ),
    );
  }
}

String _formatDue(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  final timePart = DateFormat.jm().format(dt); // e.g. 3:00 PM
  if (day == today) return 'Today · $timePart';
  if (day == today.add(const Duration(days: 1))) {
    return 'Tomorrow · $timePart';
  }
  if (day == today.subtract(const Duration(days: 1))) {
    return 'Yesterday · $timePart';
  }
  final sameYear = dt.year == now.year;
  final datePart =
      sameYear ? DateFormat('EEE, MMM d').format(dt) : DateFormat.yMMMd().format(dt);
  return '$datePart · $timePart';
}

// ─── Section theming ──────────────────────────────────────────────────────

class _BucketTheme {
  const _BucketTheme(this.label, this.accent);
  final String label;
  final Color accent;
}

_BucketTheme _bucketTheme(TodoBucket bucket) {
  switch (bucket) {
    case TodoBucket.overdue:
      return const _BucketTheme('Overdue', Color(0xFFE53935));
    case TodoBucket.today:
      return const _BucketTheme('Today', AppColors.primaryColor);
    case TodoBucket.tomorrow:
      return const _BucketTheme('Tomorrow', Color(0xFFF59E0B));
    case TodoBucket.upcoming:
      return const _BucketTheme('Upcoming', Color(0xFF8B5CF6));
    case TodoBucket.completed:
      return const _BucketTheme('Completed', Color(0xFF16A34A));
  }
}

// ─── Editor sheet ─────────────────────────────────────────────────────────

class TodoEditorSheet extends StatefulWidget {
  const TodoEditorSheet({super.key, this.existing});

  final TodoItem? existing;

  @override
  State<TodoEditorSheet> createState() => _TodoEditorSheetState();
}

class _TodoEditorSheetState extends State<TodoEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _dueAt;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleCtrl = TextEditingController(text: existing?.title ?? '');
    _notesCtrl = TextEditingController(text: existing?.notes ?? '');
    _dueAt = existing?.dueAt ?? _defaultInitialDue();
  }

  DateTime _defaultInitialDue() {
    // Default to the next quarter-hour so the picker lands on a sensible slot.
    final now = DateTime.now();
    final rounded = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      ((now.minute ~/ 15) + 1) * 15,
    );
    // If rounding overflowed an hour, DateTime handles it correctly.
    return rounded;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueAt.isBefore(now) ? now : _dueAt,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.primaryColor,
              ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _dueAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dueAt.hour,
        _dueAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.primaryColor,
              ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _dueAt = DateTime(
        _dueAt.year,
        _dueAt.month,
        _dueAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_submitting) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final controller = Get.find<TodoController>();
    if (widget.existing != null) {
      await controller.updateTodo(
        widget.existing!.id,
        title: title,
        notes: _notesCtrl.text,
        dueAt: _dueAt,
      );
    } else {
      await controller.addTodo(
        title: title,
        notes: _notesCtrl.text,
        dueAt: _dueAt,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                CustomText(
                  isEditing ? 'Edit task' : 'New task',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Title',
                    filled: true,
                    fillColor: const Color(0xFFF6F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Notes (optional)',
                    filled: true,
                    fillColor: const Color(0xFFF6F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _PickerChip(
                        icon: Icons.calendar_today_rounded,
                        label: DateFormat('EEE, MMM d, y').format(_dueAt),
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PickerChip(
                        icon: Icons.schedule_rounded,
                        label: DateFormat.jm().format(_dueAt),
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const CustomText('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : CustomText(
                                isEditing ? 'Save' : 'Add task',
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerChip extends StatelessWidget {
  const _PickerChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: CustomText(
                label,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
