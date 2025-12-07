import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import 'create_event_page.dart';
import 'create_recurring_event_page.dart'; // 👈 NUOVO IMPORT

class EventTypeSelectorPage extends StatelessWidget {
  final String groupId;
  final String groupSport;

  const EventTypeSelectorPage({
    super.key,
    required this.groupId,
    required this.groupSport,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('event_select_type_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Opzione 1: EVENTO SINGOLO
            _buildTypeCard(
              context,
              colors,
              title: loc.t('event_type_single'),
              subtitle: loc.t('event_type_single_sub'),
              icon: Icons.event,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateEventPage(
                      groupId: groupId,
                      groupSport: groupSport,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Opzione 2: EVENTO RICORRENTE (ORA ATTIVO)
            _buildTypeCard(
              context,
              colors,
              title: loc.t('event_type_recurring'),
              subtitle: loc.t('event_type_recurring_sub'),
              icon: Icons.update,
              onTap: () {
                // 👇 Naviga alla nuova pagina
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateRecurringEventPage(
                      groupId: groupId,
                      groupSport: groupSport,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(
      BuildContext context,
      ColorScheme colors, {
        required String title,
        required String subtitle,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}