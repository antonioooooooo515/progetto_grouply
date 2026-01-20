import 'package:flutter/material.dart';

class WelcomeHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const WelcomeHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.groups_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(
          icon,
          size: 80,
          color: const Color(0xFFE91E63),
        ),
        const SizedBox(height: 16),

        Text(
          title,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: colors.onSurface,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colors.onSurface.withOpacity(0.75),
          ),
        ),
      ],
    );
  }
}
