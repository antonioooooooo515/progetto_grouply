import 'package:flutter/material.dart';

class GroupPage extends StatelessWidget {
  const GroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        'Sezione Gruppo\n(qui gestirai i tuoi team)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          color: colors.onSurface,
        ),
      ),
    );
  }
}
