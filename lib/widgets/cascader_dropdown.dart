import 'package:flutter/material.dart';

/// Simple tree node model for the cascader
class CascaderNode {
  final String label;
  final List<CascaderNode> children;
  const CascaderNode({required this.label, this.children = const []});
  bool get isLeaf => children.isEmpty;
}

/// A mobile-friendly multi-hierarchical dropdown that opens inline as an overlay.
/// - Tapping an option with children drills down, replacing the list in-place
/// - A Back button at the bottom returns to the previous list
/// - Tapping a leaf closes the menu and returns the selected path
class CascaderDropdown extends StatefulWidget {
  final List<CascaderNode> options;
  final String labelText;
  final ValueChanged<List<CascaderNode>> onSelected;
  final List<CascaderNode> initialSelectionPath;

  const CascaderDropdown({
    super.key,
    required this.options,
    required this.labelText,
    required this.onSelected,
    this.initialSelectionPath = const [],
  });

  @override
  State<CascaderDropdown> createState() => _CascaderDropdownState();
}

class _CascaderDropdownState extends State<CascaderDropdown> {
  List<CascaderNode> _selectedPath = [];

  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _barrierEntry;
  OverlayEntry? _menuEntry;

  @override
  void initState() {
    super.initState();
    _selectedPath = List<CascaderNode>.from(widget.initialSelectionPath);
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _menuEntry?.remove();
    _menuEntry = null;
    _barrierEntry?.remove();
    _barrierEntry = null;
  }

  Size _fieldSize() {
    final ctx = _fieldKey.currentContext;
    if (ctx == null) return const Size(300, 48);
    final box = ctx.findRenderObject() as RenderBox?;
    return box?.size ?? const Size(300, 48);
  }

  void _openOverlay() {
    if (_menuEntry != null) return;
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    // Tap-outside barrier
    _barrierEntry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _removeOverlay,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    // Menu entry with fixed dimensions
    _menuEntry = OverlayEntry(
      builder: (_) {
        return _CascaderOverlayMenu(
          link: _layerLink,
          width: _fieldSize().width,
          height: 100.0, // Fixed 100px height
          options: widget.options,
          onClose: _removeOverlay,
          onSelected: (path) {
            setState(() => _selectedPath = path);
            widget.onSelected(path);
            _removeOverlay();
          },
        );
      },
    );

    overlay.insertAll([_barrierEntry!, _menuEntry!]);
  }

  @override
  Widget build(BuildContext context) {
    final selectedText = _selectedPath.isEmpty
        ? 'Select'
        : _selectedPath.map((e) => e.label).join(' / ');

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _fieldKey,
        onTap: _openOverlay,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedText,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }
}

class _CascaderOverlayMenu extends StatefulWidget {
  final LayerLink link;
  final double width;
  final double height;
  final List<CascaderNode> options;
  final VoidCallback onClose;
  final ValueChanged<List<CascaderNode>> onSelected;

  const _CascaderOverlayMenu({
    required this.link,
    required this.width,
    required this.height,
    required this.options,
    required this.onClose,
    required this.onSelected,
  });

  @override
  State<_CascaderOverlayMenu> createState() => _CascaderOverlayMenuState();
}

class _CascaderOverlayMenuState extends State<_CascaderOverlayMenu> {
  late List<CascaderNode> _current;
  final List<List<CascaderNode>> _stack = [];
  final List<CascaderNode> _path = [];
  bool _forward = true;

  @override
  void initState() {
    super.initState();
    _current = widget.options;
  }

  void _onTap(CascaderNode node) {
    if (node.isLeaf) {
      _path.add(node);
      widget.onSelected(List<CascaderNode>.from(_path));
      return;
    }
    _stack.add(_current);
    _path.add(node);
    setState(() {
      _forward = true;
      _current = node.children;
    });
  }

  void _onBack() {
    if (_stack.isNotEmpty) {
      setState(() {
        _current = _stack.removeLast();
        if (_path.isNotEmpty) _path.removeLast();
        _forward = false;
      });
    } else {
      widget.onClose();
    }
  }

  Widget _buildLevelList(List<CascaderNode> level) {
    return ListView.separated(
      key: ValueKey(level.hashCode ^ _stack.length),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      itemCount: level.length,
      physics: const AlwaysScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final node = level[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => _onTap(node),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      node.label,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (!node.isLeaf)
                    const Icon(Icons.chevron_right, color: Colors.black45, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _path.isEmpty
        ? 'Select'
        : _path.map((e) => e.label).join(' / ');

    return CompositedTransformFollower(
      link: widget.link,
      showWhenUnlinked: false,
      offset: const Offset(0, 4),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.hardEdge,
        child: Container(
          width: widget.width,
          height: widget.height,
          constraints: BoxConstraints.tight(Size(widget.width, widget.height)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compact Header (28px)
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 14,
                        tooltip: 'Close',
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List area (43px remaining after header, divider, back button)
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    final begin = _forward ? const Offset(1, 0) : const Offset(-1, 0);
                    final tween = Tween<Offset>(begin: begin, end: Offset.zero)
                        .chain(CurveTween(curve: Curves.easeOutCubic));
                    return ClipRect(
                      child: SlideTransition(position: animation.drive(tween), child: child),
                    );
                  },
                  child: _buildLevelList(_current),
                ),
              ),
              // Compact Back button (28px)
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: SizedBox(
                  width: double.infinity,
                  height: 24,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 24),
                    ),
                    onPressed: _onBack,
                    child: Text(
                      _stack.isEmpty ? 'Close' : 'Back',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
