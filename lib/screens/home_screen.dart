import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/home_card.dart';
import 'debug_user_mode_screen.dart';
import 'reminders_screen.dart';
import 'water_screen.dart';
import 'meals_screen.dart';
import 'activity_screen.dart';
import 'custom_reminders_screen.dart';
import 'measurements_screen.dart';
import 'results_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('RotinaFit'),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.science_outlined),
              tooltip: 'Trocar modo de teste (Free/Premium)',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DebugUserModeScreen(),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RemindersScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          if (app.loading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando sua rotina...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          final water = app.getTodayWater();
          final waterProgress = water.goalGlasses > 0
              ? (water.currentGlasses / water.goalGlasses).clamp(0.0, 1.0)
              : 0.0;
          final current = app.getCurrentMonthMeasurements();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá!',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sua rotina em um só lugar',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    HomeCard(
                      emoji: '💧',
                      icon: Icons.water_drop_rounded,
                      title: 'Água',
                      subtitle: 'Meta do dia (copo = 200 ml)',
                      progress: waterProgress,
                      progressLabel:
                          '${water.currentGlasses}/${water.goalGlasses} copos · ${_formatL(water.currentMl)} / ${_formatL(water.goalMl)}',
                      accentColor: const Color(0xFF0EA5E9),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WaterScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    HomeCard(
                      emoji: '🍽️',
                      icon: Icons.restaurant_rounded,
                      title: 'Alimentação',
                      subtitle: app.reminders.mealBreakfast != null ||
                              app.reminders.mealLunch != null ||
                              app.reminders.mealSnack != null ||
                              app.reminders.mealDinner != null ||
                              app.reminders.mealSupper != null
                          ? 'Lembretes ativos'
                          : 'Configurar lembretes',
                      accentColor: const Color(0xFFF59E0B),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MealsScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    HomeCard(
                      emoji: '🏃',
                      icon: Icons.directions_run_rounded,
                      title: 'Atividade física',
                      subtitle: (app.reminders.useSingleActivityTime
                              ? app.reminders.activityDays.isNotEmpty
                              : app.reminders.activityTimesByDay.isNotEmpty)
                          ? 'Lembretes ativos'
                          : 'Configurar lembretes',
                      accentColor: AppTheme.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ActivityScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    HomeCard(
                      emoji: '🔔',
                      icon: Icons.notifications_active_rounded,
                      title: 'Lembretes personalizados',
                      subtitle: app.customReminders.isEmpty
                          ? 'Criar lembrete (ex: Tomar creatina 5g)'
                          : '${app.customReminders.length} lembrete(s)',
                      accentColor: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CustomRemindersScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    HomeCard(
                      emoji: '📏',
                      icon: Icons.straighten_rounded,
                      title: 'Medidas',
                      subtitle: current != null
                          ? 'Cintura, quadril, braço...'
                          : 'Registrar medidas',
                      accentColor: const Color(0xFF10B981),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MeasurementsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    HomeCard(
                      emoji: '📊',
                      icon: Icons.analytics_rounded,
                      title: 'Resultados',
                      subtitle: current != null
                          ? 'Ver evolução, comparar meses e gráficos'
                          : 'Registre medidas para ver resultados',
                      accentColor: const Color(0xFF6366F1),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ResultsScreen()),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (app.showAds)
                      Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Anúncio',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatL(int ml) {
    if (ml >= 1000) {
      final l = ml / 1000;
      return l == l.roundToDouble()
          ? '${l.toInt()} L'
          : '${l.toStringAsFixed(1)} L';
    }
    return '$ml ml';
  }
}
