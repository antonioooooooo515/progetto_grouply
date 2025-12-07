import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; // Necessario per formattazione data

import '../localization/app_localizations.dart';
import 'event_type_selector_page.dart';
import 'user_profile_page.dart';
import 'event_details_page.dart';
import 'member_list_page.dart';
import '../widgets/soft_card.dart';

class GroupDashboardPage extends StatefulWidget {
  final String groupId;
  final Map<String, dynamic> groupData;

  const GroupDashboardPage({
    super.key,
    required this.groupId,
    required this.groupData,
  });

  @override
  State<GroupDashboardPage> createState() => _GroupDashboardPageState();
}

class _GroupDashboardPageState extends State<GroupDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyCode(String code, AppLocalizations loc) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.t('info_code_copied'))),
    );
  }

  void _showAddOptions(AppLocalizations loc, ColorScheme colors) {
    final String currentSport = widget.groupData['sport'] ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // OPZIONE: EVENTO
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: colors.primary.withOpacity(0.1),
                  child: const Icon(Icons.calendar_today, color: Colors.blue),
                ),
                title: Text(loc.t('fab_option_event'), style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventTypeSelectorPage(
                        groupId: widget.groupId,
                        groupSport: currentSport,
                      ),
                    ),
                  );
                },
              ),

              // OPZIONE: POST (Placeholder)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: const Icon(Icons.article, color: Colors.orange),
                ),
                title: Text(loc.t('fab_option_post'), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(loc.t('fab_option_post_sub')),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post in sviluppo")));
                },
              ),

              // OPZIONE: SONDAGGIO (Placeholder)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.withOpacity(0.1),
                  child: const Icon(Icons.poll, color: Colors.purple),
                ),
                title: Text(loc.t('fab_option_poll'), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(loc.t('fab_option_poll_sub')),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sondaggio in sviluppo")));
                },
              ),

              // OPZIONE: PAGAMENTO (Placeholder)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: const Icon(Icons.euro, color: Colors.green),
                ),
                title: Text(loc.t('fab_option_payment'), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(loc.t('fab_option_payment_sub')),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pagamenti in sviluppo")));
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _leaveGroup() async {
    final loc = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('dialog_leave_title')),
        content: Text(loc.t('dialog_leave_content')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('button_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              loc.t('info_leave_group'),
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'members': FieldValue.arrayRemove([user.uid]),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('leave_success'))),
      );
      Navigator.popUntil(context, ModalRoute.withName('/home')); // Torna alla home principale
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('leave_error', params: {'error': e.toString()}))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    final String groupName = widget.groupData['name'] ?? 'Gruppo';
    final String inviteCode = widget.groupData['inviteCode'] ?? '???';
    final String sport = widget.groupData['sport'] ?? '';
    final String adminId = widget.groupData['adminId'] ?? '';
    final bool isAdmin = (_currentUserId == adminId);

    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.primary,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurface.withOpacity(0.6),
          tabs: [
            Tab(text: loc.t('tab_board'), icon: const Icon(Icons.dashboard_outlined)),
            Tab(text: loc.t('tab_members'), icon: const Icon(Icons.people_outline)),
            Tab(text: loc.t('tab_info'), icon: const Icon(Icons.info_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. BACHECA (BOARD)
          _buildBoardTab(loc, colors, isAdmin, sport),

          // 2. MEMBRI
          _buildMembersTab(loc, colors),

          // 3. INFO
          _buildInfoTab(loc, colors, inviteCode, sport),
        ],
      ),

      floatingActionButton: (isAdmin && _tabController.index == 0)
          ? FloatingActionButton(
        onPressed: () => _showAddOptions(loc, colors),
        backgroundColor: colors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  // --- WIDGET TAB 1: BACHECA ---
  Widget _buildBoardTab(AppLocalizations loc, ColorScheme colors, bool isAdmin, String sport) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('groupId', isEqualTo: widget.groupId)
          .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.now()) // Solo eventi futuri
          .orderBy('startDateTime', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Errore: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  loc.t('board_empty'),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final events = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final eventDoc = events[index];
            final eventData = eventDoc.data() as Map<String, dynamic>;

            return _EventCard(
              eventId: eventDoc.id,
              event: eventData,
              colors: colors,
              isAdmin: isAdmin,
              groupSport: sport, // PASSIAMO LO SPORT
            );
          },
        );
      },
    );
  }

  // --- WIDGET TAB 2: MEMBRI ---
  Widget _buildMembersTab(AppLocalizations loc, ColorScheme colors) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox();

        final members = data['members'] as List<dynamic>? ?? [];
        final adminId = data['adminId'];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              "${loc.t('members_list_title')} (${members.length})",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...members.map((memberId) {
              return _MemberCard(
                userId: memberId,
                isAdmin: memberId == adminId,
                loc: loc,
                colors: colors,
              );
            }).toList(),
          ],
        );
      },
    );
  }

  // --- WIDGET TAB 3: INFO ---
  Widget _buildInfoTab(AppLocalizations loc, ColorScheme colors, String inviteCode, String sport) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.t('info_invite_code_label'), style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(
                inviteCode,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface),
              ),
              TextButton.icon(
                onPressed: () => _copyCode(inviteCode, loc),
                icon: const Icon(Icons.copy, size: 18),
                label: Text(loc.t('info_copy_code')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: const Icon(Icons.sports_soccer),
          title: Text(loc.t('info_sport')),
          trailing: Text(
            sport,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const Divider(height: 40),
        ListTile(
          leading: const Icon(Icons.exit_to_app, color: Colors.red),
          title: Text(
            loc.t('info_leave_group'),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: _leaveGroup,
        ),
      ],
    );
  }
}

// 🔥 WIDGET CARD EVENTO (AGGIORNATA per Allenamento)
class _EventCard extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> event;
  final ColorScheme colors;
  final bool isAdmin;
  final String groupSport;

  const _EventCard({
    required this.eventId,
    required this.event,
    required this.colors,
    required this.isAdmin,
    required this.groupSport,
  });

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

  @override
  Widget build(BuildContext context) {
    final type = event['matchType'] ?? 'friendly';
    final location = event['location'] ?? 'Posizione non specificata';
    final timestamp = event['startDateTime'] as Timestamp?;
    final DateTime? date = timestamp?.toDate();

    // 🔥 PRIORITÀ 1: Titolo Custom (Allenamenti, eventi ricorrenti)
    final String? customTitle = event['title'];

    IconData iconData;
    Color iconColor;
    String title;

    if (customTitle != null && customTitle.isNotEmpty) {
      // Caso 1: Evento con titolo personalizzato (Allenamento/Recurring)
      iconData = Icons.fitness_center; // 👈 Icona più adatta all'allenamento
      iconColor = Colors.teal;
      title = customTitle;
    } else if (type == 'home') {
      iconData = Icons.home;
      iconColor = Colors.blue;
      title = "${event['homeTeam']} vs ${event['awayTeam']}";
    } else if (type == 'away') {
      iconData = Icons.directions_bus;
      iconColor = Colors.orange;
      title = "${event['homeTeam']} vs ${event['awayTeam']}";
    } else if (type == 'tournament') {
      iconData = Icons.emoji_events;
      iconColor = Colors.amber;
      title = "Torneo";
    } else {
      // Fallback
      iconData = _getSportIcon(groupSport);
      iconColor = Colors.green;
      title = "${event['homeTeam'] ?? 'Squadra'} vs ${event['awayTeam'] ?? 'Squadra'}";
    }

    String dateStr = "--/--";
    String timeStr = "--:--";
    if (date != null) {
      dateStr = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
      timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsPage(
                eventId: eventId,
                isAdmin: isAdmin,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colonna Data/Ora
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(timeStr, style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Dettagli Evento
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(iconData, size: 20, color: iconColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

// Widget Membro (rimane invariato)
class _MemberCard extends StatelessWidget {
  final String userId;
  final bool isAdmin;
  final AppLocalizations loc;
  final ColorScheme colors;

  const _MemberCard({
    required this.userId,
    required this.isAdmin,
    required this.loc,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isMe = (userId == currentUserId);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String displayName = "Caricamento...";
        String? profileImageBase64;
        String role = "";

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          displayName = userData['displayName'] ?? "Utente senza nome";
          profileImageBase64 = userData['profileImageBase64'];
          role = userData['role'] ?? "";
        }

        if (isMe) displayName += " (Tu)";

        ImageProvider? imageProvider;
        if (profileImageBase64 != null) {
          try {
            imageProvider = MemoryImage(base64Decode(profileImageBase64));
          } catch (_) {}
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                    userId: userId,
                    userName: displayName.replaceAll(" (Tu)", ""),
                  ),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: colors.primary.withOpacity(0.1),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(Icons.person, color: colors.primary)
                  : null,
            ),
            title: Text(displayName, style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
            subtitle: role.isNotEmpty ? Text(role) : null,
            trailing: isAdmin
                ? Chip(
              label: Text(loc.t('member_admin_badge'), style: const TextStyle(fontSize: 10, color: Colors.white)),
              backgroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            )
                : null,
          ),
        );
      },
    );
  }
}