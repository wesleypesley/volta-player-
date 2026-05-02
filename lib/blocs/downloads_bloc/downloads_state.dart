part of 'downloads_bloc.dart';

abstract class DownloadsState extends Equatable {
  const DownloadsState();

  @override
  List<Object> get props => [];
}

class DownloadsLoading extends DownloadsState {}

class DownloadsLoaded extends DownloadsState {
  final List<DownloadTask> active;
  final List<DownloadTask> completed;

  const DownloadsLoaded({
    this.active = const [],
    this.completed = const [],
  });

  @override
  List<Object> get props => [active, completed];

  DownloadsLoaded copyWith({
    List<DownloadTask>? active,
    List<DownloadTask>? completed,
  }) {
    return DownloadsLoaded(
      active: active ?? this.active,
      completed: completed ?? this.completed,
    );
  }
}