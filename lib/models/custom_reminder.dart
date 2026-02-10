/// Lembrete personalizado criado pelo usuário (ex: Tomar Creatina 5g).
/// Horário em HH:mm; dias 1=Seg .. 7=Dom; todos os dias = [1,2,3,4,5,6,7].
class CustomReminder {
  CustomReminder({
    required this.id,
    required this.name,
    required this.time,
    required this.days,
  });

  final String id;
  String name;
  String time; // "HH:mm"
  /// Dias da semana (1=Seg .. 7=Dom). Com os 7 = todos os dias.
  List<int> days;

  bool get isAllDays => days.length == 7;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'time': time,
        'days': days,
      };

  factory CustomReminder.fromJson(Map<String, dynamic> json) {
    final daysList = json['days'] as List<dynamic>?;
    return CustomReminder(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      time: json['time'] as String? ?? '08:00',
      days: daysList?.map((e) => e as int).toList() ?? [1, 2, 3, 4, 5, 6, 7],
    );
  }

  CustomReminder copyWith({
    String? id,
    String? name,
    String? time,
    List<int>? days,
  }) {
    return CustomReminder(
      id: id ?? this.id,
      name: name ?? this.name,
      time: time ?? this.time,
      days: days ?? List.from(this.days),
    );
  }
}
