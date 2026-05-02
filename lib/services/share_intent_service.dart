import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../router.dart';

class ShareIntentService {
  static final ShareIntentService instance = ShareIntentService._init();
  ShareIntentService._init();

  StreamSubscription? _intentDataStreamSubscription;

  void init() {
    // Handle app already open
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> files) {
      for (final file in files) {
        if (file.type == SharedMediaType.url || file.type == SharedMediaType.text) {
          _handleSharedUrl(file.path);
        }
      }
    }, onError: (err) {
      debugPrint("ReceiveSharingIntent error: $err");
    });

    // Handle cold start
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> files) {
      for (final file in files) {
        if (file.type == SharedMediaType.url || file.type == SharedMediaType.text) {
          _handleSharedUrl(file.path);
        }
      }
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _handleSharedUrl(String url) {
    if (url.trim().isNotEmpty) {
      final encodedUrl = Uri.encodeComponent(url.trim());
      appRouter.go('/downloads?url=$encodedUrl');
    }
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }
}
