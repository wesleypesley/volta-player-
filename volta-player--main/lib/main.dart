import 'package:flutter/material.dart';

import 'app.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'package:media_kit/media_kit.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Background download continuation logic will go here
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Workmanager().initialize(callbackDispatcher);
  } catch (error) {
    debugPrint('Workmanager initialization failed: $error');
  }

  MediaKit.ensureInitialized();

  try {
    await NotificationService.instance.init();
  } catch (error) {
    debugPrint('Notification initialization failed: $error');
  }

  try {
    await DatabaseService.instance.database;
  } catch (error, stackTrace) {
    debugPrint('Database initialization failed: $error\n$stackTrace');
  }

  runApp(const VoltaApp());
}
