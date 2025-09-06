import 'package:flutter/material.dart';

/// Tree node for hierarchical data
class HierarchicalNode {
  final String label;
  final List<HierarchicalNode> children;
  const HierarchicalNode({required this.label, this.children = const []});
  bool get isLeaf => children.isEmpty;
}

/// A dropdown that looks and behaves like a standard dropdown but supports hierarchical navigation
class HierarchicalDropdown extends StatefulWidget {
  final List<HierarchicalNode> options;
  // final String labelText;
  final String hintText;
  final ValueChanged<List<HierarchicalNode>> onSelected;
  final List<HierarchicalNode> initialPath;

  const HierarchicalDropdown({
    super.key,
    required this.options,
    // required this.labelText,
    this.hintText = 'Select',
    required this.onSelected,
    this.initialPath = const [],
  });

  @override
  State<HierarchicalDropdown> createState() => _HierarchicalDropdownState();
}

class _HierarchicalDropdownState extends State<HierarchicalDropdown> {
  List<HierarchicalNode> _selectedPath = [];
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedPath = List<HierarchicalNode>.from(widget.initialPath);
  }

  void _toggleDropdown() {
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  void _closeDropdown() {
    setState(() {
      _isOpen = false;
    });
  }

  void _onNodeSelected(List<HierarchicalNode> path) {
    setState(() {
      _selectedPath = path;
      _isOpen = false;
    });
    widget.onSelected(path);
  }

  @override
  Widget build(BuildContext context) {
    final selectedText = _selectedPath.isEmpty
        ? widget.hintText
        : _selectedPath.map((e) => e.label).join(' / ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown button
        GestureDetector(
          onTap: _toggleDropdown,
          child: InputDecorator(
            decoration: InputDecoration(
              // labelText: widget.labelText,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _selectedPath.isEmpty ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                ),
                Icon(
                  _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        // Dropdown menu
        if (_isOpen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: _HierarchicalMenu(
              options: widget.options,
              onSelected: _onNodeSelected,
              onClose: _closeDropdown,
            ),
          ),
      ],
    );
  }
}

class _HierarchicalMenu extends StatefulWidget {
  final List<HierarchicalNode> options;
  final ValueChanged<List<HierarchicalNode>> onSelected;
  final VoidCallback onClose;

  const _HierarchicalMenu({
    required this.options,
    required this.onSelected,
    required this.onClose,
  });

  @override
  State<_HierarchicalMenu> createState() => _HierarchicalMenuState();
}

class _HierarchicalMenuState extends State<_HierarchicalMenu> {
  late List<HierarchicalNode> _currentLevel;
  final List<List<HierarchicalNode>> _navigationStack = [];
  final List<HierarchicalNode> _pathStack = [];

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.options;
  }

  void _navigateToChildren(HierarchicalNode node) {
    if (node.isLeaf) {
      // Leaf node selected
      final fullPath = [..._pathStack, node];
      widget.onSelected(fullPath);
      return;
    }

    // Navigate to children
    setState(() {
      _navigationStack.add(_currentLevel);
      _pathStack.add(node);
      _currentLevel = node.children;
    });
  }

  void _navigateBack() {
    if (_navigationStack.isNotEmpty) {
      setState(() {
        _currentLevel = _navigationStack.removeLast();
        if (_pathStack.isNotEmpty) _pathStack.removeLast();
      });
    } else {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Options list
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _currentLevel.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final node = _currentLevel[index];
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                title: Text(
                  node.label,
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: node.isLeaf 
                    ? null 
                    : Icon(Icons.chevron_right, size: 22, color: Colors.grey[600]),
                onTap: () => _navigateToChildren(node),
                hoverColor: Colors.grey[100],
              );
            },
          ),
        ),
     // Header with breadcrumb and close
     if (_pathStack.isNotEmpty || _navigationStack.isNotEmpty)
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_navigationStack.isNotEmpty)
          Expanded( // 👈 this makes Back button stretch properly
            child: GestureDetector(
              onTap: _navigateBack,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.blue, // Border color
                    width: 1.4,         // Border width
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Back',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  ),

        // if (_pathStack.isNotEmpty || _navigationStack.isNotEmpty)
        //   Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        //     decoration: BoxDecoration(
        //       color: Colors.white,
        //       border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        //     ),
        //     child: Row( 
        //       mainAxisSize: MainAxisSize.max,
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       crossAxisAlignment: CrossAxisAlignment.center,
        //       children: [
        //         if (_navigationStack.isNotEmpty)
        //           GestureDetector(
        //             onTap: _navigateBack,
        //             child: ConstrainedBox(constraints: BoxConstraints(minWidth: 100), child:
        //              Container(
        //                width: double.infinity,
        //            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        //               decoration: BoxDecoration(
        //                 color: Colors.white,
        //                 border: Border.all(
        //                   color: Colors.blue,   // Border color
        //                   width: 1.4,           // Border width
        //                 ),
        //                 borderRadius: BorderRadius.circular(12),
        //               ),
        //               child: Center(
        //                 child: Text(
        //                       'Back',
        //                       style: TextStyle(fontSize: 14, color: Colors.blue),
        //                     ),
        //               ),
        //               // child: Row(
        //               //   mainAxisSize: MainAxisSize.min,
        //               //   children: [
        //               //     Icon(Icons.arrow_back, size: 14, color: Colors.blue[700]),
        //               //     const SizedBox(width: 4),
        //               //     Text(
        //               //       'Back',
        //               //       style: TextStyle(fontSize: 12, color: Colors.blue),
        //               //     ),
        //               //   ],
        //               // ),
        //             ),
                 
        //          )
        //           ),
                
        //         // const SizedBox(width: 8),
        //         // Expanded(
        //         //   child: Text(
        //         //     _pathStack.isEmpty ? 'Select' : _pathStack.map((e) => e.label).join(' / '),
        //         //     style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        //         //     overflow: TextOverflow.ellipsis,
        //         //   ),
        //         // ),
        //         // GestureDetector(
        //         //   onTap: widget.onClose,
        //         //   child: Icon(Icons.close, size: 16, color: Colors.grey[600]),
        //         // ),
        //       ],
        //     ),
        //   ),
        
      ],
    );
  }
}
