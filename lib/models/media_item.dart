enum MediaType { audio, video }

class MediaItem {
  final String id;
  final String title;
  final String? artist;
  final MediaType type;
  final String filePath;
  final Duration duration;
  final String? thumbnailPath;
  final DateTime addedAt;
  final int fileSizeBytes;
  final String? sourceUrl;

  const MediaItem({
    required this.id,
    required this.title,
    this.artist,
    required this.type,
    required this.filePath,
    required this.duration,
    this.thumbnailPath,
    required this.addedAt,
    required this.fileSizeBytes,
    this.sourceUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'type': type.name,
      'file_path': filePath,
      'duration_ms': duration.inMilliseconds,
      'thumbnail_path': thumbnailPath,
      'added_at': addedAt.millisecondsSinceEpoch,
      'file_size_bytes': fileSizeBytes,
      'source_url': sourceUrl,
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String?,
      type: MediaType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => MediaType.audio,
      ),
      filePath: map['file_path'] as String,
      duration: Duration(milliseconds: map['duration_ms'] as int? ?? 0),
      thumbnailPath: map['thumbnail_path'] as String?,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
      fileSizeBytes: map['file_size_bytes'] as int? ?? 0,
      sourceUrl: map['source_url'] as String?,
    );
  }
}
