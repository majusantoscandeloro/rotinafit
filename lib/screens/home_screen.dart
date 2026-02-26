import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../services/att_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_version.dart';
import '../utils/responsive.dart';
import '../widgets/home_card.dart';
import 'reminders_screen.dart';
import 'water_screen.dart';
import 'meals_screen.dart';
import 'activity_screen.dart';
import 'custom_reminders_screen.dart';
import 'measurements_screen.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // App Tracking Transparency (iOS 14+): pede permissão após o usuário ver a Home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AttService.requestTrackingIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon/icon.png',
              height: responsiveSize(context, compact: 32, expanded: 48),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            SizedBox(width: responsiveSize(context, compact: 10, expanded: 14)),
            const Text('RotinaFit'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RemindersScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => context.read<AuthProvider>().signOut(),
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

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
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
                          if (!app.isPremium) ...[
                            const SizedBox(height: 12),
                            HomeCard(
                              emoji: '⭐',
                              icon: Icons.workspace_premium_rounded,
                              title: 'Assinar Premium',
                              subtitle: 'Sem anúncios + recursos completos',
                              accentColor: AppTheme.lockPremium,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PremiumScreen(),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Center(
                            child: Text(
                              'Versão $appVersion',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              if (app.showAds)
                SafeArea(
                  top: false,
                  child: app.getBannerWidget(),
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
