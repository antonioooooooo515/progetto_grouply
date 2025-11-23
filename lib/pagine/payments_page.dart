import 'package:flutter/material.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        'Sezione Pagamenti\n(qui gestirai abbonamenti, quote, ecc.)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          color: colors.onSurface,
        ),
      ),
    );
  }
}
