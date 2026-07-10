import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );

    // Request permissions for Firebase Messaging
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Request permissions for Local Notifications (Android 13+)
    await requestPermissions();

    // Show welcome notification
    showWelcomeNotification();
    
    // Schedule retention notifications
    await scheduleRetentionNotifications();

    // Foreground messages handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _flutterLocalNotificationsPlugin.show(
          id: message.notification.hashCode,
          title: message.notification!.title,
          body: message.notification!.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'firebase_push_channel',
              'Push Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });
  }

  Future<void> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<void> showWelcomeNotification() async {
    await _flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Welcome to Growup AI! ✨',
      body: 'Ready to level up your aura today?',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'welcome_channel',
          'Welcome Notifications',
          channelDescription: 'Notifications shown when the app opens',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> scheduleRetentionNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasScheduled = prefs.getBool('retention_notifications_scheduled') ?? false;

    if (!hasScheduled) {
      final now = tz.TZDateTime.now(tz.local);

      // Notification 1: 24 hours later
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: 1001,
        title: 'Unlock your full potential! 🚀',
        body: 'Hey buddy, why are you thinking about money? It\'s just the price of a burger or pizza! 🍔🍕',
        scheduledDate: now.add(const Duration(hours: 24)),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'retention_channel',
            'App Follow-ups',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      // Notification 2: 3 days later
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: 1002,
        title: 'Your GrowUp AI is fading... 📉',
        body: 'Don\'t miss out on your daily lookmaxxing routine. Get Premium and become the best version of yourself!',
        scheduledDate: now.add(const Duration(days: 3)),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'retention_channel',
            'App Follow-ups',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      await prefs.setBool('retention_notifications_scheduled', true);
    }
  }

  Future<void> cancelRetentionNotifications() async {
    await _flutterLocalNotificationsPlugin.cancel(id: 1001);
    await _flutterLocalNotificationsPlugin.cancel(id: 1002);
  }

  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'aura_tasks_channel',
            'Daily Routines',
            channelDescription:
                'Reminders for your AI generated Lookmaxxing tasks',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // Fallback to inexact if Exact Alarm permission is denied (Android 14+)
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'aura_tasks_channel',
              'Daily Routines',
              channelDescription:
                  'Reminders for your AI generated Lookmaxxing tasks',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (innerE) {
        debugPrint('Failed to schedule notification (fallback failed): $innerE');
      }
    }
  }

  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
