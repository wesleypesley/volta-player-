import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/media_item.dart';
import '../../services/library_service.dart';
part 'library_event.dart';
part 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc() : super(const LibraryState()) {
    on<LoadLibrary>(_onLoadLibrary);
    on<RefreshLibrary>(_onLoadLibrary);
    on<FilterByType>(_onFilterByType);
    on<SearchLibrary>(_onSearchLibrary);
    on<ImportMediaFromDevice>(_onImportMediaFromDevice);
    on<DeleteMediaFromLibrary>(_onDeleteMediaFromLibrary);
  }

  Future<void> _onLoadLibrary(
      LibraryEvent event, Emitter<LibraryState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final items = await LibraryService.instance.loadLibrary();
      emit(state.copyWith(items: items, isLoading: false));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  void _onFilterByType(FilterByType event, Emitter<LibraryState> emit) {
    emit(state.copyWith(
        activeFilter: event.type, clearFilter: event.type == null));
  }

  Future<void> _onSearchLibrary(
      SearchLibrary event, Emitter<LibraryState> emit) async {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onImportMediaFromDevice(
    ImportMediaFromDevice event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(isImporting: true, clearError: true));
    try {
      final items = await LibraryService.instance.importFromDevice();
      emit(state.copyWith(items: items, isImporting: false));
    } catch (error) {
      emit(state.copyWith(isImporting: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onDeleteMediaFromLibrary(
    DeleteMediaFromLibrary event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(clearError: true));
    try {
      final items = await LibraryService.instance.deleteItem(
        event.item,
        deleteFile: event.deleteFile,
      );
      emit(state.copyWith(items: items));
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }
}
