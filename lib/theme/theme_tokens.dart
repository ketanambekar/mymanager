import 'package:flutter/material.dart';

extension ThemeTokens on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;

  Color get appBg => cs.surface;
  Color get panel => cs.surfaceContainerLowest;
  Color get panelMuted => cs.surfaceContainerLow;
  Color get border => cs.outlineVariant;
  Color get title => cs.onSurface;
  Color get subtitle => cs.onSurfaceVariant;
  Color get accent => cs.primary;
}
