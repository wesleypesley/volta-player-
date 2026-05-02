import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/player_bloc/player_bloc.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/duration_formatter.dart';
import '../../core/widgets/seek_bar.dart';
import 'widgets/player_artwork.dart';
import 'widgets/queue_sheet.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        final item = state.currentItem;
        final duration = state.duration.inMilliseconds == 0
            ? const Duration(minutes: 3)
            : state.duration;
        final progress = duration.inMilliseconds == 0
            ? 0.0
            : state.position.inMilliseconds / duration.inMilliseconds;

        return Scaffold(
          appBar: AppBar(title: const Text('Player')),
          body: SafeArea(
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) < -200) {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => const QueueSheet(),
                  );
                }
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                children: [
                  const PlayerArtwork(),
                  const SizedBox(height: 28),
                  Text(
                    item?.title ?? 'No media selected',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item?.artist ?? 'Open Library to choose something',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  SeekBar(
                    value: progress.clamp(0, 1),
                    bufferedValue: progress.clamp(0, 1),
                    onChanged: item == null
                        ? null
                        : (value) {
                            context.read<PlayerBloc>().add(
                                  Seek(
                                    Duration(
                                      milliseconds: (duration.inMilliseconds * value).round(),
                                    ),
                                  ),
                                );
                          },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DurationFormatter.format(state.position)),
                      Text('-${DurationFormatter.format(duration - state.position)}'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 36,
                        onPressed: () => context.read<PlayerBloc>().add(const SkipPrev()),
                        icon: const Icon(Icons.skip_previous),
                      ),
                      const SizedBox(width: 16),
                      IconButton.filled(
                        onPressed: item == null
                            ? null
                            : () => context
                                .read<PlayerBloc>()
                                .add(state.isPlaying ? const Pause() : const Play()),
                        constraints: const BoxConstraints.tightFor(width: 72, height: 72),
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          shape: const CircleBorder(),
                        ),
                        icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow, size: 38),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        iconSize: 36,
                        onPressed: () => context.read<PlayerBloc>().add(const SkipNext()),
                        icon: const Icon(Icons.skip_next),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilterChip(
                        selected: state.shuffle,
                        label: const Text('Shuffle'),
                        avatar: const Icon(Icons.shuffle),
                        onSelected: (value) => context.read<PlayerBloc>().add(SetShuffle(value)),
                      ),
                      FilterChip(
                        selected: state.loop,
                        label: const Text('Loop'),
                        avatar: const Icon(Icons.repeat),
                        onSelected: (value) => context.read<PlayerBloc>().add(SetLoop(value)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
