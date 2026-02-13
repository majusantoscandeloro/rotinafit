/// Configuração de lembretes: água, alimentação, atividade.
/// Refeições: Café, Almoço, Lanche, Jantar, Ceia.
class RemindersConfig {
  /// 10 horários a partir das 7h, 200 ml cada = 2 L/dia.
  RemindersConfig({
    this.notificationsEnabled = true,
    this.waterTimes = const [
      '07:00', '08:30', '10:00', '11:30', '13:00', '14:30', '16:00', '17:30', '19:00', '20:30',
    ],
    this.mealBreakfast,
    this.mealLunch,
    this.mealSnack,
    this.mealDinner,
    this.mealSupper,
    this.activityDays = const [1, 3, 5],
    this.activityTime = '07:00',
    this.useSingleActivityTime = true,
    Map<int, String>? activityTimesByDay,
  }) : activityTimesByDay = activityTimesByDay ?? {};

  bool notificationsEnabled;
  List<String> waterTimes;
  String? mealBreakfast;
  String? mealLunch;
  String? mealSnack;
  String? mealDinner;
  String? mealSupper;
  List<int> activityDays; // 1=Mon .. 7=Sun
  String activityTime;
  /// true = um horário para todos os dias; false = horário por dia
  bool useSingleActivityTime;
  /// Dia da semana (1–7) -> horário "HH:mm"
  Map<int, String> activityTimesByDay;

  Map<String, dynamic> toJson() => {
        'notificationsEnabled': notificationsEnabled,
        'waterTimes': waterTimes,
        'mealBreakfast': mealBreakfast,
        'mealLunch': mealLunch,
        'mealSnack': mealSnack,
        'mealDinner': mealDinner,
        'mealSupper': mealSupper,
        'activityDays': activityDays,
        'activityTime': activityTime,
        'useSingleActivityTime': useSingleActivityTime,
        'activityTimesByDay': activityTimesByDay.map((k, v) => MapEntry(k.toString(), v)),
      };

  factory RemindersConfig.fromJson(Map<String, dynamic> json) {
    final byDay = json['activityTimesByDay'] as Map<String, dynamic>?;
    return RemindersConfig(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      waterTimes: (json['waterTimes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [
            '07:00', '08:30', '10:00', '11:30', '13:00', '14:30', '16:00', '17:30', '19:00', '20:30',
          ],
      mealBreakfast: json['mealBreakfast'] as String?,
      mealLunch: json['mealLunch'] as String?,
      mealSnack: json['mealSnack'] as String?,
      mealDinner: json['mealDinner'] as String?,
      mealSupper: json['mealSupper'] as String?,
      activityDays: (json['activityDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [1, 3, 5],
      activityTime: json['activityTime'] as String? ?? '07:00',
      useSingleActivityTime: json['useSingleActivityTime'] as bool? ?? true,
      activityTimesByDay: byDay != null
          ? byDay.map((k, v) => MapEntry(int.parse(k), v as String))
          : {},
    );
  }
}
