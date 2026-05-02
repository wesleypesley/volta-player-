import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/library_bloc/library_bloc.dart';
import '../../blocs/player_bloc/player_bloc.dart';
import '../../models/media_item.dart';
import '../../models/playlist.dart';
import '../../services/database_service.dart';
import '../../widgets/music_video_toggle.dart';
import 'widgets/media_grid_item.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Playlist> _playlists = const [];

  @override
  void initState() {
    super.initState();
    context.read<LibraryBloc>().add(const LoadLibrary());
    _loadPlaylists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    final playlists = await DatabaseService.instance.getPlaylists();
    if (!mounted) return;
    setState(() => _playlists = playlists);
  }

  Future<Playlist?> _createPlaylist({MediaItem? initialItem}) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Playlist name',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();

    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final playlist = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
      mediaItemIds: initialItem == null ? const [] : [initialItem.id],
      createdAt: DateTime.now(),
    );
    await DatabaseService.instance.upsertPlaylist(playlist);
    await _loadPlaylists();
    if (!mounted) return playlist;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created "$trimmed"')),
    );
    return playlist;
  }

  Future<void> _showAddToPlaylist(MediaItem item) async {
    if (_playlists.isEmpty) {
      await _createPlaylist(initialItem: item);
      return;
    }

    final choice = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create new playlist'),
              onTap: () => Navigator.of(context).pop('new'),
            ),
            const Divider(height: 1),
            for (final playlist in _playlists)
              ListTile(
                leading: const Icon(Icons.queue_music),
                title: Text(playlist.name),
                subtitle: Text('${playlist.mediaItemIds.length} tracks'),
                onTap: () => Navigator.of(context).pop(playlist),
              ),
          ],
        ),
      ),
    );

    if (choice == 'new') {
      await _createPlaylist(initialItem: item);
    } else if (choice is Playlist) {
      await DatabaseService.instance.addMediaToPlaylist(choice.id, item.id);
      await _loadPlaylists();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to "${choice.name}"')),
      );
    }
  }

  Future<void> _confirmDeleteMedia(MediaItem item) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${item.title}"?'),
        content: const Text(
            'Remove it from your library, or delete the actual audio file from this device too.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('library'),
            child: const Text('Remove from library'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('file'),
            child: const Text('Delete file'),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    context.read<LibraryBloc>().add(
          DeleteMediaFromLibrary(item, deleteFile: choice == 'file'),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted "${item.title}"')),
    );
    await _loadPlaylists();
  }

  Future<void> _confirmDeletePlaylist(Playlist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${playlist.name}"?'),
        content: const Text(
            'This deletes the playlist only. The songs stay in your library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete playlist'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DatabaseService.instance.deletePlaylist(playlist.id);
    await _loadPlaylists();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted "${playlist.name}"')),
    );
  }

  Future<void> _openPlaylist(Playlist playlist) async {
    final items = await DatabaseService.instance.getPlaylistItems(playlist.id);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(playlist.name),
              subtitle: Text('${items.length} tracks'),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Delete playlist',
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _confirmDeletePlaylist(playlist);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                  if (items.isNotEmpty)
                    IconButton.filled(
                      tooltip: 'Play playlist',
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        context.read<PlayerBloc>().add(
                              SetQueue(items, startAt: items.first),
                            );
                        context.read<PlayerBloc>().add(Play(items.first));
                      },
                      icon: const Icon(Icons.play_arrow),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (items.isEmpty)
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('Add audio from phone storage'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context
                      .read<LibraryBloc>()
                      .add(const ImportMediaFromDevice());
                },
              )
            else
              for (final item in items)
                ListTile(
                  leading: Icon(item.type == MediaType.video
                      ? Icons.movie
                      : Icons.music_note),
                  title: Text(item.title),
                  subtitle: item.artist == null ? null : Text(item.artist!),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context
                        .read<PlayerBloc>()
                        .add(SetQueue(items, startAt: item));
                    context.read<PlayerBloc>().add(Play(item));
                  },
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Playlists', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _createPlaylist(),
              icon: const Icon(Icons.add),
              label: const Text('New playlist'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: _playlists.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _createPlaylist(),
                    icon: const Icon(Icons.queue_music),
                    label: const Text('Create playlist'),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    return InputChip(
                      avatar: const Icon(Icons.queue_music),
                      label: Text(
                          '${playlist.name} (${playlist.mediaItemIds.length})'),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () => _confirmDeletePlaylist(playlist),
                      onPressed: () => _openPlaylist(playlist),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemCount: _playlists.length,
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            tooltip: 'Add from phone',
            onPressed: () {
              if (context.read<LibraryBloc>().state.isImporting) return;
              context.read<LibraryBloc>().add(const ImportMediaFromDevice());
            },
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () =>
                context.read<LibraryBloc>().add(const RefreshLibrary()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          final items = state.visibleItems;
          return RefreshIndicator(
            onRefresh: () async {
              context.read<LibraryBloc>().add(const RefreshLibrary());
              await _loadPlaylists();
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      children: [
                        MusicVideoToggle(
                          value: state.activeFilter == MediaType.video
                              ? MusicVideoSelection.video
                              : MusicVideoSelection.music,
                          onChanged: (value) {
                            context.read<LibraryBloc>().add(
                                  FilterByType(
                                    value == MusicVideoSelection.music
                                        ? MediaType.audio
                                        : MediaType.video,
                                  ),
                                );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildPlaylistSection(),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search library',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: state.activeFilter == null
                                ? null
                                : IconButton(
                                    onPressed: () => context
                                        .read<LibraryBloc>()
                                        .add(const FilterByType(null)),
                                    icon: const Icon(Icons.filter_alt_off),
                                  ),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) => context
                              .read<LibraryBloc>()
                              .add(SearchLibrary(value)),
                        ),
                        if (state.isImporting) ...[
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(),
                        ],
                        if (state.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            state.errorMessage!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (state.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Library is empty')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.orientationOf(context) ==
                                Orientation.landscape
                            ? 3
                            : 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return InkWell(
                          onTap: () {
                            context
                                .read<PlayerBloc>()
                                .add(SetQueue(items, startAt: item));
                            context.read<PlayerBloc>().add(Play(item));
                          },
                          onLongPress: () => _showAddToPlaylist(item),
                          child: MediaGridItem(
                            title: item.title,
                            onAddToPlaylist: () => _showAddToPlaylist(item),
                            onDelete: () => _confirmDeleteMedia(item),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
