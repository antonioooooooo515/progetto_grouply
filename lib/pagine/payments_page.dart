import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    return Center(
      child: Text(
        loc.t('payments_placeholder'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          color: colors.onSurface,
        ),
      ),
    );
  }
}