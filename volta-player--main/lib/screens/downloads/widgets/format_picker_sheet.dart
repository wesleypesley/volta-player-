import 'package:flutter/material.dart';

import '../../../models/download_task.dart';

class FormatPickerSheet extends StatelessWidget {
  final ValueChanged<DownloadFormat> onSelected;

  const FormatPickerSheet({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.audiotrack),
            title: const Text('Audio MP3'),
            onTap: () => onSelected(DownloadFormat.audioOnly),
          ),
          ListTile(
            leading: const Icon(Icons.video_library),
            title: const Text('Video MP4'),
            onTap: () => onSelected(DownloadFormat.videoMp4),
          ),
          ListTile(
            leading: const Icon(Icons.high_quality),
            title: const Text('Best Quality'),
            onTap: () => onSelected(DownloadFormat.best),
          ),
        ],
      ),
    );
  }
}
