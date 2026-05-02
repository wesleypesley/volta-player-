import 'package:flutter_test/flutter_test.dart';
import 'package:volta_player/core/utils/duration_formatter.dart';
import 'package:volta_player/core/utils/file_size_formatter.dart';
import 'package:volta_player/core/utils/url_validator.dart';
import 'package:volta_player/models/download_task.dart';
import 'package:volta_player/models/media_item.dart';

void main() {
  test('formats durations as minutes and padded seconds', () {
    expect(DurationFormatter.format(const Duration(seconds: 45)), '0:45');
    expect(DurationFormatter.format(const Duration(minutes: 3, seconds: 5)), '3:05');
  });

  test('formats byte counts with binary units', () {
    expect(FileSizeFormatter.format(512), '512 B');
    expect(FileSizeFormatter.format(1536), '1.5 KB');
    expect(FileSizeFormatter.format(1048576), '1.0 MB');
  });

  test('validates http and https urls with query strings', () {
    expect(UrlValidator.isValidUrl('https://www.youtube.com/watch?v=abc123'), isTrue);
    expect(UrlValidator.isValidUrl('http://example.com/file.mp4?download=1'), isTrue);
    expect(UrlValidator.isValidUrl('ftp://example.com/file.mp4'), isFalse);
    expect(UrlValidator.isValidUrl('not a url'), isFalse);
  });

  test('round trips download task map data', () {
    final createdAt = DateTime(2026, 5, 1);
    final task = DownloadTask(
      id: 'task-1',
      url: 'https://example.com/video',
      status: DownloadStatus.complete,
      progress: 1,
      format: DownloadFormat.videoMp4,
      filePath: '/tmp/video.mp4',
      createdAt: createdAt,
    );

    final copy = DownloadTask.fromMap(task.toMap());

    expect(copy.id, task.id);
    expect(copy.status, DownloadStatus.complete);
    expect(copy.format, DownloadFormat.videoMp4);
    expect(copy.filePath, '/tmp/video.mp4');
  });

  test('round trips media item map data', () {
    final item = MediaItem(
      id: 'media-1',
      title: 'Track',
      artist: 'Artist',
      type: MediaType.audio,
      filePath: '/tmp/track.mp3',
      duration: const Duration(minutes: 4),
      addedAt: DateTime(2026, 5, 1),
      fileSizeBytes: 4096,
      sourceUrl: 'https://example.com/track',
    );

    final copy = MediaItem.fromMap(item.toMap());

    expect(copy.title, 'Track');
    expect(copy.artist, 'Artist');
    expect(copy.type, MediaType.audio);
    expect(copy.duration, const Duration(minutes: 4));
    expect(copy.fileSizeBytes, 4096);
  });
}
