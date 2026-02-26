import 'package:flutter/material.dart';

/// Breakpoint a partir do qual consideramos tablet (ex.: iPad).
/// Em telas menores (iPhone) os tamanhos ficam no valor [compact].
const double kTabletBreakpoint = 600.0;

/// Largura máxima do conteúdo em tablet (iPad). Evita cards/listas ultra-largos.
/// No iPhone a tela já é menor que isso, então não altera o layout.
const double kMaxContentWidth = 640.0;

/// Retorna um tamanho que escala do [compact] no celular para [expanded] no tablet.
/// No iPhone o valor permanece [compact]; no iPad aumenta para não ficar pequeno.
///
/// [expanded] opcional: se null, usa 1.5 * compact.
double responsiveSize(
  BuildContext context, {
  required double compact,
  double? expanded,
}) {
  final w = MediaQuery.sizeOf(context).width;
  if (w <= kTabletBreakpoint) return compact;
  final exp = expanded ?? compact * 1.5;
  const maxW = 900.0;
  final t = ((w - kTabletBreakpoint) / (maxW - kTabletBreakpoint)).clamp(0.0, 1.0);
  return compact + (exp - compact) * t;
}

/// Indica se a tela atual é considerada tablet (ex.: iPad).
bool isTablet(BuildContext context) {
  return MediaQuery.sizeOf(context).width > kTabletBreakpoint;
}
