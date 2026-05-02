import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/media_item.dart';
import 'database_service.dart';
import 'storage_service.dart';

class LibraryService {
  static final LibraryService instance = LibraryService._init();
  LibraryService._init();

  static const _audioExtensions = {
    '.mp3',
    '.m4a',
    '.aac',
    '.opus',
    '.ogg',
    '.wav',
    '.flac'
  };
  static const _videoExtensions = {'.mp4', '.mkv', '.webm', '.mov', '.m4v'};

  Future<List<MediaItem>> loadLibrary() async {
    final existing = await DatabaseService.instance.getMediaItems();
    final scanned = await scanDownloadDirectories();
    if (scanned.isEmpty) return existing;

    final existingPaths = existing.map((item) => item.filePath).toSet();
    for (final item
        in scanned.where((item) => !existingPaths.contains(item.filePath))) {
      await DatabaseService.instance.upsertMediaItem(item);
    }
    return DatabaseService.instance.getMediaItems();
  }

  Future<List<MediaItem>> search(String query) {
    return DatabaseService.instance.searchMedia(query);
  }

  Future<List<MediaItem>> importFromDevice() async {
    final picked = await StorageService.instance.pickMediaFiles();
    final imported =
        picked.map(_mediaItemFromNativeMap).whereType<MediaItem>().toList();
    for (final item in imported) {
      await DatabaseService.instance.upsertMediaItem(item);
    }
    return DatabaseService.instance.getMediaItems();
  }

  Future<List<MediaItem>> deleteItem(MediaItem item,
      {required bool deleteFile}) async {
    if (deleteFile) {
      try {
        final file = File(item.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } on FileSystemException {
        // Keep the library cleanup working even if Android refuses file deletion.
      }
    }
    await DatabaseService.instance.deleteMediaItem(item.id);
    return DatabaseService.instance.getMediaItems();
  }

  MediaItem? _mediaItemFromNativeMap(Map<String, dynamic> map) {
    final path = map['path']?.toString();
    final title = map['title']?.toString();
    final typeName = map['type']?.toString();
    if (path == null || path.isEmpty || title == null || title.isEmpty) {
      return null;
    }
    final size = map['size'];
    return MediaItem(
      id: path,
      title: title,
      type: typeName == 'video' ? MediaType.video : MediaType.audio,
      filePath: path,
      duration: Duration.zero,
      addedAt: DateTime.now(),
      fileSizeBytes:
          size is int ? size : int.tryParse(size?.toString() ?? '') ?? 0,
    );
  }

  Future<List<MediaItem>> scanDownloadDirectories() async {
    final roots = <Directory>[];
    final configuredPath = await StorageService.instance.getDownloadPath();
    if (configuredPath.isNotEmpty && !configuredPath.startsWith('content://')) {
      roots.add(Directory(configuredPath));
    }

    final external = await getExternalStorageDirectory();
    if (external != null) {
      roots
          .add(Directory(p.join(external.path, 'Downloads', 'VoltaDownloads')));
      roots.add(Directory(p.join(external.path, 'VoltaDownloads')));
    }

    final docs = await getApplicationDocumentsDirectory();
    roots.add(Directory(p.join(docs.path, 'VoltaDownloads')));

    final items = <MediaItem>[];
    for (final root in roots) {
      if (!await root.exists()) continue;
      await for (final entity
          in root.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final extension = p.extension(entity.path).toLowerCase();
        final type = _audioExtensions.contains(extension)
            ? MediaType.audio
            : _videoExtensions.contains(extension)
                ? MediaType.video
                : null;
        if (type == null) continue;
        final stat = await entity.stat();
        items.add(
          MediaItem(
            id: entity.path,
            title: p.basenameWithoutExtension(entity.path).replaceAll('_', ' '),
            type: type,
            filePath: entity.path,
            duration: Duration.zero,
            addedAt: stat.modified,
            fileSizeBytes: stat.size,
          ),
        );
      }
    }
    return items;
  }
}
