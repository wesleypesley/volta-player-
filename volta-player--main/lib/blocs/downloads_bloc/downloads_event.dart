part of 'downloads_bloc.dart';

abstract class DownloadsEvent extends Equatable {
  const DownloadsEvent();

  @override
  List<Object?> get props => [];
}

class LoadDownloads extends DownloadsEvent {}

class AddDownload extends DownloadsEvent {
  final String url;
  final DownloadFormat format;

  const AddDownload(this.url, this.format);

  @override
  List<Object> get props => [url, format];
}

class CancelDownload extends DownloadsEvent {
  final String taskId;

  const CancelDownload(this.taskId);

  @override
  List<Object> get props => [taskId];
}

class RetryDownload extends DownloadsEvent {
  final String taskId;

  const RetryDownload(this.taskId);

  @override
  List<Object> get props => [taskId];
}

class UpdateProgress extends DownloadsEvent {
  final DownloadTask task;

  const UpdateProgress(this.task);

  @override
  List<Object> get props => [task];
}