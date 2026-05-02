import 'package:flutter/material.dart';

class SeekBar extends StatelessWidget {
  final double value;
  final double bufferedValue;
  final ValueChanged<double>? onChanged;

  const SeekBar({
    super.key,
    required this.value,
    required this.bufferedValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        secondaryActiveTrackColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Slider(
        value: value.clamp(0, 1),
        secondaryTrackValue: bufferedValue.clamp(0, 1),
        onChanged: onChanged,
      ),
    );
  }
}
