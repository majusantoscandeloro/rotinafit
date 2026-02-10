import '../models/body_measurements.dart';

/// Configuração de uma medida para gráfico e resumo de evolução.
/// Centraliza label, unidade e extração do valor para reuso e expansão futura.
class MeasureConfig {
  const MeasureConfig({
    required this.id,
    required this.label,
    required this.unit,
    required this.getValue,
  });

  final String id;
  final String label;
  final String unit;
  final double? Function(BodyMeasurements m) getValue;

  /// Todas as medidas disponíveis para evolução (ordem de exibição).
  static const List<MeasureConfig> all = [
    MeasureConfig(
      id: 'weightKg',
      label: 'Peso',
      unit: 'kg',
      getValue: _getWeight,
    ),
    MeasureConfig(
      id: 'imc',
      label: 'IMC',
      unit: '',
      getValue: _getImc,
    ),
    MeasureConfig(
      id: 'waistCm',
      label: 'Cintura',
      unit: 'cm',
      getValue: _getWaist,
    ),
    MeasureConfig(
      id: 'hipCm',
      label: 'Quadril',
      unit: 'cm',
      getValue: _getHip,
    ),
    MeasureConfig(
      id: 'chestCm',
      label: 'Peito',
      unit: 'cm',
      getValue: _getChest,
    ),
    MeasureConfig(
      id: 'armCm',
      label: 'Braço',
      unit: 'cm',
      getValue: _getArm,
    ),
    MeasureConfig(
      id: 'thighCm',
      label: 'Coxa',
      unit: 'cm',
      getValue: _getThigh,
    ),
    MeasureConfig(
      id: 'neckCm',
      label: 'Pescoço',
      unit: 'cm',
      getValue: _getNeck,
    ),
    MeasureConfig(
      id: 'calfCm',
      label: 'Panturrilha',
      unit: 'cm',
      getValue: _getCalf,
    ),
    MeasureConfig(
      id: 'bodyFatPercentage',
      label: '% gordura',
      unit: '%',
      getValue: _getBodyFat,
    ),
  ];

  static double? _getWeight(BodyMeasurements m) => m.weightKg;
  static double? _getImc(BodyMeasurements m) => m.imc;
  static double? _getWaist(BodyMeasurements m) => m.waistCm;
  static double? _getHip(BodyMeasurements m) => m.hipCm;
  static double? _getChest(BodyMeasurements m) => m.chestCm;
  static double? _getArm(BodyMeasurements m) => m.armCm;
  static double? _getThigh(BodyMeasurements m) => m.thighCm;
  static double? _getNeck(BodyMeasurements m) => m.neckCm;
  static double? _getCalf(BodyMeasurements m) => m.calfCm;
  static double? _getBodyFat(BodyMeasurements m) => m.bodyFatPercentage;

  static MeasureConfig? byId(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static MeasureConfig get defaultMeasure => all.first;
}

/// Resultado da comparação entre dois check-ins para uma medida.
class MeasureDiff {
  MeasureDiff({
    required this.config,
    required this.oldValue,
    required this.newValue,
    required this.diff,
  });

  final MeasureConfig config;
  final double oldValue;
  final double newValue;
  final double diff;

  bool get isDown => diff < 0;
  bool get isUp => diff > 0;
  bool get isStable => diff == 0;

  String get diffLabel {
    if (diff == 0) return 'manteve';
    final sign = diff > 0 ? '+' : '';
    if (config.unit.isEmpty) return '$sign${diff.toStringAsFixed(1)}';
    if (config.unit == '%') return '$sign${diff.toStringAsFixed(1)}%';
    return '$sign${diff.toStringAsFixed(1)} ${config.unit}';
  }
}
