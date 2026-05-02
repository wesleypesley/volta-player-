import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/download_task.dart';
import 'storage_service.dart';

class DownloadProgressUpdate {
  final double progress;
  final String? speed;
  final String? eta;
  final String? currentAction;
  final String? filePath;
  final bool isDone;

  DownloadProgressUpdate({
    required this.progress,
    this.speed,
    this.eta,
    this.currentAction,
    this.filePath,
    this.isDone = false,
  });
}

class DownloadException implements Exception {
  final String message;
  DownloadException(this.message);
  @override
  String toString() => message;
}

class DownloadService {
  static final DownloadService instance = DownloadService._init();
  DownloadService._init() {
    _eventChannel.receiveBroadcastStream().listen(_onEvent);
  }

  static const MethodChannel _methodChannel =
      MethodChannel('com.voltaplayer.volta_player/youtubedl');
  static const EventChannel _eventChannel =
      EventChannel('com.voltaplayer.volta_player/youtubedl_events');

  final Map<String, StreamController<DownloadProgressUpdate>> _controllers = {};

  void _onEvent(dynamic event) {
    if (event is Map) {
      final taskId = event['taskId'] as String?;
      if (taskId == null || !_controllers.containsKey(taskId)) return;

      final controller = _controllers[taskId]!;

      if (event.containsKey('error')) {
        controller.addError(DownloadException(event['error'].toString()));
        controller.close();
        _controllers.remove(taskId);
        return;
      }

      final progress = (event['progress'] as num?)?.toDouble() ?? 0.0;
      final etaSeconds = int.tryParse(event['eta']?.toString() ?? '');
      final status = event['status'] as String?;
      final filePath = event['filePath'] as String?;
      final action = event['action'] as String?;
      final speed = event['speed'] as String?;

      String? etaStr;
      if (etaSeconds != null && etaSeconds > 0) {
        final duration = Duration(seconds: etaSeconds);
        etaStr =
            '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
      }

      controller.add(DownloadProgressUpdate(
        progress: progress,
        speed: action ?? speed,
        eta: etaStr,
        currentAction: action,
        filePath: filePath,
        isDone: status == 'done' || progress >= 1.0,
      ));

      if (status == 'done' || progress >= 1.0) {
        controller.close();
        _controllers.remove(taskId);
      }
    }
  }

  Stream<DownloadProgressUpdate> download(
      String taskId, String url, DownloadFormat format) {
    final controller = StreamController<DownloadProgressUpdate>();
    _controllers[taskId] = controller;

    () async {
      try {
        final outputDir = await StorageService.instance.getDownloadPath();
        await _methodChannel.invokeMethod('download', {
          'url': url,
          'taskId': taskId,
          'format': format.name,
          'outputDir': outputDir,
        });
      } catch (e) {
        controller.addError(DownloadException('Failed to start download: $e'));
        controller.close();
        _controllers.remove(taskId);
      }
    }();

    return controller.stream;
  }

  Future<void> cancelDownload(String taskId) async {
    try {
      await _methodChannel.invokeMethod('cancel', {'taskId': taskId});
    } catch (e) {
      debugPrint('Cancel failed: $e');
    }
  }

  Future<void> updateYoutubeDL() async {
    await _methodChannel.invokeMethod('updateYtdlp');
  }
}
