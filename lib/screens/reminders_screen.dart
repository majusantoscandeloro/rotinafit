import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/reminders_config.dart';
import '../theme/app_theme.dart';
import '../widgets/home_card.dart';
import 'water_screen.dart';
import 'meals_screen.dart';
import 'activity_screen.dart';
import 'custom_reminders_screen.dart';

/// Tela hub: lista Água, Alimentação, Atividade e Lembretes personalizados.
/// Entrada: ícone no cabeçalho da Home. Ícones e cards iguais ao dashboard.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  Future<void> _setNotificationsEnabled(bool value) async {
    final app = context.read<AppProvider>();
    final config = RemindersConfig(
      notificationsEnabled: value,
      waterTimes: app.reminders.waterTimes,
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Lembretes'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          final config = app.reminders;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              SwitchListTile(
                title: const Text('Ativar notificações'),
                subtitle: const Text(
                  'Lembretes de água, refeições, atividade e personalizados',
                ),
                value: config.notificationsEnabled,
                onChanged: (v) => _setNotificationsEnabled(v),
              ),
              const SizedBox(height: 16),
              HomeCard(
                emoji: '💧',
                icon: Icons.water_drop_rounded,
                title: 'Água',
                subtitle: 'Meta do dia e horários dos lembretes',
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
                subtitle: 'Café, almoço, lanche, jantar, ceia',
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
                subtitle: 'Dias e horários para lembrete de exercício',
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
                  MaterialPageRoute(builder: (_) => const CustomRemindersScreen()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
