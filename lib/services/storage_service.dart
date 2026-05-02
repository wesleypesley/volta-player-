import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class StorageService {
  static final StorageService instance = StorageService._init();
  StorageService._init();

  static const MethodChannel _channel = MethodChannel('com.voltaplayer.volta_player/storage');

  Future<String> getDownloadPath() async {
    try {
      final path = await _channel.invokeMethod<String>('getDownloadPath');
      return path ?? '';
    } catch (error) {
      debugPrint('Unable to read download path: $error');
      return '';
    }
  }

  Future<String> setDownloadPath(String path) async {
    try {
      final savedPath = await _channel.invokeMethod<String>(
        'setDownloadPath',
        {'path': path.trim()},
      );
      return savedPath ?? path.trim();
    } catch (error) {
      debugPrint('Unable to save download path: $error');
      return path.trim();
    }
  }

  Future<String> resetDownloadPath() async {
    try {
      final path = await _channel.invokeMethod<String>('resetDownloadPath');
      return path ?? '';
    } catch (error) {
      debugPrint('Unable to reset download path: $error');
      return '';
    }
  }

  Future<String?> pickDownloadPath() async {
    try {
      return _channel.invokeMethod<String>('pickDownloadPath');
    } catch (error) {
      debugPrint('Unable to pick download path: $error');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> pickMediaFiles() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('pickMediaFiles');
      return (result ?? const [])
          .whereType<Map<dynamic, dynamic>>()
          .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
          .toList();
    } catch (error) {
      debugPrint('Unable to pick media files: $error');
      return const [];
    }
  }
}
