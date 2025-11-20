import 'package:flutter/material.dart';

class SoftCard extends StatelessWidget {
  final Widget child;

  const SoftCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2E2E2E)
            : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark) ...[
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ]
        ],
      ),
      child: child,
    );
  }
}
