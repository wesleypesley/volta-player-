import 'package:flutter/material.dart';

class MediaGridItem extends StatelessWidget {
  final String title;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onDelete;

  const MediaGridItem({
    super.key,
    required this.title,
    this.onAddToPlaylist,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
          ),
          if (onAddToPlaylist != null)
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                tooltip: 'Song actions',
                onSelected: (value) {
                  if (value == 'playlist') {
                    onAddToPlaylist?.call();
                  } else if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'playlist',
                    child: ListTile(
                      leading: Icon(Icons.playlist_add),
                      title: Text('Add to playlist'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Delete'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
