import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.progress,
    this.progressLabel,
    this.accentColor,
    this.icon,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double? progress;
  final String? progressLabel;
  /// Optional accent color for the icon container. Defaults to theme primary.
  final Color? accentColor;
  /// Optional IconData to show instead of emoji for a more polished look.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = accentColor ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? theme.cardTheme.color ?? theme.colorScheme.surfaceContainerHigh
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha:0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: responsiveSize(context, compact: 52, expanded: 72),
                    height: responsiveSize(context, compact: 52, expanded: 72),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: icon != null
                        ? Icon(icon, size: responsiveSize(context, compact: 26, expanded: 36), color: accent)
                        : Text(emoji, style: TextStyle(fontSize: responsiveSize(context, compact: 26, expanded: 36))),
                  ),
                  SizedBox(width: responsiveSize(context, compact: 16, expanded: 20)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha:0.6),
                  ),
                ],
              ),
              if (progress != null && progress! >= 0) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress!.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha:0.08)
                        : accent.withValues(alpha:0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                if (progressLabel != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    progressLabel!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
