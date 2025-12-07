import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class MemberListPage extends StatelessWidget {
  final String groupId;
  final String groupName;

  const MemberListPage({
    super.key,
    required this.groupId,
    this.groupName = 'Gruppo',
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    // NOTA: La logica vera per mostrare la lista membri è nel Tab 2 di GroupDashboardPage.
    // Questa pagina serve solo per navigare a essa o per i dettagli.

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.t('members_list_title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Stai visualizzando il tab Membri del gruppo: $groupName",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            // Qui ci sarà la vera lista membri quando implementeremo la navigazione da Info.
          ],
        ),
      ),
    );
  }
}