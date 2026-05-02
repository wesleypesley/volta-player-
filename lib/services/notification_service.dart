import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  int _notificationIdCounter = 0;

  int _nextId() => _notificationIdCounter++;

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    
    await _plugin.initialize(initSettings);
    await _createChannel();
  }

  Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      'downloads',
      'Downloads',
      description: 'Download completion and progress notifications',
      importance: Importance.defaultImportance,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showDownloadComplete(String mediaTitle) async {
    await _plugin.show(
      _nextId(),
      'Download Complete',
      mediaTitle,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'downloads',
          'Downloads',
          channelDescription: 'Download completion notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> showDownloadFailed(String mediaTitle, String error) async {
    await _plugin.show(
      _nextId(),
      'Download Failed',
      '$mediaTitle - $error',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'downloads',
          'Downloads',
          channelDescription: 'Download completion notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
