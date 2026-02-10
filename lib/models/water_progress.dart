/// Progresso de água no dia (meta em copos; cada copo = 200 ml).
/// No plano free a meta padrão é 2 L (10 copos).
class WaterProgress {
  static const int mlPerGlass = 200;
  /// Meta padrão no free: 2 L = 10 copos de 200 ml
  static const int defaultGoalGlasses = 10;

  WaterProgress({
    required this.dateKey,
    this.goalGlasses = defaultGoalGlasses,
    this.currentGlasses = 0,
  });

  /// "yyyy-MM-dd"
  final String dateKey;
  int goalGlasses;
  int currentGlasses;

  int get currentMl => currentGlasses * mlPerGlass;
  int get goalMl => goalGlasses * mlPerGlass;

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'goalGlasses': goalGlasses,
        'currentGlasses': currentGlasses,
      };

  factory WaterProgress.fromJson(Map<String, dynamic> json) {
    return WaterProgress(
      dateKey: json['dateKey'] as String,
      goalGlasses: json['goalGlasses'] as int? ?? defaultGoalGlasses,
      currentGlasses: json['currentGlasses'] as int? ?? 0,
    );
  }
}
