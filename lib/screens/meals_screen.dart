import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/reminders_config.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  bool _loaded = false;
  late String? mealBreakfast;
  late String? mealLunch;
  late String? mealSnack;
  late String? mealDinner;
  late String? mealSupper;

  void _loadFromProvider() {
    if (_loaded) return;
    _loaded = true;
    final config = context.read<AppProvider>().reminders;
    mealBreakfast = config.mealBreakfast;
    mealLunch = config.mealLunch;
    mealSnack = config.mealSnack;
    mealDinner = config.mealDinner;
    mealSupper = config.mealSupper;
  }

  Future<void> _save() async {
    final app = context.read<AppProvider>();
    final config = RemindersConfig(
      notificationsEnabled: app.reminders.notificationsEnabled,
      waterTimes: app.reminders.waterTimes,
      mealBreakfast: mealBreakfast,
      mealLunch: mealLunch,
      mealSnack: mealSnack,
      mealDinner: mealDinner,
      mealSupper: mealSupper,
      activityDays: app.reminders.activityDays,
      activityTime: app.reminders.activityTime,
      useSingleActivityTime: app.reminders.useSingleActivityTime,
      activityTimesByDay: app.reminders.activityTimesByDay,
    );
    await app.updateReminders(config);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horários salvos com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickTime(String title, String? current, ValueChanged<String?> onPicked) async {
    final parts = (current ?? '12:00').split(':');
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.isNotEmpty ? parts[0] : '12') ?? 12,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      ),
      initialEntryMode: TimePickerEntryMode.inputOnly,
    );
    if (time != null) {
      final s =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      onPicked(s);
      setState(() {});
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadFromProvider();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alimentação'),
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
            title: Text('Horários das refeições'),
            subtitle: Text('Defina em que horário deseja ser lembrado de cada refeição'),
          ),
          const SizedBox(height: 8),
          _MealTile(
            label: 'Café',
            time: mealBreakfast,
            onTap: () => _pickTime('Café', mealBreakfast, (v) => mealBreakfast = v),
          ),
          _MealTile(
            label: 'Almoço',
            time: mealLunch,
            onTap: () => _pickTime('Almoço', mealLunch, (v) => mealLunch = v),
          ),
          _MealTile(
            label: 'Lanche',
            time: mealSnack,
            onTap: () => _pickTime('Lanche', mealSnack, (v) => mealSnack = v),
          ),
          _MealTile(
            label: 'Jantar',
            time: mealDinner,
            onTap: () => _pickTime('Jantar', mealDinner, (v) => mealDinner = v),
          ),
          _MealTile(
            label: 'Ceia',
            time: mealSupper,
            onTap: () => _pickTime('Ceia', mealSupper, (v) => mealSupper = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('Salvar horários'),
          ),
        ],
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final String? time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label),
        trailing: TextButton(
          onPressed: onTap,
          child: Text(time ?? 'Definir'),
        ),
      ),
    );
  }
}
