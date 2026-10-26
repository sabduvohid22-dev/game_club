import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';

/// MUHIM: ilova butunlay yopilganda oddiy Dart Timer ishlamaydi (Android/iOS
/// buni cheklaydi). Shu sababli signalni ilova ichidagi taймerga emas,
/// balki operatsion tizim darajasidagi rejalashtirilgan bildirishnomaga
/// bog'laymiz — u ilova fonda yoki butunlay yopiq bo'lsa ham, ekran o'chiq
/// bo'lsa ham, belgilangan vaqtda tovush bilan ishlaydi.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));
    } catch (_) {
      // Ba'zi platformalarda vaqt zonasi topilmasligi mumkin
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await Permission.notification.request();
      if (Platform.isAndroid) {
        await Permission.scheduleExactAlarm.request();
      }
    }

    if (!kIsWeb && Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'session_end_channel',
        'Seans tugashi signali',
        description: 'Stansiya vaqti tugaganda beriladigan ovozli signal',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  /// [id] sifatida stansiya id sining hash kodini ishlating (int bo'lishi kerak).
  Future<void> scheduleEndAlarm({
    required int id,
    required DateTime endTime,
    required String stationName,
  }) async {
    if (kIsWeb) return;
    final scheduledDate = tz.TZDateTime.from(endTime, tz.local);
    await _plugin.zonedSchedule(
      id,
      '⏰ Vaqt tugadi!',
      "$stationName stansiyasining belgilangan vaqti yakunlandi.",
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'session_end_channel',
          'Seans tugashi signali',
          channelDescription: 'Stansiya vaqti tugaganda beriladigan ovozli signal',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('alarm_sound'),
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
          sound: 'alarm_sound.caf',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAlarm(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }
}
