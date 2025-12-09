import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert'; // Per le immagini base64

import '../localization/app_localizations.dart';
import 'user_profile_page.dart'; // Per navigare al profilo

class MemberListPage extends StatelessWidget {
  final String groupId;
  final String groupName;

  const MemberListPage({
    super.key,
    required this.groupId,
    this.groupName = '',
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    // 1. Ascolta il documento del GRUPPO in tempo reale
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .snapshots(),
      builder: (context, snapshot) {
        // Gestione caricamento
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Gestione errori o gruppo non trovato
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Impossibile caricare i membri"));
        }

        // Estrazione dati gruppo
        final groupData = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> membersList = groupData['members'] ?? [];
        final String adminId = groupData['adminId'] ?? '';

        if (membersList.isEmpty) {
          return const Center(child: Text("Nessun membro nel gruppo"));
        }

        // 2. Costruisce la lista visiva
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: membersList.length + 1, // +1 per il titolo
          itemBuilder: (context, index) {

            // Intestazione con il conteggio
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  "${loc.t('members_list_title')} (${membersList.length})",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              );
            }

            // Dati del singolo membro
            final String memberId = membersList[index - 1]; // -1 per compensare il titolo
            final bool isUserAdmin = (memberId == adminId);

            // 3. Widget che scarica i dati dell'utente (Nome, Foto)
            return _MemberTile(
              userId: memberId,
              isAdmin: isUserAdmin,
              loc: loc,
              colors: colors,
            );
          },
        );
      },
    );
  }
}

// 🔥 WIDGET CHE SCARICA I DATI UTENTE
class _MemberTile extends StatelessWidget {
  final String userId;
  final bool isAdmin;
  final AppLocalizations loc;
  final ColorScheme colors;

  const _MemberTile({
    required this.userId,
    required this.isAdmin,
    required this.loc,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isMe = (userId == currentUserId);

    // Scarica i dati dalla collezione 'users'
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        // Dati di default mentre carica
        String displayName = "Caricamento...";
        String role = "";
        String? profileImageBase64;

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          displayName = userData['displayName'] ?? "Utente sconosciuto";
          role = userData['role'] ?? "";
          profileImageBase64 = userData['profileImageBase64'];
        }

        // Aggiungi (Tu) se è l'utente corrente
        if (isMe) displayName += " (Tu)";

        // Gestione immagine profilo
        ImageProvider? imageProvider;
        if (profileImageBase64 != null) {
          try {
            imageProvider = MemoryImage(base64Decode(profileImageBase64));
          } catch (_) {}
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: () {
              // Naviga al profilo completo
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
            // Avatar
            leading: CircleAvatar(
              backgroundColor: colors.primary.withOpacity(0.1),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(Icons.person, color: colors.primary)
                  : null,
            ),
            // Nome
            title: Text(
              displayName,
              style: TextStyle(
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            // Ruolo (sottotitolo)
            subtitle: role.isNotEmpty
                ? Text(role, style: TextStyle(color: Colors.grey.shade600))
                : null,
            // Badge Admin
            trailing: isAdmin
                ? Chip(
              label: Text(
                loc.t('member_admin_badge'), // "Admin"
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            )
                : const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        );
      },
    );
  }
}