import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Per copiare il codice
import 'dart:convert'; // Per decodificare la foto base64

import '../localization/app_localizations.dart';

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

class _GroupDashboardPageState extends State<GroupDashboardPage> {

  // Copia codice
  void _copyCode(String code, AppLocalizations loc) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.t('info_code_copied'))),
    );
  }

  // 🔥 NUOVA FUNZIONE: Esci dal gruppo
  Future<void> _leaveGroup() async {
    final loc = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Chiedi conferma
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

    // 2. Esegui operazione su Firebase
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

      // 3. Torna alla lista gruppi
      Navigator.of(context).pop();

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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(groupName),
          bottom: TabBar(
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
          children: [
            // --- TAB 1: BACHECA ---
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mark_chat_unread_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    loc.t('board_empty'),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            ),

            // --- TAB 2: MEMBRI ---
            _buildMembersTab(loc, colors),

            // --- TAB 3: INFO ---
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          loc.t('info_invite_code_label'),
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          inviteCode,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _copyCode(inviteCode, loc),
                          icon: const Icon(Icons.copy, size: 18),
                          label: Text(loc.t('info_copy_code')),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
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

                // 🔥 PULSANTE ESCI DAL GRUPPO
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab(AppLocalizations loc, ColorScheme colors) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        // Controllo di sicurezza se il gruppo è stato cancellato o dati mancanti
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
}

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

        if (isMe) {
          displayName += " (Tu)";
        }

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
            leading: CircleAvatar(
              backgroundColor: colors.primary.withOpacity(0.1),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(Icons.person, color: colors.primary)
                  : null,
            ),
            title: Text(
              displayName,
              style: TextStyle(
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: role.isNotEmpty ? Text(role) : null,
            trailing: isAdmin
                ? Chip(
              label: Text(
                loc.t('member_admin_badge'),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
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