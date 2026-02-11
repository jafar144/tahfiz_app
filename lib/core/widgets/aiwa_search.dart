import 'package:flutter/material.dart';

class AiwaSearch extends StatelessWidget {
  final TextEditingController controller;
  final Function(String)? onSubmitted;
  final VoidCallback? onSearch;
  final String hintText;

  const AiwaSearch({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onSearch,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.grey,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.blue,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: 'Search',
          ),
        ),
      ],
    );
  }
}