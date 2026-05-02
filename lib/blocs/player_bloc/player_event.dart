part of 'player_bloc.dart';

abstract class PlayerEvent {
  const PlayerEvent();
}

class Play extends PlayerEvent {
  final MediaItem? item;
  const Play([this.item]);
}

class Pause extends PlayerEvent {
  const Pause();
}

class Seek extends PlayerEvent {
  final Duration position;
  const Seek(this.position);
}

class SkipNext extends PlayerEvent {
  const SkipNext();
}

class SkipPrev extends PlayerEvent {
  const SkipPrev();
}

class SetLoop extends PlayerEvent {
  final bool enabled;
  const SetLoop(this.enabled);
}

class SetShuffle extends PlayerEvent {
  final bool enabled;
  const SetShuffle(this.enabled);
}

class SetQueue extends PlayerEvent {
  final List<MediaItem> items;
  final MediaItem? startAt;
  const SetQueue(this.items, {this.startAt});
}

class PlaybackSnapshotChanged extends PlayerEvent {
  final PlaybackSnapshot snapshot;
  const PlaybackSnapshotChanged(this.snapshot);
}
