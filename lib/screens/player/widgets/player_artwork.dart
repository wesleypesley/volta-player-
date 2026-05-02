import 'package:flutter/material.dart';

import '../../../core/widgets/artwork_card.dart';

class PlayerArtwork extends StatelessWidget {
  const PlayerArtwork({super.key});

  @override
  Widget build(BuildContext context) {
    return const ArtworkCard(
      child: AspectRatio(
        aspectRatio: 1,
        child: ColoredBox(
          color: Colors.black12,
          child: Center(child: Icon(Icons.music_note, size: 64)),
        ),
      ),
    );
  }
}
