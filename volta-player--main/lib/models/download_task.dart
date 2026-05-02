enum DownloadStatus { queued, downloading, converting, complete, failed }
enum DownloadFormat { audioOnly, videoMp4, best }

class DownloadTask {
  final String id;
  final String url;
  final DownloadStatus status;
  final double progress;
  final String? speedDisplay;
  final String? etaDisplay;
  final DownloadFormat format;
  final String? filePath;
  final String? errorMessage;
  final DateTime createdAt;

  const DownloadTask({
    required this.id,
    required this.url,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.speedDisplay,
    this.etaDisplay,
    this.format = DownloadFormat.best,
    this.filePath,
    this.errorMessage,
    required this.createdAt,
  });

  DownloadTask copyWith({
    DownloadStatus? status,
    double? progress,
    String? speedDisplay,
    String? etaDisplay,
    String? filePath,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DownloadTask(
      id: id,
      url: url,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      speedDisplay: speedDisplay ?? this.speedDisplay,
      etaDisplay: etaDisplay ?? this.etaDisplay,
      format: format,
      filePath: filePath ?? this.filePath,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'status': status.name,
      'progress': progress,
      'format': format.name,
      'file_path': filePath,
      'error_message': errorMessage,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory DownloadTask.fromMap(Map<String, dynamic> map) {
    return DownloadTask(
      id: map['id'] as String,
      url: map['url'] as String,
      status: DownloadStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => DownloadStatus.queued),
      progress: (map['progress'] as num).toDouble(),
      format: DownloadFormat.values.firstWhere((e) => e.name == map['format'], orElse: () => DownloadFormat.best),
      filePath: map['file_path'] as String?,
      errorMessage: map['error_message'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
