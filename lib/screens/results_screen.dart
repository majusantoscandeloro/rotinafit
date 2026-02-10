import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/body_measurements.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/evolution_config.dart';
import 'measurements_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _openHistory(context),
            tooltip: 'Histórico',
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          final current = app.getCurrentMonthMeasurements();
          final prev = current != null
              ? app.getPreviousMonthMeasurements(current.monthKey)
              : null;
          final imc = current?.imc;

          if (current == null) {
            final theme = Theme.of(context);
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: theme.brightness == Brightness.dark ? null : [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha:0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha:0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.analytics_rounded, size: 48, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Nenhum check-in este mês',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Registre peso, altura e medidas na tela Medidas para ver IMC, evolução e comparação aqui.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MeasurementsScreen()),
                        ),
                        icon: const Icon(Icons.straighten_rounded, size: 20),
                        label: const Text('Ir para Medidas'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openHistory(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(alpha:0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.history_rounded, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Histórico', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                Text('Ver check-ins anteriores', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumo do mês',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'IMC',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      imc != null ? imc.toStringAsFixed(1) : '—',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    if (imc != null)
                                      Text(
                                        _imcCategory(imc),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (current.bodyFatPercentage != null) ...[
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '% gordura',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${current.bodyFatPercentage!.toStringAsFixed(1)}%',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    'US Navy',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!app.canSeeCharts) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Comparação com mês anterior',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.lock, size: 18, color: AppTheme.lockPremium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Desbloqueie o histórico com RotinaFit Premium para ver a evolução mês a mês.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ]
              else ...[
                _EvolutionSection(
                  measurements: app.getMeasurementsForHistory(),
                  current: current,
                  prev: prev,
                ),
              ],
              if (!app.isPremium) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _openPremium(context),
                  icon: const Icon(Icons.star),
                  label: const Text('Ver RotinaFit Premium'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _imcCategory(double imc) {
    if (imc < 18.5) return 'Abaixo do peso';
    if (imc < 25) return 'Peso normal';
    if (imc < 30) return 'Sobrepeso';
    return 'Obesidade';
  }

  void _openHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HistoryScreen(),
      ),
    );
  }

  void _openPremium(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PremiumScreen(),
      ),
    );
  }
}

/// Seção completa de evolução: resumo (diffs), seletor de medida e gráfico.
class _EvolutionSection extends StatefulWidget {
  const _EvolutionSection({
    required this.measurements,
    required this.current,
    required this.prev,
  });

  final List<BodyMeasurements> measurements;
  final BodyMeasurements? current;
  final BodyMeasurements? prev;

  @override
  State<_EvolutionSection> createState() => _EvolutionSectionState();
}

class _EvolutionSectionState extends State<_EvolutionSection> {
  late String _selectedMeasureId;
  bool _showTextView = false;

  @override
  void initState() {
    super.initState();
    _selectedMeasureId = MeasureConfig.defaultMeasure.id;
  }

  String _effectiveMeasureId() {
    final hasData = widget.measurements.any(
      (m) => (MeasureConfig.byId(_selectedMeasureId)?.getValue(m)) != null,
    );
    if (hasData) return _selectedMeasureId;
    for (final config in MeasureConfig.all) {
      if (widget.measurements.any((m) => config.getValue(m) != null)) {
        return config.id;
      }
    }
    return _selectedMeasureId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up_rounded, size: 22, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Evolução',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Compare medidas ao longo do tempo',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _EvolutionSummarySection(
              current: widget.current,
              prev: widget.prev,
            ),
            const SizedBox(height: 24),
            Text(
              'Gráfico por medida',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _MeasureSelectorChips(
              selectedId: _selectedMeasureId,
              measurements: widget.measurements,
              onSelected: (id) => setState(() => _selectedMeasureId = id),
            ),
            const SizedBox(height: 16),
            if (!_showTextView)
              SizedBox(
                height: 220,
                child: _SingleMeasureLineChart(
                  measureId: _effectiveMeasureId(),
                  measurements: widget.measurements,
                ),
              )
            else
              _EvolutionTextView(measurements: widget.measurements),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => _showTextView = !_showTextView),
              icon: Icon(_showTextView ? Icons.bar_chart_rounded : Icons.format_list_bulleted_rounded),
              label: Text(_showTextView ? 'Ver gráfico' : 'Ver em texto'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Visualização em texto: uma linha por medida, com cada valor por data/ordem.
/// Ex: "Peso 1ª = 90 kg - Peso 2ª = 85 kg" e "Cintura 1ª = 80 cm - Cintura 2ª = 78 cm".
class _EvolutionTextView extends StatelessWidget {
  const _EvolutionTextView({required this.measurements});

  final List<BodyMeasurements> measurements;

  static String _formatMonthKey(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (y == null || m == null || m < 1 || m > 12) return monthKey;
    return DateFormat('MMM/yy', 'pt_BR').format(DateTime(y, m));
  }

  static String _formatValue(double value, MeasureConfig config) {
    final decimals = (config.id == 'imc' || config.id == 'bodyFatPercentage') ? 1 : 0;
    final numStr = value.toStringAsFixed(decimals);
    if (config.unit.isEmpty) return numStr;
    if (config.unit == '%') return '$numStr%';
    return '$numStr ${config.unit}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chronological = List<BodyMeasurements>.from(measurements)
      ..sort((a, b) => a.monthKey.compareTo(b.monthKey));
    if (chronological.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Nenhuma medição para exibir.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final lines = <Widget>[];
    for (final config in MeasureConfig.all) {
      final parts = <String>[];
      for (var i = 0; i < chronological.length; i++) {
        final m = chronological[i];
        final value = config.getValue(m);
        if (value == null) continue;
        final label = chronological.length <= 8 ? '${i + 1}ª' : _formatMonthKey(m.monthKey);
        parts.add('${config.label} $label = ${_formatValue(value, config)}');
      }
      if (parts.isEmpty) continue;
      lines.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            parts.join(' – '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    if (lines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Preencha peso e medidas para ver a evolução em texto.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines,
      ),
    );
  }
}

/// Resumo: lista de medidas com diferença (último vs anterior) e destaque visual.
class _EvolutionSummarySection extends StatelessWidget {
  const _EvolutionSummarySection({
    required this.current,
    required this.prev,
  });

  final BodyMeasurements? current;
  final BodyMeasurements? prev;

  @override
  Widget build(BuildContext context) {
    if (current == null || prev == null) {
      return Text(
        'Registre pelo menos dois meses para ver a evolução.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final diffs = <MeasureDiff>[];
    for (final config in MeasureConfig.all) {
      final oldV = config.getValue(prev!);
      final newV = config.getValue(current!);
      if (oldV != null && newV != null) {
        diffs.add(MeasureDiff(
          config: config,
          oldValue: oldV,
          newValue: newV,
          diff: newV - oldV,
        ));
      }
    }

    if (diffs.isEmpty) {
      return Text(
        'Preencha peso e medidas nos dois meses para comparar.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Último mês vs anterior',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: diffs.map((d) => _DiffChip(diff: d)).toList(),
        ),
      ],
    );
  }
}

class _DiffChip extends StatelessWidget {
  const _DiffChip({required this.diff});

  final MeasureDiff diff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg;
    Color fg;
    IconData icon;
    if (diff.isDown) {
      bg = const Color(0xFFDCFCE7); // green light
      fg = const Color(0xFF166534);
      icon = Icons.trending_down_rounded;
    } else if (diff.isUp) {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFB91C1C);
      icon = Icons.trending_up_rounded;
    } else {
      bg = theme.colorScheme.surfaceContainerHighest;
      fg = theme.colorScheme.onSurfaceVariant;
      icon = Icons.remove_rounded;
    }
    if (theme.brightness == Brightness.dark) {
      if (diff.isDown) {
        bg = const Color(0xFF14532D).withValues(alpha: 0.5);
        fg = const Color(0xFF86EFAC);
      } else if (diff.isUp) {
        bg = const Color(0xFF7F1D1D).withValues(alpha: 0.5);
        fg = const Color(0xFFFCA5A5);
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            '${diff.config.label}: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            diff.diffLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chips horizontais para escolher qual medida exibir no gráfico.
class _MeasureSelectorChips extends StatelessWidget {
  const _MeasureSelectorChips({
    required this.selectedId,
    required this.measurements,
    required this.onSelected,
  });

  final String selectedId;
  final List<BodyMeasurements> measurements;
  final void Function(String id) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MeasureConfig.all.map((config) {
          final hasData = measurements.any((m) => config.getValue(m) != null);
          if (!hasData) return const SizedBox.shrink();
          final selected = config.id == selectedId;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(config.label),
              selected: selected,
              onSelected: (_) => onSelected(config.id),
              selectedColor: primary.withValues(alpha: 0.2),
              checkmarkColor: primary,
              showCheckmark: true,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Escala "inteligente" para o eixo Y: poucos rótulos redondos (ex: 0, 50, 100, 150, 200).
/// Evita valores muito próximos (23.8 / 24.0) e adapta ao tipo de medida.
class _ChartYScale {
  final double minY;
  final double maxY;
  final double interval;
  final int decimalPlaces;

  _ChartYScale({required this.minY, required this.maxY, required this.interval, this.decimalPlaces = 0});

  static const List<double> _niceSteps = [1, 2, 5, 10, 20, 25, 50, 100, 200];

  /// Sugestões por medida: (min sugerido, max sugerido) para escala inicial.
  static (double min, double max)? _boundsForMeasure(String measureId) {
    switch (measureId) {
      case 'weightKg':
        return (30, 200);   // peso: 30–200 kg
      case 'imc':
        return (15, 45);    // IMC: 15–45
      case 'bodyFatPercentage':
        return (5, 50);     // % gordura: 5–50%
      case 'waistCm':
      case 'hipCm':
      case 'chestCm':
      case 'armCm':
      case 'thighCm':
      case 'neckCm':
      case 'calfCm':
        return (0, 150);    // circunferências: 0–150 cm
      default:
        return null;
    }
  }

  static _ChartYScale compute(double dataMin, double dataMax, String measureId) {
    const padding = 0.08;
    double range = (dataMax - dataMin).clamp(1.0, double.infinity);
    double minVal = dataMin - range * padding;
    double maxVal = dataMax + range * padding;
    final bounds = _boundsForMeasure(measureId);
    if (bounds != null) {
      minVal = minVal < bounds.$1 ? bounds.$1 : minVal;
      maxVal = maxVal > bounds.$2 ? bounds.$2 : maxVal;
    }
    range = maxVal - minVal;
    if (range <= 0) range = 1;

    // Objetivo: ~5 marcas no eixo (ex: 0, 50, 100, 150, 200). step >= range/4 → no máx. 5 ticks.
    double step = 1;
    for (final s in _niceSteps) {
      if (s >= range / 4) {
        step = s;
        break;
      }
      step = s;
    }
    if (range < 10) {
      for (final x in [0.5, 1.0, 2.0, 5.0]) {
        if (x >= range / 4) {
          step = x;
          break;
        }
      }
    }

    double minY = (minVal / step).floorToDouble() * step;
    double maxY = (maxVal / step).ceilToDouble() * step;
    if (minY == maxY) {
      minY -= step;
      maxY += step;
    }
    int decimals = step >= 1 ? 0 : (step == 0.5 ? 1 : 2);
    // IMC e % gordura: sempre 1 casa decimal (ex: 24.3%, 29.4)
    if (measureId == 'imc' || measureId == 'bodyFatPercentage') decimals = 1;
    return _ChartYScale(minY: minY, maxY: maxY, interval: step, decimalPlaces: decimals);
  }
}

/// Gráfico de linha única para uma medida (reutilizável).
class _SingleMeasureLineChart extends StatelessWidget {
  const _SingleMeasureLineChart({
    required this.measureId,
    required this.measurements,
  });

  final String measureId;
  final List<BodyMeasurements> measurements;

  static String _formatMonthKey(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (y == null || m == null || m < 1 || m > 12) return monthKey;
    final date = DateTime(y, m);
    return DateFormat('MMM/yy', 'pt_BR').format(date);
  }

  /// Unidade no eixo Y: peso → kg, circunferências → cm, % gordura → %.
  static String _yUnitForMeasure(String measureId) {
    if (measureId == 'weightKg') return ' kg';
    if (measureId == 'bodyFatPercentage') return '%';
    if (measureId == 'imc') return '';
    if (measureId == 'waistCm' || measureId == 'hipCm' || measureId == 'chestCm' ||
        measureId == 'armCm' || measureId == 'thighCm' || measureId == 'neckCm' || measureId == 'calfCm') {
      return ' cm';
    }
    return '';
  }

  /// Formata valor para tooltip: 1 casa decimal para IMC e % gordura.
  static String _formatTooltipValue(double value, String measureId) {
    final decimals = (measureId == 'imc' || measureId == 'bodyFatPercentage') ? 1 : 1;
    final numStr = value.toStringAsFixed(decimals);
    return '$numStr${_yUnitForMeasure(measureId)}';
  }

  @override
  Widget build(BuildContext context) {
    final config = MeasureConfig.byId(measureId) ?? MeasureConfig.defaultMeasure;
    final chronological = List<BodyMeasurements>.from(measurements)
      ..sort((a, b) => a.monthKey.compareTo(b.monthKey));
    final withValue = chronological.where((m) => config.getValue(m) != null).toList();
    final spots = <FlSpot>[];
    for (var i = 0; i < withValue.length; i++) {
      spots.add(FlSpot(i.toDouble(), config.getValue(withValue[i])!));
    }

    if (spots.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart_rounded, size: 40, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              'Sem dados para ${config.label}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final values = spots.map((s) => s.y).toList();
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    final yScale = _ChartYScale.compute(dataMin, dataMax, measureId);
    final primaryColor = theme.colorScheme.primary;
    // Linhas da grade visíveis (não brancas): cinza que contrasta com o fundo
    final gridColor = isDark
        ? theme.colorScheme.outline.withValues(alpha: 0.35)
        : theme.colorScheme.outline.withValues(alpha: 0.45);
    // Texto dos eixos sempre legível (Y: medidas, X: datas)
    final axisTextColor = theme.colorScheme.onSurface;
    final isImc = measureId == 'imc';

    final count = withValue.length;
    final maxX = count > 1 ? (count - 1).toDouble() : 1.0;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: yScale.minY,
        maxY: yScale.maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: yScale.interval,
          verticalInterval: 1,
          getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
          getDrawingVerticalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: yScale.interval,
              getTitlesWidget: (value, meta) {
                final decimals = (measureId == 'imc' || measureId == 'bodyFatPercentage')
                    ? 1
                    : yScale.decimalPlaces;
                final text = decimals == 0
                    ? value.round().toString()
                    : value.toStringAsFixed(decimals);
                final suffix = _SingleMeasureLineChart._yUnitForMeasure(measureId);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '$text$suffix',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: axisTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i >= 0 && i < count) {
                  // Sempre um rótulo por medição: 1ª, 2ª, 3ª... (valor1, valor2, valor3)
                  final label = count <= 8
                      ? '${i + 1}ª'
                      : _formatMonthKey(withValue[i].monthKey);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: axisTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: gridColor, width: 1),
            bottom: BorderSide(color: gridColor, width: 1),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final text = _SingleMeasureLineChart._formatTooltipValue(spot.y, measureId);
                return LineTooltipItem(
                  text,
                  theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
        extraLinesData: isImc
            ? ExtraLinesData(
                horizontalLines: [
                  _refLine(18.5, yScale.minY, yScale.maxY, theme),
                  _refLine(25, yScale.minY, yScale.maxY, theme),
                  _refLine(30, yScale.minY, yScale.maxY, theme),
                ],
              )
            : null,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: primaryColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: primaryColor,
                strokeWidth: 2,
                strokeColor: theme.brightness == Brightness.dark ? theme.colorScheme.surface : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.35),
                  primaryColor.withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }

  HorizontalLine _refLine(double y, double minY, double maxY, ThemeData theme) {
    if (y < minY || y > maxY) return HorizontalLine(y: minY - 1, color: Colors.transparent);
    return HorizontalLine(
      y: y,
      color: theme.colorScheme.outline.withValues(alpha: 0.15),
      strokeWidth: 1,
      dashArray: [4, 4],
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          final list = app.getMeasurementsForHistory();
          final locked = !app.canSeeHistory;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (locked)
                Card(
                  color: Color.lerp(Colors.transparent, AppTheme.lockPremium, 0.15)!,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: AppTheme.lockPremium, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Histórico completo disponível no Premium. Aqui você só vê o preview do mês atual.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                const Center(child: Text('Nenhum check-in salvo.'))
              else
                ...list.take(locked ? 1 : list.length).map((m) {
                  return Card(
                    child: ListTile(
                      title: Text(m.monthKey),
                      subtitle: m.imc != null
                          ? Text('IMC: ${m.imc!.toStringAsFixed(1)}')
                          : null,
                      trailing: locked ? const Icon(Icons.lock) : null,
                    ),
                  );
                }),
              if (locked) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PremiumScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.star),
                  label: const Text('Desbloquear com Premium'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RotinaFit Premium')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.lockPremium, size: 40),
                      const SizedBox(width: 12),
                      Text(
                        'Premium (assinatura)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('• Sem anúncios\n• Histórico mês a mês ilimitado\n• Comparação automática (ex: Cintura -2 cm)\n• Gráficos e evolução\n• Backup (em breve)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remoção de anúncios (pagamento único)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Remove apenas os anúncios. O histórico mês a mês continua no Premium.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      // TODO: in_app_purchase - compra única
                      context.read<AppProvider>().setAdsRemoved(true);
                      Navigator.pop(context);
                    },
                    child: const Text('Remover anúncios (simulado)'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              // TODO: in_app_purchase - assinatura
              context.read<AppProvider>().setPremium(true);
              Navigator.pop(context);
            },
            child: const Text('Ativar Premium (simulado)'),
          ),
        ],
      ),
    );
  }
}
