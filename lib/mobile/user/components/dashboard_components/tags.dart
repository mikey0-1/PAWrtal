// tags.dart - Complete replacement with proper initialization
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class MyTags extends StatefulWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final int Function(String) getFilterCount;

  const MyTags({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.getFilterCount,
  });

  @override
  State<MyTags> createState() => _MyTagsState();
}

class _MyTagsState extends State<MyTags> {
  final List<String> tags = [
    "All",
    "Open",
    "Closed",
    "Popular",
  ];

  final _scrollController = ScrollController();
  var _dragStartX = 0.0;
  var _dragStartScrollOffset = 0.0;
  var _isDragging = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_scrollController.hasClients) {
      _isDragging = true;
      _dragStartX = event.position.dx;
      _dragStartScrollOffset = _scrollController.offset;
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isDragging || !_scrollController.hasClients) return;

    try {
      if (_scrollController.position.hasContentDimensions) {
        final delta = _dragStartX - event.position.dx;
        final newOffset = _dragStartScrollOffset + delta;
        final maxScroll = _scrollController.position.maxScrollExtent;

        _scrollController.jumpTo(
          newOffset.clamp(0.0, maxScroll),
        );
      }
    } catch (e) {
      // Ignore scroll errors during initialization
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _isDragging = false;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _isDragging = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        child: MouseRegion(
          cursor: _isDragging
              ? SystemMouseCursors.grabbing
              : SystemMouseCursors.grab,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
              scrollbars: false,
            ),
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              itemCount: tags.length,
              itemBuilder: (context, index) {
                final tag = tags[index];
                final isSelected = widget.selectedFilter == tag;
                final count = widget.getFilterCount(tag);

                return Padding(
                  padding: const EdgeInsets.only(left: 10, right: 5),
                  child: ChoiceChip(
                    checkmarkColor: Colors.white,
                    elevation: 3,
                    selectedColor: const Color.fromARGB(255, 81, 115, 153),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? const Color.fromARGB(255, 81, 115, 153)
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    label: Text(
                      count > 0 && tag != 'All' ? '$tag ($count)' : tag,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      if (selected) {
                        widget.onFilterChanged(tag);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
