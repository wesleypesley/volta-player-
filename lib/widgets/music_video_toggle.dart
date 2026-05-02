import 'package:flutter/material.dart';

import '../core/constants/colors.dart';

enum MusicVideoSelection { music, video }

class MusicVideoToggle extends StatelessWidget {
  final MusicVideoSelection value;
  final ValueChanged<MusicVideoSelection> onChanged;

  const MusicVideoToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 36,
      child: SegmentedButton<MusicVideoSelection>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: MusicVideoSelection.music, label: Text('Music')),
          ButtonSegment(value: MusicVideoSelection.video, label: Text('Video')),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.accentSoft;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.accent;
            return AppColors.textSecondary;
          }),
        ),
      ),
    );
  }
}
