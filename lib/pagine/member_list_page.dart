import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import '../localization/app_localizations.dart';
import 'user_profile_page.dart';

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

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text(loc.t('members_error')));
        }

        final groupData = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> membersList = groupData['members'] ?? [];
        final String adminId = groupData['adminId'] ?? '';

        if (membersList.isEmpty) {
          return Center(child: Text(loc.t('no_members')));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: membersList.length + 1,
          itemBuilder: (context, index) {

            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  "${loc.t('members_list_title')} (${membersList.length})",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              );
            }

            final String memberId = membersList[index - 1];
            final bool isUserAdmin = (memberId == adminId);

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

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String displayName = loc.t('loading');
        String role = "";
        String? profileImageBase64;

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          displayName = userData['displayName'] ?? loc.t('unknown_user');
          role = userData['role'] ?? "";
          profileImageBase64 = userData['profileImageBase64'];
        }

        if (isMe) displayName += loc.t('you');

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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                    userId: userId,
                    userName: displayName.replaceAll(loc.t('you'), ""),
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
            title: Text(
              displayName,
              style: TextStyle(
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            subtitle: role.isNotEmpty
                ? Text(role, style: TextStyle(color: Colors.grey.shade600))
                : null,
            // Badge Admin
            trailing: isAdmin
                ? Chip(
              label: Text(
                loc.t('member_admin_badge'),
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