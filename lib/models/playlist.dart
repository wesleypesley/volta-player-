class Playlist {
  final String id;
  final String name;
  final List<String> mediaItemIds;
  final DateTime createdAt;
  final bool isSmart;

  const Playlist({
    required this.id,
    required this.name,
    this.mediaItemIds = const [],
    required this.createdAt,
    this.isSmart = false,
  });

  factory Playlist.fromMap(
      Map<String, dynamic> map, List<String> mediaItemIds) {
    return Playlist(
      id: map['id'] as String,
      name: map['name'] as String,
      mediaItemIds: mediaItemIds,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      isSmart: (map['is_smart'] as int? ?? 0) == 1,
    );
  }

  Playlist copyWith({
    String? id,
    String? name,
    List<String>? mediaItemIds,
    DateTime? createdAt,
    bool? isSmart,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      mediaItemIds: mediaItemIds ?? this.mediaItemIds,
      createdAt: createdAt ?? this.createdAt,
      isSmart: isSmart ?? this.isSmart,
    );
  }
}
