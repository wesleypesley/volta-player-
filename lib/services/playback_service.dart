import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' as media_kit;

import '../models/media_item.dart';

class PlaybackSnapshot {
  final List<MediaItem> queue;
  final MediaItem? currentItem;
  final bool isPlaying;
  final bool shuffle;
  final bool loop;
  final Duration position;
  final Duration duration;

  const PlaybackSnapshot({
    required this.queue,
    required this.currentItem,
    required this.isPlaying,
    required this.shuffle,
    required this.loop,
    required this.position,
    required this.duration,
  });
}

class PlaybackService {
  static final PlaybackService instance = PlaybackService._init();
  PlaybackService._init() {
    _subscriptions.addAll([
      _player.stream.playlist.listen((playlist) {
        if (playlist.index >= 0 && playlist.index < _queue.length) {
          _currentItem = _queue[playlist.index];
          _duration = _currentItem?.duration ?? _duration;
          _emitSnapshot();
        }
      }),
      _player.stream.playing.listen((value) {
        _isPlaying = value;
        _emitSnapshot();
      }),
      _player.stream.position.listen((value) {
        _position = value;
        _emitSnapshot();
      }),
      _player.stream.duration.listen((value) {
        _duration = value;
        _emitSnapshot();
      }),
      _player.stream.completed.listen((completed) {
        if (completed && !_loop) {
          _isPlaying = false;
          _emitSnapshot();
        }
      }),
      _player.stream.error.listen((error) {
        debugPrint('Playback error: $error');
        _isPlaying = false;
        _emitSnapshot();
      }),
    ]);
  }

  final media_kit.Player _player = media_kit.Player();
  final StreamController<PlaybackSnapshot> _snapshots =
      StreamController<PlaybackSnapshot>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<MediaItem> _queue = [];
  MediaItem? _currentItem;
  bool _isPlaying = false;
  bool _shuffle = false;
  bool _loop = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  List<MediaItem> get queue => List.unmodifiable(_queue);
  MediaItem? get currentItem => _currentItem;
  bool get isPlaying => _isPlaying;
  bool get shuffle => _shuffle;
  bool get loop => _loop;
  Duration get position => _position;
  Duration get duration => _duration;
  Stream<PlaybackSnapshot> get snapshots => _snapshots.stream;

  PlaybackSnapshot get snapshot => PlaybackSnapshot(
        queue: queue,
        currentItem: _currentItem,
        isPlaying: _isPlaying,
        shuffle: _shuffle,
        loop: _loop,
        position: _position,
        duration: _duration,
      );

  void _emitSnapshot() {
    if (!_snapshots.isClosed) {
      _snapshots.add(snapshot);
    }
  }

  media_kit.Media _toMedia(MediaItem item) => media_kit.Media(item.filePath);

  void setQueue(List<MediaItem> items, {MediaItem? startAt}) {
    _queue
      ..clear()
      ..addAll(items);
    _currentItem = startAt ?? (items.isEmpty ? null : items.first);
    _position = Duration.zero;
    _duration = _currentItem?.duration ?? Duration.zero;
    _emitSnapshot();
  }

  Future<void> play([MediaItem? item]) async {
    if (item != null) {
      if (!_queue.any((queued) => queued.id == item.id)) _queue.add(item);
      _currentItem = item;
      _position = Duration.zero;
      _duration = item.duration;

      final startIndex = _queue.indexWhere((queued) => queued.id == item.id);
      final playlist = media_kit.Playlist(
        _queue.map(_toMedia).toList(),
        index: startIndex < 0 ? 0 : startIndex,
      );
      await _player.open(playlist, play: true);
    } else if (_currentItem != null) {
      await _player.play();
    }
    _isPlaying = _currentItem != null;
    _emitSnapshot();
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    _emitSnapshot();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _position = position;
    _emitSnapshot();
  }

  Future<void> skipNext() async {
    if (_queue.isEmpty || _currentItem == null) return;
    final index = _queue.indexWhere((item) => item.id == _currentItem!.id);
    _currentItem = _queue[(index + 1) % _queue.length];
    _position = Duration.zero;
    _duration = _currentItem?.duration ?? Duration.zero;
    await _player.next();
    _emitSnapshot();
  }

  Future<void> skipPrevious() async {
    if (_queue.isEmpty || _currentItem == null) return;
    final index = _queue.indexWhere((item) => item.id == _currentItem!.id);
    _currentItem = _queue[(index - 1 + _queue.length) % _queue.length];
    _position = Duration.zero;
    _duration = _currentItem?.duration ?? Duration.zero;
    await _player.previous();
    _emitSnapshot();
  }

  Future<void> setShuffle(bool enabled) async {
    _shuffle = enabled;
    await _player.setShuffle(enabled);
    _emitSnapshot();
  }

  Future<void> setLoop(bool enabled) async {
    _loop = enabled;
    await _player.setPlaylistMode(
      enabled ? media_kit.PlaylistMode.loop : media_kit.PlaylistMode.none,
    );
    _emitSnapshot();
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _snapshots.close();
    await _player.dispose();
  }
}
