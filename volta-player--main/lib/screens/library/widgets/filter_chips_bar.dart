import 'package:flutter/material.dart';

class FilterChipsBar extends StatelessWidget {
  const FilterChipsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      children: [
        FilterChip(label: Text('All'), onSelected: null),
        FilterChip(label: Text('Audio'), onSelected: null),
        FilterChip(label: Text('Video'), onSelected: null),
        FilterChip(label: Text('Recent'), onSelected: null),
      ],
    );
  }
}
