import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/download_task.dart';
import '../../models/media_item.dart';
import '../../services/database_service.dart';
import '../../services/download_service.dart';
import '../../services/notification_service.dart';

part 'downloads_event.dart';
part 'downloads_state.dart';

class DownloadsBloc extends Bloc<DownloadsEvent, DownloadsState> {
  DownloadsBloc() : super(DownloadsLoading()) {
    on<LoadDownloads>(_onLoadDownloads);
    on<AddDownload>(_onAddDownload);
    on<CancelDownload>(_onCancelDownload);
    on<RetryDownload>(_onRetryDownload);
    on<UpdateProgress>(_onUpdateProgress);
  }

  Future<void> _onLoadDownloads(LoadDownloads event, Emitter<DownloadsState> emit) async {
    final allTasks = await DatabaseService.instance.getDownloadTasks();
    
    final active = allTasks.where((t) => t.status != DownloadStatus.complete && t.status != DownloadStatus.failed).toList();
    final completed = allTasks.where((t) => t.status == DownloadStatus.complete || t.status == DownloadStatus.failed).toList();
    
    emit(DownloadsLoaded(active: active, completed: completed));
  }

  Future<void> _onAddDownload(AddDownload event, Emitter<DownloadsState> emit) async {
    var task = DownloadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: event.url,
      format: event.format,
      status: DownloadStatus.downloading,
      createdAt: DateTime.now(),
    );

    await DatabaseService.instance.upsertDownloadTask(task);
    
    _startDownloadProcess(task);
    
    add(LoadDownloads());
  }

  void _startDownloadProcess(DownloadTask initialTask) {
    var currentTask = initialTask;
    
    DownloadService.instance.download(initialTask.id, initialTask.url, initialTask.format).listen(
      (update) {
        currentTask = currentTask.copyWith(
          progress: update.progress,
          speedDisplay: update.speed,
          etaDisplay: update.eta,
          filePath: update.filePath,
          status: update.isDone ? DownloadStatus.complete : DownloadStatus.downloading,
        );
        add(UpdateProgress(currentTask));
      },
      onError: (error) {
        currentTask = currentTask.copyWith(
          status: DownloadStatus.failed,
          errorMessage: error.toString(),
        );
        add(UpdateProgress(currentTask));
        NotificationService.instance.showDownloadFailed(initialTask.url, "Failed");
      },
      onDone: () async {
        if (currentTask.status != DownloadStatus.failed) {
          // If it didn't fail, it's complete
          currentTask = currentTask.copyWith(
            status: DownloadStatus.complete,
            progress: 1.0,
          );
          add(UpdateProgress(currentTask));
          NotificationService.instance.showDownloadComplete(initialTask.url);
          _registerCompletedDownload(currentTask);
        }
      },
    );
  }

  Future<void> _registerCompletedDownload(DownloadTask task) async {
    final filePath = task.filePath;
    if (filePath == null || filePath.isEmpty) return;
    final title = filePath.split(RegExp(r'[\\/]')).last;
    await DatabaseService.instance.upsertMediaItem(
      MediaItem(
        id: task.id,
        title: title,
        type: task.format == DownloadFormat.audioOnly ? MediaType.audio : MediaType.video,
        filePath: filePath,
        duration: Duration.zero,
        addedAt: DateTime.now(),
        fileSizeBytes: 0,
        sourceUrl: task.url,
      ),
    );
  }

  Future<void> _onCancelDownload(CancelDownload event, Emitter<DownloadsState> emit) async {
    DownloadService.instance.cancelDownload(event.taskId);
    
    final allTasks = await DatabaseService.instance.getDownloadTasks();
    final matching = allTasks.where((task) => task.id == event.taskId);
    if (matching.isNotEmpty) {
      await DatabaseService.instance.upsertDownloadTask(
        matching.first.copyWith(
          status: DownloadStatus.failed,
          errorMessage: 'Cancelled by user',
        ),
      );
    }
    add(LoadDownloads());
  }

  Future<void> _onRetryDownload(RetryDownload event, Emitter<DownloadsState> emit) async {
    final allTasks = await DatabaseService.instance.getDownloadTasks();
    final matching = allTasks.where((task) => task.id == event.taskId);
    if (matching.isEmpty) return;

    var task = matching.first.copyWith(
      status: DownloadStatus.downloading,
      progress: 0.0,
      clearError: true,
    );

    await DatabaseService.instance.upsertDownloadTask(task);
    
    _startDownloadProcess(task);
    add(LoadDownloads());
  }

  Future<void> _onUpdateProgress(UpdateProgress event, Emitter<DownloadsState> emit) async {
    await DatabaseService.instance.upsertDownloadTask(event.task);
    add(LoadDownloads());
  }
}
