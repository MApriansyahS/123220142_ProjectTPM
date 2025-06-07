//li/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzData;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifier = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);

    await _notifier.initialize(initSettings);

    // Inisialisasi data zona waktu
    tzData.initializeTimeZones();
  }

  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'moodmeal_channel',
      'MoodMeal',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails notifDetails = NotificationDetails(android: androidDetails);

    await _notifier.show(0, title, body, notifDetails);
  }

  static Future<void> showDailyNotification(int id, String title, String body, int hour, int minute) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'moodmeal_channel',
      'MoodMeal',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails notifDetails = NotificationDetails(android: androidDetails);

    await _notifier.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
