import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_version.dart';
import 'home_screen.dart';

/// Tela inicial de teste (apenas em debug) para simular cada tipo de usuário:
/// Free (com anúncios) ou Premium.
class DebugUserModeScreen extends StatelessWidget {
  const DebugUserModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo de teste'),
        backgroundColor: Colors.grey.shade800,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Versão $appVersion',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Selecione o tipo de usuário para testar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _ModeCard(
                title: 'Free (com anúncios)',
                subtitle:
                    'Anúncios visíveis, 1 lembrete personalizado (com vídeo), IMC 1x/mês, sem histórico completo',
                icon: Icons.sell_outlined,
                onTap: () => _selectMode(context, premium: false),
              ),
              const SizedBox(height: 12),
              _ModeCard(
                title: 'Premium',
                subtitle:
                    'Sem anúncios, histórico completo, gráficos e comparação mês a mês. Assinatura mensal ou anual.',
                icon: Icons.star,
                color: AppTheme.lockPremium,
                onTap: () => _selectMode(context, premium: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectMode(BuildContext context, {required bool premium}) async {
    final app = context.read<AppProvider>();
    await app.setPremium(premium);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;

    return Material(
      color: theme.cardColor,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cardColor.withValues(alpha: 0.2),
                child: Icon(icon, color: cardColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}