import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/reminders_config.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _loaded = false;
  late List<int> activityDays;
  late String activityTime;
  late bool useSingleActivityTime;
  late Map<int, String> activityTimesByDay;

  static const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  void _loadFromProvider() {
    if (_loaded) return;
    _loaded = true;
    final config = context.read<AppProvider>().reminders;
    activityDays = List.from(config.activityDays);
    activityTime = config.activityTime;
    useSingleActivityTime = config.useSingleActivityTime;
    activityTimesByDay = Map.from(config.activityTimesByDay);
  }

  Future<void> _save() async {
    final app = context.read<AppProvider>();
    final config = RemindersConfig(
      notificationsEnabled: app.reminders.notificationsEnabled,
      waterTimes: app.reminders.waterTimes,
      mealBreakfast: app.reminders.mealBreakfast,
      mealLunch: app.reminders.mealLunch,
      mealSnack: app.reminders.mealSnack,
      mealDinner: app.reminders.mealDinner,
      mealSupper: app.reminders.mealSupper,
      activityDays: activityDays,
      activityTime: activityTime,
      useSingleActivityTime: useSingleActivityTime,
      activityTimesByDay: activityTimesByDay,
    );
    await app.updateReminders(config);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickTime(String title, String? current, ValueChanged<String?> onPicked) async {
    final parts = (current ?? '07:00').split(':');
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.isNotEmpty ? parts[0] : '7') ?? 7,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      ),
      initialEntryMode: TimePickerEntryMode.inputOnly,
    );
    if (time != null) {
      final s =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      onPicked(s);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadFromProvider();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atividade física'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Salvar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            title: Text('Lembrete de atividade'),
            subtitle: Text('Escolha os dias e horários para ser lembrado de se exercitar'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Mesmo horário todos os dias'),
            value: useSingleActivityTime,
            onChanged: (v) => setState(() => useSingleActivityTime = v),
          ),
          if (useSingleActivityTime) ...[
            const SizedBox(height: 8),
            const Text('Dias da semana', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final day = i + 1;
                final selected = activityDays.contains(day);
                return FilterChip(
                  label: Text(weekdays[i]),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        activityDays.add(day);
                      } else {
                        activityDays.remove(day);
                      }
                      activityDays.sort();
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Horário'),
              trailing: TextButton(
                onPressed: () => _pickTime(
                  'Horário atividade',
                  activityTime,
                  (v) => activityTime = v ?? activityTime,
                ),
                child: Text(activityTime),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text('Horário por dia', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ...List.generate(7, (i) {
              final day = i + 1;
              final time = activityTimesByDay[day] ?? '07:00';
              return ListTile(
                title: Text(weekdays[i]),
                trailing: TextButton(
                  onPressed: () => _pickTime(
                    weekdays[i],
                    time,
                    (v) {
                      if (v != null) activityTimesByDay[day] = v;
                      setState(() {});
                    },
                  ),
                  child: Text(time),
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('Salvar lembretes'),
          ),
        ],
      ),
    );
  }
}
