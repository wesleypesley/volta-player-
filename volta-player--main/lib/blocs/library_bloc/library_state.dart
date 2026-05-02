part of 'library_bloc.dart';

class LibraryState {
  final List<MediaItem> items;
  final MediaType? activeFilter;
  final String searchQuery;
  final bool isLoading;
  final bool isImporting;
  final String? errorMessage;

  const LibraryState({
    this.items = const [],
    this.activeFilter,
    this.searchQuery = '',
    this.isLoading = false,
    this.isImporting = false,
    this.errorMessage,
  });

  List<MediaItem> get visibleItems {
    final filtered = activeFilter == null
        ? items
        : items.where((item) => item.type == activeFilter).toList();
    if (searchQuery.trim().isEmpty) return filtered;
    final needle = searchQuery.toLowerCase();
    return filtered
        .where(
          (item) =>
              item.title.toLowerCase().contains(needle) ||
              (item.artist?.toLowerCase().contains(needle) ?? false),
        )
        .toList();
  }

  LibraryState copyWith({
    List<MediaItem>? items,
    MediaType? activeFilter,
    bool clearFilter = false,
    String? searchQuery,
    bool? isLoading,
    bool? isImporting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LibraryState(
      items: items ?? this.items,
      activeFilter: clearFilter ? null : activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isImporting: isImporting ?? this.isImporting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
