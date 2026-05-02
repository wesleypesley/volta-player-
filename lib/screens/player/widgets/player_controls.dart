import 'package:flutter/material.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: null, icon: Icon(Icons.skip_previous)),
        IconButton(onPressed: null, icon: Icon(Icons.play_arrow)),
        IconButton(onPressed: null, icon: Icon(Icons.skip_next)),
      ],
    );
  }
}
