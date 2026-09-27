import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'medicine.dart';
import 'history_entry.dart';

// This runs in a separate background isolate when the user taps a
// notification action button (e.g. "Mark Taken") while the app is
// closed or backgrounded. Because it's a background isolate, it
// can't touch any UI or in-memory app state — it talks directly to
// SharedPreferences using the exact same keys/format as
// MedicineStorage and HistoryStorage, so whatever it writes shows
// up correctly the next time the app is opened.
//
// Must stay top-level (not a class method) and keep this pragma —
// both are required by flutter_local_notifications for background
// isolate entry points.
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService._handleAction(response);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _remindersChannelId = 'medicine_reminders_channel';
  static const String _alarmsChannelId = 'medicine_alarms_channel';

  static Future<void> initialize() async {
    // Note: we deliberately do NOT call tz.setLocalLocation() here.
    // All scheduling below uses tz.UTC as a wrapper around an
    // already-correct local DateTime instead (see
    // _nextInstanceOfTime), which needs no setup and can't silently
    // fail the way setLocalLocation did on this device.
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // we ask explicitly below instead
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) async {
        // Foreground / app-just-backgrounded tap or action button.
        await _handleAction(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );

    // Two separate channels: a normal-priority one for "Notification"
    // style reminders, and a max-importance, full-screen-intent one
    // for "Alarm" style reminders so they behave differently even
    // though they go through the same plugin.
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _remindersChannelId,
      'Medicine reminders',
      description: 'Standard reminders to take a medicine',
      importance: Importance.high,
    ));

    await androidPlugin?.createNotificationChannel(AndroidNotificationChannel(
      _alarmsChannelId,
      'Medicine alarms',
      description: 'Loud, high-priority reminders for important medicines',
      importance: Importance.max,
      playSound: true,
      sound: const UriAndroidNotificationSound('content://settings/system/alarm_alert'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 800, 400, 800, 400, 800]),
    ));

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static const List<String> _weekdayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  /// Cancels any existing reminders for this medicine, then
  /// schedules fresh ones based on its current frequency, active
  /// days, reminder time, and reminder style.
  static Future<void> scheduleForMedicine(Medicine med) async {
    await cancelForMedicine(med);

    // Don't bother scheduling something that's already over.
    final today = Medicine.todayString();
    if (med.endDate != null && med.endDate!.compareTo(today) < 0) return;

    final parts = med.reminderTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final isAlarm = med.reminderStyle == 'alarm';
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        isAlarm ? _alarmsChannelId : _remindersChannelId,
        isAlarm ? 'Medicine alarms' : 'Medicine reminders',
        importance: isAlarm ? Importance.max : Importance.high,
        priority: isAlarm ? Priority.max : Priority.high,
        fullScreenIntent: isAlarm,
        category: isAlarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
        ongoing: isAlarm,
        autoCancel: !isAlarm,
        actions: const [
          AndroidNotificationAction('taken', 'Mark Taken', showsUserInterface: false),
          AndroidNotificationAction('skip', 'Skip', showsUserInterface: false),
        ],
      ),
      iOS: DarwinNotificationDetails(
        interruptionLevel: isAlarm
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
        categoryIdentifier: 'medicineReminder',
      ),
    );

    final payload = jsonEncode({'docId': med.docId, 'name': med.name});

    if (med.frequency == 'Specific days' && med.activeDays.isNotEmpty) {
      for (final day in med.activeDays) {
        final weekdayIndex = _weekdayNames.indexOf(day) + 1; // 1=Mon..7=Sun
        if (weekdayIndex == 0) continue;
        await _scheduleOne(
          id: med.notificationId + weekdayIndex,
          title: med.name,
          body: 'Time for ${med.dosage} — ${med.timing}',
          scheduledDate: _nextInstanceOfWeekdayTime(weekdayIndex, hour, minute),
          details: details,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
        );
      }
    } else {
      // 'Daily'
      await _scheduleOne(
        id: med.notificationId,
        title: med.name,
        body: 'Time for ${med.dosage} — ${med.timing}',
        scheduledDate: _nextInstanceOfTime(hour, minute),
        details: details,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    }
  }

  // Schedules one notification, trying EXACT timing first. If that
  // throws (most commonly because the "Alarms & reminders" special
  // permission hasn't actually been granted on Android 12+, which
  // silently blocks exact alarms), this catches it, logs it clearly
  // so it's visible in the debug console instead of vanishing, and
  // retries with INEXACT scheduling instead — which doesn't need
  // that permission at all. Inexact reminders may arrive a little
  // late (Android batches them to save battery) but this guarantees
  // something fires rather than nothing.
  static Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required DateTimeComponents matchDateTimeComponents,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
      debugPrint('NotificationService: scheduled id=$id "$title" at $scheduledDate (exact)');
    } catch (e) {
      debugPrint('NotificationService: EXACT scheduling failed for id=$id "$title": $e');
      debugPrint('NotificationService: retrying id=$id with INEXACT scheduling instead');
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: matchDateTimeComponents,
          payload: payload,
        );
        debugPrint('NotificationService: scheduled id=$id "$title" at $scheduledDate (inexact fallback)');
      } catch (e2) {
        debugPrint('NotificationService: INEXACT scheduling ALSO failed for id=$id "$title": $e2');
      }
    }
  }

  static Future<void> cancelForMedicine(Medicine med) async {
    await _plugin.cancel(med.notificationId);
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(med.notificationId + weekday);
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    // FIX: previously used tz.local, which requires
    // tz.setLocalLocation() to have run successfully first. On this
    // device that setup silently failed (LateInitializationError),
    // meaning every single scheduling call was crashing invisibly.
    // Using tz.UTC instead needs no setup at all — it's a built-in
    // constant — and works correctly here because we already build
    // "scheduled" using plain Dart's real local time above; we're
    // only wrapping an already-correct instant in a TZDateTime to
    // satisfy the plugin's required parameter type.
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(scheduled, tz.UTC);
  }

  static tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(scheduled, tz.UTC);
  }

  // Fires immediately, with no scheduling involved at all. Purely a
  // diagnostic: if this doesn't show up on the phone right away,
  // the problem is Do Not Disturb, a blocked notification channel,
  // or a lock-screen display setting — not the scheduling code.
  static Future<void> testNow() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _alarmsChannelId,
        'Medicine alarms',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: DarwinNotificationDetails(interruptionLevel: InterruptionLevel.timeSensitive),
    );
    try {
      await _plugin.show(999999, 'Test notification', 'If you can see this, notifications work!', details);
      debugPrint('NotificationService: test notification shown successfully');
    } catch (e) {
      debugPrint('NotificationService: test notification FAILED: $e');
    }
  }

  // Shared by both the foreground and background response handlers.
  // Reads/writes SharedPreferences directly rather than touching any
  // widget state, since this must work even when the app isn't running.
  static Future<void> _handleAction(NotificationResponse response) async {
    if (response.actionId != 'taken' && response.actionId != 'skip') {
      return; // plain tap with no action — just opens the app
    }

    final payload = response.payload;
    if (payload == null) return;
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    final docId = decoded['docId'] as String;
    final name = decoded['name'] as String;

    final prefs = await SharedPreferences.getInstance();

    // Update the medicine's taken state, matching MedicineStorage's format.
    final medsJson = prefs.getString('medicines_list');
    if (medsJson != null) {
      final List<dynamic> medsList = jsonDecode(medsJson);
      for (final item in medsList) {
        final itemDocId =
            (item['name'] as String).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
        if (itemDocId == docId) {
          if (response.actionId == 'taken') {
            item['isTaken'] = true;
            item['lastTakenDate'] = Medicine.todayString();
            final currentStock = item['stockCount'] ?? 20;
            if (currentStock > 0) item['stockCount'] = currentStock - 1;
          }
          break;
        }
      }
      await prefs.setString('medicines_list', jsonEncode(medsList));
    }

    // Log it to history, matching HistoryStorage's format.
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final entry = HistoryEntry(
      medicineName: name,
      date: '${now.day} ${months[now.month - 1]}',
      time: '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}',
      status: response.actionId == 'taken' ? 'taken' : 'missed',
    );
    final historyJson = prefs.getString('history_entries');
    final List<dynamic> history = historyJson == null ? [] : jsonDecode(historyJson);
    history.add(entry.toMap());
    await prefs.setString('history_entries', jsonEncode(history));
  }
}