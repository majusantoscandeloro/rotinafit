import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/reminders_config.dart';
import 'water_screen.dart';
import 'meals_screen.dart';
import 'activity_screen.dart';
import 'custom_reminders_screen.dart';

/// Tela hub: lista Água, Alimentação, Atividade e Lembretes personalizados.
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lembretes'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          final config = app.reminders;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Ativar notificações'),
                subtitle: const Text('Lembretes de água, refeições, atividade e personalizados'),
                value: config.notificationsEnabled,
                onChanged: (v) => _setNotificationsEnabled(v),
              ),
              const Divider(height: 24),
              _HubTile(
                emoji: '💧',
                title: 'Água',
                subtitle: 'Meta do dia e horários dos lembretes',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WaterScreen()),
                ),
              ),
              _HubTile(
                emoji: '🍽️',
                title: 'Alimentação',
                subtitle: 'Café, almoço, lanche, jantar, ceia',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MealsScreen()),
                ),
              ),
              _HubTile(
                emoji: '🏃',
                title: 'Atividade física',
                subtitle: 'Dias e horários para lembrete de exercício',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActivityScreen()),
                ),
              ),
              _HubTile(
                emoji: '🔔',
                title: 'Lembretes personalizados',
                subtitle: app.customReminders.isEmpty
                    ? 'Criar lembrete (ex: Tomar creatina 5g)'
                    : '${app.customReminders.length} lembrete(s)',
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

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Text(emoji, style: const TextStyle(fontSize: 28)),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.primary),
        onTap: onTap,
      ),
    );
  }
}
