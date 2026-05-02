part of 'player_bloc.dart';

class PlayerState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final MediaItem? currentItem;
  final List<MediaItem> queue;
  final bool shuffle;
  final bool loop;

  const PlayerState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.currentItem,
    this.queue = const [],
    this.shuffle = false,
    this.loop = false,
  });

  PlayerState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    MediaItem? currentItem,
    List<MediaItem>? queue,
    bool? shuffle,
    bool? loop,
  }) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      currentItem: currentItem ?? this.currentItem,
      queue: queue ?? this.queue,
      shuffle: shuffle ?? this.shuffle,
      loop: loop ?? this.loop,
    );
  }
}
