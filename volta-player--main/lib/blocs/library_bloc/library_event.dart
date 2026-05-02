part of 'library_bloc.dart';

abstract class LibraryEvent {
  const LibraryEvent();
}

class LoadLibrary extends LibraryEvent {
  const LoadLibrary();
}

class RefreshLibrary extends LibraryEvent {
  const RefreshLibrary();
}

class FilterByType extends LibraryEvent {
  final MediaType? type;
  const FilterByType(this.type);
}

class SearchLibrary extends LibraryEvent {
  final String query;
  const SearchLibrary(this.query);
}

class ImportMediaFromDevice extends LibraryEvent {
  const ImportMediaFromDevice();
}

class DeleteMediaFromLibrary extends LibraryEvent {
  final MediaItem item;
  final bool deleteFile;
  const DeleteMediaFromLibrary(this.item, {required this.deleteFile});
}
