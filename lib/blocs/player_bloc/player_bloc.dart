import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/media_item.dart';
import '../../services/playback_service.dart';
part 'player_event.dart';
part 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  StreamSubscription<PlaybackSnapshot>? _playbackSubscription;

  PlayerBloc() : super(const PlayerState()) {
    on<Play>(_onPlay);
    on<Pause>(_onPause);
    on<Seek>(_onSeek);
    on<SkipNext>(_onSkipNext);
    on<SkipPrev>(_onSkipPrev);
    on<SetLoop>(_onSetLoop);
    on<SetShuffle>(_onSetShuffle);
    on<SetQueue>(_onSetQueue);
    on<PlaybackSnapshotChanged>(_onPlaybackSnapshotChanged);

    _playbackSubscription = PlaybackService.instance.snapshots.listen(
      (snapshot) => add(PlaybackSnapshotChanged(snapshot)),
    );
  }

  void _emitFromService(Emitter<PlayerState> emit) {
    final service = PlaybackService.instance;
    _emitSnapshot(emit, service.snapshot);
  }

  void _emitSnapshot(Emitter<PlayerState> emit, PlaybackSnapshot snapshot) {
    emit(
      state.copyWith(
        isPlaying: snapshot.isPlaying,
        position: snapshot.position,
        duration: snapshot.duration,
        currentItem: snapshot.currentItem,
        queue: snapshot.queue,
        shuffle: snapshot.shuffle,
        loop: snapshot.loop,
      ),
    );
  }

  Future<void> _onPlay(Play event, Emitter<PlayerState> emit) async {
    await PlaybackService.instance.play(event.item);
    _emitFromService(emit);
  }

  Future<void> _onPause(Pause event, Emitter<PlayerState> emit) async {
    await PlaybackService.instance.pause();
    _emitFromService(emit);
  }

  Future<void> _onSeek(Seek event, Emitter<PlayerState> emit) async {
    await PlaybackService.instance.seek(event.position);
    _emitFromService(emit);
  }

  Future<void> _onSkipNext(SkipNext event, Emitter<PlayerState> emit) async {
    await PlaybackService.instance.skipNext();
    _emitFromService(emit);
  }

  Future<void> _onSkipPrev(SkipPrev event, Emitter<PlayerState> emit) async {
    await PlaybackService.instance.skipPrevious();
    _emitFromService(emit);
  }

  Future<void> _onSetLoop(SetLoop event, Emitter<PlayerState> emit) async {
    await PlaybackService.instance.setLoop(event.enabled);
    _emitFromService(emit);
  }

  Future<void> _onSetShuffle(
      SetShuffle event, Emitter<PlayerState> emit) async {
    await PlaybackService.instance.setShuffle(event.enabled);
    _emitFromService(emit);
  }

  void _onSetQueue(SetQueue event, Emitter<PlayerState> emit) {
    PlaybackService.instance.setQueue(event.items, startAt: event.startAt);
    _emitFromService(emit);
  }

  void _onPlaybackSnapshotChanged(
    PlaybackSnapshotChanged event,
    Emitter<PlayerState> emit,
  ) {
    _emitSnapshot(emit, event.snapshot);
  }

  @override
  Future<void> close() async {
    await _playbackSubscription?.cancel();
    return super.close();
  }
}
