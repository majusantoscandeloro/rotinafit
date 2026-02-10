import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/custom_reminder.dart';

class CustomRemindersScreen extends StatelessWidget {
  const CustomRemindersScreen({super.key});

  static const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lembretes personalizados'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, app, _) {
          final list = app.customReminders;
          final isFree = app.plan == Plan.free;
          final atLimit = isFree && list.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const ListTile(
                title: Text('Seus lembretes'),
                subtitle: Text(
                  'Crie lembretes específicos (ex: Tomar creatina 5g). No plano gratuito você pode ter 1 lembrete e precisa assistir a um vídeo para criar.',
                ),
              ),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Nenhum lembrete. Toque em "Criar lembrete" para adicionar.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...list.map(
                  (r) => _CustomReminderTile(
                    reminder: r,
                    weekdays: weekdays,
                    onTap: () => _showForm(context, reminder: r),
                    onDelete: () => app.removeCustomReminder(r.id),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: atLimit ? null : () => _openCreate(context),
                icon: const Icon(Icons.add),
                label: Text(
                  atLimit
                      ? 'Limite do plano gratuito (1 lembrete)'
                      : 'Criar lembrete',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    final app = context.read<AppProvider>();
    if (!app.canAddCustomReminder) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plano gratuito permite apenas 1 lembrete personalizado.'),
          ),
        );
      }
      return;
    }
    if (app.mustWatchAdToAddCustomReminder) {
      final watched = await app.showRewardedAd();
      if (!context.mounted) return;
      if (!watched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assista ao vídeo até o fim para desbloquear a criação do lembrete.'),
          ),
        );
        return;
      }
    }
    if (!context.mounted) return;
    await _showForm(context, reminder: null);
  }

  Future<void> _showForm(BuildContext context, {CustomReminder? reminder}) async {
    final app = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<CustomReminder?>(
      context: context,
      builder: (ctx) => _CustomReminderFormDialog(
        reminder: reminder,
        weekdays: weekdays,
      ),
    );
    if (result == null || !context.mounted) return;
    if (reminder != null) {
      await app.updateCustomReminder(result);
    } else {
      final err = await app.addCustomReminder(result);
      if (context.mounted && err != null) {
        messenger.showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }
}

class _CustomReminderTile extends StatelessWidget {
  const _CustomReminderTile({
    required this.reminder,
    required this.weekdays,
    required this.onTap,
    required this.onDelete,
  });

  final CustomReminder reminder;
  final List<String> weekdays;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final daysText = reminder.isAllDays
        ? 'Todos os dias'
        : reminder.days.map((d) => weekdays[d - 1]).join(', ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(reminder.name),
        subtitle: Text('$daysText às ${reminder.time}'),
        onTap: onTap,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Excluir lembrete?'),
                content: Text('Remover o lembrete "${reminder.name}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onDelete();
                    },
                    child: const Text('Excluir'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CustomReminderFormDialog extends StatefulWidget {
  const _CustomReminderFormDialog({
    required this.weekdays,
    this.reminder,
  });

  final List<String> weekdays;
  final CustomReminder? reminder;

  @override
  State<_CustomReminderFormDialog> createState() => _CustomReminderFormDialogState();
}

class _CustomReminderFormDialogState extends State<_CustomReminderFormDialog> {
  late TextEditingController _nameController;
  late String _time;
  late List<int> _days;

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _nameController = TextEditingController(text: r?.name ?? '');
    _time = r?.time ?? '07:50';
    _days = r != null ? List.from(r.days) : [1, 2, 3, 4, 5, 6, 7];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final parts = _time.split(':');
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.isNotEmpty ? parts[0] : '7') ?? 7,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '50') ?? 50,
      ),
      initialEntryMode: TimePickerEntryMode.inputOnly,
    );
    if (time != null) {
      setState(() {
        _time =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_days.contains(day)) {
        _days.remove(day);
      } else {
        _days.add(day);
        _days.sort();
      }
    });
  }

  void _selectAllDays() {
    setState(() => _days = [1, 2, 3, 4, 5, 6, 7]);
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome do lembrete.')),
      );
      return;
    }
    final days = _days.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : _days;
    final id = widget.reminder?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    Navigator.pop(context, CustomReminder(id: id, name: name, time: _time, days: days));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.reminder != null ? 'Editar lembrete' : 'Criar lembrete'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do lembrete',
                hintText: 'Ex: Tomar Creatina 5g',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Horário'),
              trailing: TextButton(
                onPressed: _pickTime,
                child: Text(_time),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dias da semana',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Todos os dias'),
                  onPressed: _selectAllDays,
                  backgroundColor: _days.length == 7
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                ...List.generate(7, (i) {
                  final day = i + 1;
                  final selected = _days.contains(day);
                  return FilterChip(
                    label: Text(widget.weekdays[i]),
                    selected: selected,
                    onSelected: (_) => _toggleDay(day),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
