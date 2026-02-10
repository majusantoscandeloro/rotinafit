import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/custom_reminder.dart';
import '../models/reminders_config.dart';

class NotificationsService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onSelect,
    );

    await _requestPermissions();
    _initialized = true;
  }

  static void _onSelect(NotificationResponse? response) {
    // Pode abrir tela específica se quiser
  }

  static Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Cancela apenas os IDs usados por lembretes personalizados (300–399).
  static Future<void> _cancelCustomReminderIds() async {
    for (int id = 300; id < 400; id++) {
      await _plugin.cancel(id);
    }
  }

  static Future<void> scheduleWaterReminders(List<String> times) async {
    await cancelAll();
    int id = 0;
    for (final time in times) {
      final parts = time.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts[1]) ?? 0;
      var now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id++,
        'Hidratação',
        'Hora de tomar água! 💧',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water',
            'Lembretes de água',
            channelDescription: 'Horários para beber água',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> scheduleMealReminder(String title, String? time) async {
    if (time == null || time.isEmpty) return;
    final parts = time.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]) ?? 12;
    final minute = int.tryParse(parts[1]) ?? 0;
    var now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    const ids = {'Café': 100, 'Almoço': 101, 'Lanche': 102, 'Jantar': 103, 'Ceia': 104};
    final id = ids[title] ?? 100;
    await _plugin.zonedSchedule(
      id,
      title,
      'Lembrete: $title 🍽️',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meals',
          'Refeições',
          channelDescription: 'Lembretes de café, almoço, lanche, jantar, ceia',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleActivityReminders(
      List<int> weekdays, String time) async {
    final parts = time.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]) ?? 7;
    final minute = int.tryParse(parts[1]) ?? 0;
    for (final weekday in weekdays) {
      var now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      scheduled = _nextWeekday(scheduled, weekday);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 7));
      }
      await _plugin.zonedSchedule(
        200 + weekday,
        'Atividade física',
        'Hora de se movimentar! 🏃',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'activity',
            'Atividade física',
            channelDescription: 'Lembrete de exercícios',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// Um horário por dia da semana (dia 1–7 -> "HH:mm").
  static Future<void> scheduleActivityRemindersByDay(
      Map<int, String> timesByDay) async {
    for (final e in timesByDay.entries) {
      final weekday = e.key;
      final time = e.value;
      final parts = time.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]) ?? 7;
      final minute = int.tryParse(parts[1]) ?? 0;
      var now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      scheduled = _nextWeekday(scheduled, weekday);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 7));
      }
      await _plugin.zonedSchedule(
        200 + weekday,
        'Atividade física',
        'Hora de se movimentar! 🏃',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'activity',
            'Atividade física',
            channelDescription: 'Lembrete de exercícios',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static tz.TZDateTime _nextWeekday(tz.TZDateTime from, int weekday) {
    // weekday: 1=Mon .. 7=Sun; Dart: 1=Mon .. 7=Sun
    var d = from;
    while (d.weekday != weekday) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  /// IDs 300 + index*7 + (weekday-1) para lembretes personalizados.
  static Future<void> scheduleCustomReminders(List<CustomReminder> list) async {
    for (int index = 0; index < list.length; index++) {
      final r = list[index];
      final parts = r.time.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;
      final days = r.days.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : r.days;
      for (final weekday in days) {
        var now = tz.TZDateTime.now(tz.local);
        var scheduled = tz.TZDateTime(
            tz.local, now.year, now.month, now.day, hour, minute);
        scheduled = _nextWeekday(scheduled, weekday);
        if (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 7));
        }
        final id = 300 + index * 7 + (weekday - 1);
        await _plugin.zonedSchedule(
          id,
          r.name,
          'Lembrete: ${r.name} 🔔',
          scheduled,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'custom_reminders',
              'Lembretes personalizados',
              channelDescription: 'Lembretes criados por você',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  static Future<void> applyConfig(
      RemindersConfig config, List<CustomReminder> customReminders) async {
    await cancelAll();
    if (!config.notificationsEnabled) {
      await scheduleCustomReminders(customReminders);
      return;
    }
    await scheduleWaterReminders(config.waterTimes);
    if (config.mealBreakfast != null) {
      await scheduleMealReminder('Café', config.mealBreakfast);
    }
    if (config.mealLunch != null) {
      await scheduleMealReminder('Almoço', config.mealLunch);
    }
    if (config.mealSnack != null) {
      await scheduleMealReminder('Lanche', config.mealSnack);
    }
    if (config.mealDinner != null) {
      await scheduleMealReminder('Jantar', config.mealDinner);
    }
    if (config.mealSupper != null) {
      await scheduleMealReminder('Ceia', config.mealSupper);
    }
    if (config.useSingleActivityTime) {
      await scheduleActivityReminders(config.activityDays, config.activityTime);
    } else {
      await scheduleActivityRemindersByDay(config.activityTimesByDay);
    }
    await scheduleCustomReminders(customReminders);
  }

  /// Atualiza apenas lembretes personalizados (ex.: após adicionar/remover).
  static Future<void> applyCustomRemindersOnly(
      List<CustomReminder> customReminders) async {
    await _cancelCustomReminderIds();
    await scheduleCustomReminders(customReminders);
  }
}
