import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../localization/app_localizations.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;
  final bool isAdmin;
  final String groupSport; // 👈 NUOVO: Serve per l'icona dinamica

  const EventDetailsPage({
    super.key,
    required this.eventId,
    required this.isAdmin,
    this.groupSport = '', // Opzionale, default vuoto
  });

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  String? _localStatus;

  // Funzione icona dinamica
  IconData _getSportIcon(String sportName) {
    final s = sportName.toLowerCase();
    if (s.contains('pallavolo') || s.contains('volley')) return Icons.sports_volleyball;
    if (s.contains('basket') || s.contains('pallacanestro')) return Icons.sports_basketball;
    if (s.contains('tennis')) return Icons.sports_tennis;
    if (s.contains('rugby')) return Icons.sports_rugby;
    if (s.contains('football')) return Icons.sports_football;
    if (s.contains('golf')) return Icons.sports_golf;
    if (s.contains('baseball')) return Icons.sports_baseball;
    if (s.contains('pallamano')) return Icons.sports_handball;
    return Icons.sports_soccer;
  }

  Future<void> _updateStatus(String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _localStatus = status;
    });

    try {
      await FirebaseFirestore.instance.collection('events').doc(widget.eventId).set({
        'participants': {
          user.uid: status,
        }
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
      }
    }
  }

  Future<void> _deleteEvent() async {
    final loc = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('delete_event_title')),
        content: Text(loc.t('delete_event_confirm')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.t('button_cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Elimina", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance.collection('events').doc(widget.eventId).delete();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('events').doc(widget.eventId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (!snapshot.data!.exists) return Scaffold(appBar: AppBar(), body: const Center(child: Text("Evento non trovato")));

        final eventData = snapshot.data!.data() as Map<String, dynamic>;

        final Timestamp? ts = eventData['startDateTime'];
        final DateTime date = ts?.toDate() ?? DateTime.now();
        final String timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
        final String dateStr = "${date.day}/${date.month}/${date.year}";

        String meetingTimeStr = "";
        if (eventData['meetingDateTime'] != null) {
          final DateTime mt = (eventData['meetingDateTime'] as Timestamp).toDate();
          meetingTimeStr = "${mt.hour.toString().padLeft(2, '0')}:${mt.minute.toString().padLeft(2, '0')}";
        }

        final String matchType = eventData['matchType'] ?? 'friendly';
        final String location = eventData['location'] ?? '-';
        final String meetingPoint = eventData['meetingPoint'] ?? '-';

        // 🔥 LOGICA TITOLO E ICONA (Uguale alla Dashboard)
        final String? customTitle = eventData['title'];
        String title = "Evento";
        IconData headerIcon = Icons.event;
        Color headerColor = colors.primary;

        if (customTitle != null && customTitle.isNotEmpty) {
          // Evento custom (Allenamento)
          title = customTitle;
          headerIcon = Icons.fitness_center;
          headerColor = Colors.teal;
        } else if (matchType == 'home') {
          title = "${eventData['homeTeam']} vs ${eventData['awayTeam']}";
          headerIcon = Icons.home;
          headerColor = Colors.blue;
        } else if (matchType == 'away') {
          title = "${eventData['homeTeam']} vs ${eventData['awayTeam']}";
          headerIcon = Icons.directions_bus;
          headerColor = Colors.orange;
        } else if (matchType == 'tournament') {
          title = "Torneo";
          headerIcon = Icons.emoji_events;
          headerColor = Colors.amber;
        } else {
          // Fallback (Amichevole) con icona sport
          title = "${eventData['homeTeam'] ?? '?'} vs ${eventData['awayTeam'] ?? '?'}";
          headerIcon = _getSportIcon(widget.groupSport);
          headerColor = Colors.green;
        }

        final Map<String, dynamic> participants = eventData['participants'] as Map<String, dynamic>? ?? {};
        final String serverStatus = participants[user?.uid] ?? 'pending';
        final String myStatus = _localStatus ?? serverStatus;

        return Scaffold(
          appBar: AppBar(
            title: Text(loc.t('event_details_title')),
            actions: [
              if (widget.isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _deleteEvent,
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER CON ICONA GRANDE E TITOLO
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: headerColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(headerIcon, size: 48, color: headerColor),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text("$dateStr  •  $timeStr"),
                        backgroundColor: colors.primary.withOpacity(0.05),
                        labelStyle: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 2. DETTAGLI
                _buildDetailRow(context, Icons.location_on, loc.t('label_location'), location), // 👈 Usa label generica

                // Mostra ritrovo solo se c'è
                if (meetingPoint != '-' && meetingPoint.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(context, Icons.place, loc.t('label_meeting_point'), meetingPoint),
                ],

                if (meetingTimeStr.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(context, Icons.access_time, loc.t('label_meeting_time'), meetingTimeStr),
                ],

                const SizedBox(height: 40),

                // 3. PRESENZA
                Text(
                  loc.t('status_title'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateStatus('no'),
                        icon: const Icon(Icons.close),
                        label: Text(loc.t('btn_decline')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: myStatus == 'no' ? Colors.red : Colors.grey.shade300, width: myStatus == 'no' ? 2 : 1),
                          backgroundColor: myStatus == 'no' ? Colors.red.withOpacity(0.1) : null,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus('yes'),
                        icon: const Icon(Icons.check),
                        label: Text(loc.t('btn_accept')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myStatus == 'yes' ? Colors.green : Colors.grey.shade200,
                          foregroundColor: myStatus == 'yes' ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: myStatus == 'yes' ? 2 : 0,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _getStatusText(myStatus, loc),
                    style: TextStyle(
                      color: _getStatusColor(myStatus),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  String _getStatusText(String status, AppLocalizations loc) {
    switch (status) {
      case 'yes': return loc.t('status_going');
      case 'no': return loc.t('status_not_going');
      default: return loc.t('status_pending');
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'yes': return Colors.green;
      case 'no': return Colors.red;
      default: return Colors.orange;
    }
  }
}