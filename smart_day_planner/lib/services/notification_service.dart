import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    // Türkiye saati ayarı (Hata riskini önlemek için manuel set)
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (e) {
      // Hata durumunda varsayılan devam et
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidInit));

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  // Videoda anlık test yapmanızı sağlar ✅
  Future<void> showInstantNotification() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'test_channel', 'Test',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    await _plugin.show(123, "SmartDay Hatırlatıcı", "Bu bir test bildirimidir! 🚀", details);
  }

  Future<void> scheduleTaskNotification({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id, title, body, scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails('tasks', 'Görevler', importance: Importance.max, priority: Priority.high),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
