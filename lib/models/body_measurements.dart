import 'dart:math' as math;

/// Check-in de medidas do mês (peso, altura, circunferências).
class BodyMeasurements {
  BodyMeasurements({
    required this.id,
    required this.monthKey,
    this.weightKg,
    this.heightCm,
    this.waistCm,
    this.hipCm,
    this.chestCm,
    this.armCm,
    this.thighCm,
    this.neckCm,
    this.calfCm,
    this.isMale,
  });

  final String id;
  /// Formato: "yyyy-MM" (ex: "2025-02")
  final String monthKey;
  double? weightKg;
  double? heightCm;
  double? waistCm;
  double? hipCm;
  double? chestCm;
  double? armCm;
  double? thighCm;
  double? neckCm;
  double? calfCm;
  /// true = homem, false = mulher, null = não informado (para fórmula US Navy)
  bool? isMale;

  double? get imc {
    if (weightKg == null || heightCm == null || heightCm! <= 0) return null;
    final heightM = heightCm! / 100;
    return weightKg! / (heightM * heightM);
  }

  /// Percentual de gordura pela Fórmula US Navy (requer sexo e medidas).
  /// Homens: cintura, pescoço, altura. Mulheres: cintura, quadril, pescoço, altura.
  double? get bodyFatPercentage {
    if (heightCm == null || heightCm! <= 0) return null;
    if (isMale == true) {
      if (waistCm == null || neckCm == null) return null;
      final wMinusN = waistCm! - neckCm!;
      if (wMinusN <= 0) return null;
      return 86.010 * math.log(wMinusN) / math.ln10
          - 70.041 * math.log(heightCm!) / math.ln10
          + 36.76;
    }
    if (isMale == false) {
      if (waistCm == null || hipCm == null || neckCm == null) return null;
      final sum = waistCm! + hipCm! - neckCm!;
      if (sum <= 0) return null;
      return 163.205 * math.log(sum) / math.ln10
          - 97.684 * math.log(heightCm!) / math.ln10
          - 78.387;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'monthKey': monthKey,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'waistCm': waistCm,
        'hipCm': hipCm,
        'chestCm': chestCm,
        'armCm': armCm,
        'thighCm': thighCm,
        'neckCm': neckCm,
        'calfCm': calfCm,
        'isMale': isMale,
      };

  factory BodyMeasurements.fromJson(Map<String, dynamic> json) {
    return BodyMeasurements(
      id: json['id'] as String,
      monthKey: json['monthKey'] as String,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      waistCm: (json['waistCm'] as num?)?.toDouble(),
      hipCm: (json['hipCm'] as num?)?.toDouble(),
      chestCm: (json['chestCm'] as num?)?.toDouble(),
      armCm: (json['armCm'] as num?)?.toDouble(),
      thighCm: (json['thighCm'] as num?)?.toDouble(),
      neckCm: (json['neckCm'] as num?)?.toDouble(),
      calfCm: (json['calfCm'] as num?)?.toDouble(),
      isMale: json['isMale'] as bool?,
    );
  }
}
