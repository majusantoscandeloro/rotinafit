import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/reminders_config.dart';
import '../utils/responsive.dart';
import 'results_screen.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  bool _loaded = false;
  late List<String> _waterTimes;

  static const Color _waterAccent = Color(0xFF0EA5E9);

  void _loadFromProvider() {
    if (_loaded) return;
    _loaded = true;
    _waterTimes = List.from(context.read<AppProvider>().reminders.waterTimes);
  }

  Future<void> _saveHorarios() async {
    final app = context.read<AppProvider>();
    final config = RemindersConfig(
      notificationsEnabled: app.reminders.notificationsEnabled,
      waterTimes: _waterTimes,
      mealBreakfast: app.reminders.mealBreakfast,
      mealLunch: app.reminders.mealLunch,
      mealSnack: app.reminders.mealSnack,
      mealDinner: app.reminders.mealDinner,
      mealSupper: app.reminders.mealSupper,
      activityDays: app.reminders.activityDays,
      activityTime: app.reminders.activityTime,
      useSingleActivityTime: app.reminders.useSingleActivityTime,
      activityTimesByDay: app.reminders.activityTimesByDay,
    );
    await app.updateReminders(config);
    if (mounted) setState(() {});
  }

  String _formatL(int ml) {
    if (ml >= 1000) {
      final l = ml / 1000;
      return l == l.roundToDouble() ? '${l.toInt()} L' : '${l.toStringAsFixed(1)} L';
    }
    return '$ml ml';
  }

  Future<void> _openAlterarMeta(BuildContext context, AppProvider app) async {
    if (app.isPremium) {
      _showMetaDialog(context, app);
      return;
    }
    if (app.canChangeWaterGoalForFree) {
      _showMetaDialog(context, app);
      return;
    }
    // Free já usou a alteração grátis de hoje: oferecer vídeo, premium ou cancelar
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar meta de água'),
        content: const Text(
          'Você já alterou a meta hoje. Assista a um vídeo para liberar mais uma alteração ou assine o Premium para alterar quando quiser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancelar'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'premium'),
            child: const Text('Assinar Premium'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'video'),
            child: const Text('Assistir vídeo e liberar'),
          ),
        ],
      ),
    );
    if (!mounted || choice == null || choice == 'cancel') return;
    if (choice == 'premium') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
      if (!mounted) return;
      if (context.read<AppProvider>().isPremium) {
        _showMetaDialog(context, context.read<AppProvider>());
      }
      return;
    }
    if (choice == 'video') {
      final earned = await app.showRewardedAd();
      if (!mounted) return;
      if (!earned) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assista o vídeo até o fim para liberar a alteração.'),
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    _showMetaDialog(context, app);
  }

  void _showMetaDialog(BuildContext context, AppProvider app) {
    int goal = app.getTodayWater().goalGlasses;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final ml = goal * 200;
          final litros = ml >= 1000 ? '${(ml / 1000).toStringAsFixed(1)} L' : '$ml ml';
          return AlertDialog(
            title: const Text('Meta de água por dia'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Cada copo = 200 ml. Meta padrão: 2 L (10 copos).'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                      icon: const Icon(Icons.remove),
                      onPressed: () => setState(() => goal = (goal - 1).clamp(1, 20)),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$goal copos', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text(litros, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    IconButton.filled(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => goal = (goal + 1).clamp(1, 20)),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  app.setWaterGoal(goal);
                  if (!app.isPremium) app.recordWaterGoalChange();
                  Navigator.pop(context);
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _loadFromProvider();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Água'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          final water = app.getTodayWater();
          final progress = water.goalGlasses > 0
              ? (water.currentGlasses / water.goalGlasses).clamp(0.0, 1.0)
              : 0.0;
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Hero card with circular progress
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            _waterAccent.withValues(alpha:0.2),
                            _waterAccent.withValues(alpha:0.08),
                          ]
                        : [
                            _waterAccent.withValues(alpha:0.15),
                            _waterAccent.withValues(alpha:0.05),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _waterAccent.withValues(alpha:0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hoje',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${water.currentGlasses} / ${water.goalGlasses}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'copos · ${_formatL(water.currentMl)} / ${_formatL(water.goalMl)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: _waterAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: responsiveSize(context, compact: 72, expanded: 96),
                          height: responsiveSize(context, compact: 72, expanded: 96),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 6,
                                backgroundColor: _waterAccent.withValues(alpha:0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(_waterAccent),
                              ),
                              Icon(Icons.water_drop_rounded, size: responsiveSize(context, compact: 28, expanded: 36), color: _waterAccent),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: _waterAccent.withValues(alpha:0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(_waterAccent),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: water.currentGlasses > 0
                                ? () => app.removeWaterGlass()
                                : null,
                            icon: const Icon(Icons.remove_rounded, size: 22),
                            label: const Text('Menos'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _waterAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: () => app.addWaterGlass(),
                            icon: const Icon(Icons.add_rounded, size: 22),
                            label: const Text('+ 1 copo'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _waterAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: water.currentGlasses < water.goalGlasses
                            ? () => app.completeWaterGoal()
                            : null,
                        style: FilledButton.styleFrom(
                          foregroundColor: _waterAccent,
                          backgroundColor: _waterAccent.withValues(alpha:0.15),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Marcar meta inteira'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _openAlterarMeta(context, app),
                      icon: const Icon(Icons.tune_rounded, size: 20),
                      label: const Text('Alterar meta de água'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        foregroundColor: _waterAccent,
                        side: BorderSide(color: _waterAccent.withValues(alpha:0.5)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Horários dos lembretes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Em quais horários deseja ser lembrado de beber água',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._waterTimes.map((t) => Chip(
                        label: Text(t),
                        deleteIcon: Icon(Icons.close_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                        onDeleted: () {
                          setState(() {
                            _waterTimes.remove(t);
                            _saveHorarios();
                          });
                        },
                      )),
                  ActionChip(
                    avatar: Icon(Icons.add_rounded, size: 18, color: theme.colorScheme.onPrimary),
                    label: const Text('Adicionar horário'),
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        initialEntryMode: TimePickerEntryMode.inputOnly,
                        builder: (context, child) {
                          return MediaQuery(
                            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        final s =
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        setState(() {
                          _waterTimes.add(s);
                          _waterTimes.sort();
                          _saveHorarios();
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
