import 'package:flutter/material.dart';

import '../theme/neon_colors.dart';

/// Back-chevron + title row for screens reached via `Navigator.push` that
/// otherwise have no on-screen way to leave mid-activity -- this app uses
/// no `AppBar` anywhere, so `SentenceBuilderScreen`/`ExamScreen` previously
/// had zero exit affordance until their post-session summary widget.
class ExitTopBar extends StatelessWidget {
  const ExitTopBar({required this.title, required this.onExit, super.key});

  final String title;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onExit,
          icon: const Icon(Icons.arrow_back, color: NeonColors.textPrimary),
          tooltip: 'Voltar',
        ),
        Text(
          title,
          style: const TextStyle(
            color: NeonColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
