import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AiwaWheelPicker<T> extends StatelessWidget {
  final int initialItem;
  final ValueChanged<int> onSelectedItemChanged;
  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final double itemExtent;
  final double height;
  final Color? highlightColor;

  const AiwaWheelPicker({
    super.key,
    required this.initialItem,
    required this.onSelectedItemChanged,
    required this.items,
    required this.itemBuilder,
    this.itemExtent = 40,
    this.height = 200, // Optional height constraint if needed, but usually expanded
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Highlight Container
        Container(
          height: itemExtent,
          decoration: BoxDecoration(
            color: highlightColor ?? Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        
        // Picker
        CupertinoPicker(
          selectionOverlay: const SizedBox(), // Hide default overlay
          scrollController: FixedExtentScrollController(
            initialItem: initialItem,
          ),
          itemExtent: itemExtent,
          onSelectedItemChanged: onSelectedItemChanged,
          children: items.map((item) {
            return Center(
              child: itemBuilder(item),
            );
          }).toList(),
        ),
      ],
    );
  }
}
