import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../widgets/soft_card.dart';
import 'create_payment_request_page.dart';

class PaymentSelectRecipientsPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String adminId;

  const PaymentSelectRecipientsPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.adminId,
  });

  @override
  State<PaymentSelectRecipientsPage> createState() =>
      _PaymentSelectRecipientsPageState();
}

class _PaymentSelectRecipientsPageState
    extends State<PaymentSelectRecipientsPage> {
  final Set<String> _selectedUserIds = {};

  void _toggle(String uid) {
    setState(() {
      if (_selectedUserIds.contains(uid)) {
        _selectedUserIds.remove(uid);
      } else {
        _selectedUserIds.add(uid);
      }
    });
  }

  void _selectAll(List<String> ids) {
    setState(() {
      _selectedUserIds
        ..clear()
        ..addAll(ids);
    });
  }

  void _clearAll() {
    setState(() => _selectedUserIds.clear());
  }

  Future<void> _goNext(List<_MemberInfo> members) async {
    final loc = AppLocalizations.of(context);

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('payment_no_recipients_error'))),
      );
      return;
    }

    final selected =
    members.where((m) => _selectedUserIds.contains(m.uid)).toList();

    final Map<String, String> selectedNames = {
      for (final m in selected) m.uid: m.displayName,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePaymentRequestPage(
          groupId: widget.groupId,
          groupName: widget.groupName,
          adminId: widget.adminId,
          recipients: selectedNames,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isAdmin = currentUserId != null && currentUserId == widget.adminId;

    // SOLO ADMIN
    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.t('payment_admin_only_error')),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      });
      return const SizedBox();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('payment_select_people_title')),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .snapshots(),
        builder: (context, groupSnap) {
          if (groupSnap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Errore: ${groupSnap.error}"),
              ),
            );
          }
          if (groupSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!groupSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final groupData = groupSnap.data!.data() as Map<String, dynamic>?;
          final List<dynamic> membersDyn =
          (groupData?['members'] ?? []) as List<dynamic>;
          final membersIdsRaw = membersDyn.map((e) => e.toString()).toList();

          // Escludo me stesso dalla selezione
          final memberIds =
          membersIdsRaw.where((id) => id != currentUserId).toList();

          if (memberIds.isEmpty) {
            return Center(
              child: Text(
                loc.t('payment_no_recipients_error'),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            );
          }

          return FutureBuilder<List<_MemberInfo>>(
            future: _loadMembers(memberIds),
            builder: (context, membersSnap) {
              if (membersSnap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text("Errore: ${membersSnap.error}"),
                  ),
                );
              }
              if (membersSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!membersSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final members = membersSnap.data!;
              final allIds = members.map((m) => m.uid).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.t('payment_select_people_subtitle'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),

                          // ✅ FIX OVERFLOW: uso Wrap invece di Row
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () => _selectAll(allIds),
                                icon: const Icon(Icons.select_all),
                                label: Text(loc.t('payment_select_all')),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _clearAll,
                                icon: const Icon(Icons.clear),
                                label: Text(loc.t('payment_clear_all')),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colors.surfaceVariant.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  "${_selectedUserIds.length}/${members.length}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      itemCount: members.length,
                      itemBuilder: (context, i) {
                        final m = members[i];
                        final selected = _selectedUserIds.contains(m.uid);

                        final isMemberAdmin = m.uid == widget.adminId;

                        ImageProvider? img;
                        if (m.photoBase64 != null) {
                          try {
                            img = MemoryImage(base64Decode(m.photoBase64!));
                          } catch (_) {}
                        }

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: selected
                                  ? colors.primary
                                  : Colors.grey.shade200,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _toggle(m.uid),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor:
                                    colors.primary.withOpacity(0.1),
                                    backgroundImage: img,
                                    child: img == null
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                m.displayName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isMemberAdmin)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: colors.primary
                                                        .withOpacity(0.12),
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        999),
                                                  ),
                                                  child: Text(
                                                    loc.t('label_admin'),
                                                    style: TextStyle(
                                                      color: colors.primary,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          m.email ?? "",
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    selected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color:
                                    selected ? colors.primary : Colors.grey,
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                          members.isEmpty ? null : () => _goNext(members),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            loc.t('payment_next'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<List<_MemberInfo>> _loadMembers(List<String> ids) async {
    final List<_MemberInfo> out = [];
    for (final uid in ids) {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data() as Map<String, dynamic>?;

      out.add(
        _MemberInfo(
          uid: uid,
          displayName: (data?['displayName'] ?? 'Utente').toString(),
          photoBase64: data?['profileImageBase64']?.toString(),
          email: data?['email']?.toString(),
        ),
      );
    }

    out.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return out;
  }
}

class _MemberInfo {
  final String uid;
  final String displayName;
  final String? photoBase64;
  final String? email;

  _MemberInfo({
    required this.uid,
    required this.displayName,
    this.photoBase64,
    this.email,
  });
}
