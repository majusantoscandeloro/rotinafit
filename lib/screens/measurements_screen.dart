import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/body_measurements.dart';

class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _hipCtrl = TextEditingController();
  final _chestCtrl = TextEditingController();
  final _armCtrl = TextEditingController();
  final _thighCtrl = TextEditingController();
  final _neckCtrl = TextEditingController();
  final _calfCtrl = TextEditingController();
  bool? _isMale;
  bool _hasCalculatedFat = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrent());
  }

  void _loadCurrent() {
    final app = context.read<AppProvider>();
    final m = app.getCurrentMonthMeasurements();
    if (m != null) {
      _weightCtrl.text = m.weightKg?.toString() ?? '';
      _heightCtrl.text = m.heightCm?.toString() ?? '';
      _waistCtrl.text = m.waistCm?.toString() ?? '';
      _hipCtrl.text = m.hipCm?.toString() ?? '';
      _chestCtrl.text = m.chestCm?.toString() ?? '';
      _armCtrl.text = m.armCm?.toString() ?? '';
      _thighCtrl.text = m.thighCm?.toString() ?? '';
      _neckCtrl.text = m.neckCm?.toString() ?? '';
      _calfCtrl.text = m.calfCm?.toString() ?? '';
      _isMale = m.isMale;
      _hasCalculatedFat = m.bodyFatPercentage != null;
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _waistCtrl.dispose();
    _hipCtrl.dispose();
    _chestCtrl.dispose();
    _armCtrl.dispose();
    _thighCtrl.dispose();
    _neckCtrl.dispose();
    _calfCtrl.dispose();
    super.dispose();
  }

  double? _parse(String? s) {
    if (s == null || s.isEmpty) return null;
    return double.tryParse(s.replaceAll(',', '.'));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final app = context.read<AppProvider>();
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    // Cada salvamento gera um novo check-in (não sobrescreve o mês).
    final id = '${monthKey}_${now.millisecondsSinceEpoch}';
    final m = BodyMeasurements(
      id: id,
      monthKey: monthKey,
      weightKg: _parse(_weightCtrl.text),
      heightCm: _parse(_heightCtrl.text),
      waistCm: _parse(_waistCtrl.text),
      hipCm: _parse(_hipCtrl.text),
      chestCm: _parse(_chestCtrl.text),
      armCm: _parse(_armCtrl.text),
      thighCm: _parse(_thighCtrl.text),
      neckCm: _parse(_neckCtrl.text),
      calfCm: _parse(_calfCtrl.text),
      isMale: _isMale,
    );
    await app.saveMeasurements(m);
    await app.showInterstitialOnSave();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in do mês salvo!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat.yMMMM('pt_BR').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medidas e composição'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Check-in de $monthName',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildField('Peso (kg)', _weightCtrl, isRequired: true),
            _buildField('Altura (cm)', _heightCtrl, isRequired: true),
            _ImcCard(
              weightCtrl: _weightCtrl,
              heightCtrl: _heightCtrl,
            ),
            const SizedBox(height: 16),
            _buildField('Cintura (cm)', _waistCtrl),
            _buildField('Quadril (cm)', _hipCtrl),
            _buildField('Peito (cm)', _chestCtrl),
            _buildField('Braço (cm)', _armCtrl),
            _buildField('Coxa (cm)', _thighCtrl),
            _buildField('Pescoço (cm)', _neckCtrl),
            _buildField('Panturrilha (cm)', _calfCtrl),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Percentual de gordura (Fórmula US Navy)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Homens: cintura, pescoço e altura. Mulheres: cintura, quadril, pescoço e altura.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool?>(
              segments: const [
                ButtonSegment(value: true, label: Text('Homem'), icon: Icon(Icons.male)),
                ButtonSegment(value: false, label: Text('Mulher'), icon: Icon(Icons.female)),
                ButtonSegment(value: null, label: Text('Não informar')),
              ],
              selected: {_isMale},
              onSelectionChanged: (Set<bool?> selected) {
                setState(() {
                  _isMale = selected.first;
                  _hasCalculatedFat = false;
                });
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                await context.read<AppProvider>().showInterstitial();
                if (mounted) setState(() => _hasCalculatedFat = true);
              },
              icon: const Icon(Icons.calculate),
              label: const Text('Calcular % gordura'),
            ),
            const SizedBox(height: 16),
            _BodyFatCard(
              showResult: _hasCalculatedFat,
              isMale: _isMale,
              heightCm: _parse(_heightCtrl.text),
              waistCm: _parse(_waistCtrl.text),
              hipCm: _parse(_hipCtrl.text),
              neckCm: _parse(_neckCtrl.text),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Salvar check-in do mês'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: isRequired
            ? (v) {
                if (v == null || v.isEmpty) return 'Preencha';
                if (double.tryParse(v.replaceAll(',', '.')) == null) {
                  return 'Número inválido';
                }
                return null;
              }
            : null,
      ),
    );
  }
}

String _imcCategory(double imc) {
  if (imc < 18.5) return 'Abaixo do peso';
  if (imc < 25) return 'Peso normal';
  if (imc < 30) return 'Sobrepeso';
  return 'Obesidade';
}

class _ImcCard extends StatefulWidget {
  const _ImcCard({
    required this.weightCtrl,
    required this.heightCtrl,
  });

  final TextEditingController weightCtrl;
  final TextEditingController heightCtrl;

  @override
  State<_ImcCard> createState() => _ImcCardState();
}

class _ImcCardState extends State<_ImcCard> {
  @override
  void initState() {
    super.initState();
    widget.weightCtrl.addListener(_onUpdate);
    widget.heightCtrl.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.weightCtrl.removeListener(_onUpdate);
    widget.heightCtrl.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final weight = _parse(widget.weightCtrl.text);
    final height = _parse(widget.heightCtrl.text);
    final imc = (weight != null && height != null && height > 0)
        ? weight / ((height / 100) * (height / 100))
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'IMC',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Índice de Massa Corporal',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (imc == null)
              Text(
                'Preencha peso e altura acima para ver o IMC.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Text(
                imc.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _imcCategory(imc),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

double? _parse(String? s) {
  if (s == null || s.isEmpty) return null;
  return double.tryParse(s.replaceAll(',', '.'));
}

class _BodyFatCard extends StatelessWidget {
  const _BodyFatCard({
    required this.showResult,
    required this.isMale,
    required this.heightCm,
    required this.waistCm,
    required this.hipCm,
    required this.neckCm,
  });

  final bool showResult;
  final bool? isMale;
  final double? heightCm;
  final double? waistCm;
  final double? hipCm;
  final double? neckCm;

  @override
  Widget build(BuildContext context) {
    if (!showResult) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resultado',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Selecione o sexo acima e toque em "Calcular % gordura" para ver o percentual.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final m = BodyMeasurements(
      id: '',
      monthKey: '',
      heightCm: heightCm,
      waistCm: waistCm,
      hipCm: hipCm,
      neckCm: neckCm,
      isMale: isMale,
    );
    final fat = m.bodyFatPercentage;
    if (fat == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resultado',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                isMale == null
                    ? 'Selecione o sexo (Homem ou Mulher) para calcular.'
                    : isMale == true
                        ? 'Preencha cintura, pescoço e altura para calcular.'
                        : 'Preencha cintura, quadril, pescoço e altura para calcular.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultado',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${fat.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fórmula US Navy – ${isMale == true ? "Homens" : "Mulheres"}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
