import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../localization/app_localizations.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  static const String kPaymentsCollection = 'payment_requests';

  List<String> _safeStringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const <String>[];
  }

  Map<String, dynamic> _safeMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  bool _isPaidValue(dynamic statusRaw) {
    final s = (statusRaw ?? '').toString().toLowerCase().trim();
    return s == 'paid' || s == 'ok' || s == 'done' || s == 'true';
  }

  bool _isPaidForUser(Map<String, dynamic> data, String uid) {
    final statusByUser = _safeMap(data['statusByUser']);
    final perUser = _safeMap(statusByUser[uid]);
    final status = perUser['status'];
    return _isPaidValue(status);
  }

  int _countPaidTargets(Map<String, dynamic> data, List<String> targets) {
    int paid = 0;
    final statusByUser = _safeMap(data['statusByUser']);
    for (final t in targets) {
      final perUser = _safeMap(statusByUser[t]);
      final status = perUser['status'];
      if (_isPaidValue(status)) paid++;
    }
    return paid;
  }

  String _formatAmount(AppLocalizations loc, dynamic raw) {
    double? value;
    if (raw is num) value = raw.toDouble();
    if (raw is String) value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null) return '';

    final fmt = NumberFormat.currency(
      locale: loc.locale.toString(),
      symbol: '€',
      decimalDigits: 2,
    );
    return fmt.format(value);
  }

  int _createdAtMillis(Map<String, dynamic> data) {
    final ts = data['createdAt'];
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;
    return 0;
  }

  Future<void> _confirmAndDeletePayment(
      BuildContext context, {
        required String paymentId,
        required String groupName,
      }) async {
    final loc = AppLocalizations.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('payment_delete_title')),
        content: Text(
          loc.t('payment_delete_confirm', params: {'groupName': groupName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('button_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              loc.t('button_delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection(kPaymentsCollection)
        .doc(paymentId)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('payment_deleted_success'))),
      );
    }
  }

  /// ✅ ADMIN: segna l'intera richiesta come "pagata" (tutti i recipients -> paid)
  Future<void> _setPaymentPaidByAdmin(
      BuildContext context, {
        required String paymentId,
      }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref =
    FirebaseFirestore.instance.collection(kPaymentsCollection).doc(paymentId);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() as Map<String, dynamic>? ?? {};

        final recipients = _safeStringList(data['recipients']);
        if (recipients.isEmpty) return;

        final statusByUser = _safeMap(data['statusByUser']);
        final now = Timestamp.now();

        for (final uid in recipients) {
          final perUser = _safeMap(statusByUser[uid]);
          statusByUser[uid] = {
            ...perUser,
            'status': 'paid',
            'paidAt': perUser['paidAt'] ?? now,
          };
        }

        tx.update(ref, {'statusByUser': statusByUser});
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final colors = Theme.of(context).colorScheme;

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('fab_option_payment')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .where('members', arrayContains: user.uid)
            .snapshots(),
        builder: (context, groupsSnapshot) {
          if (groupsSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Errore: ${groupsSnapshot.error}"),
              ),
            );
          }
          if (groupsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!groupsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = groupsSnapshot.data!.docs;

          final groupIds = <String>[];
          final groupNames = <String, String>{};
          final groupAdmins = <String, String>{};

          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;
            groupIds.add(d.id);
            groupNames[d.id] = (data['name'] ?? 'Gruppo').toString();
            groupAdmins[d.id] = (data['adminId'] ?? '').toString();
          }

          final safeGroupIds = groupIds.take(10).toList();

          if (safeGroupIds.isEmpty) {
            return Center(child: Text(loc.t('home_no_groups')));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(kPaymentsCollection)
                .where('groupId', whereIn: safeGroupIds)
                .snapshots(),
            builder: (context, paySnapshot) {
              if (paySnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text("Errore: ${paySnapshot.error}"),
                  ),
                );
              }
              if (paySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!paySnapshot.hasData || paySnapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    loc.t('home_no_payments'),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }

              final activeDocs = paySnapshot.data!.docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['isActive'] == true;
              }).toList();

              activeDocs.sort((a, b) {
                final da = a.data() as Map<String, dynamic>;
                final db = b.data() as Map<String, dynamic>;
                return _createdAtMillis(db).compareTo(_createdAtMillis(da));
              });

              if (activeDocs.isEmpty) {
                return Center(
                  child: Text(
                    loc.t('home_no_payments'),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activeDocs.length,
                itemBuilder: (context, index) {
                  final doc = activeDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final paymentId = doc.id;

                  final groupId = (data['groupId'] ?? '').toString();
                  final groupName =
                  (data['groupName'] ?? groupNames[groupId] ?? 'Gruppo')
                      .toString();

                  final isAdminOfGroup = groupAdmins[groupId] == user.uid;

                  final note = (data['note'] ?? '').toString();
                  final amountStr = _formatAmount(loc, data['amount']);

                  final createdAtTs = data['createdAt'] as Timestamp?;
                  final createdAtStr = createdAtTs == null
                      ? ''
                      : DateFormat('dd MMM HH:mm', loc.locale.toString())
                      .format(createdAtTs.toDate());

                  final dueTs = data['dueDate'] as Timestamp?;
                  final dueStr = dueTs == null
                      ? ''
                      : DateFormat('dd/MM/yyyy', loc.locale.toString())
                      .format(dueTs.toDate());

                  final recipients = _safeStringList(data['recipients']);

                  // ✅ L'utente vede lo stato personale SOLO se è tra i recipients
                  final bool isRecipient = recipients.contains(user.uid);

                  final paidCount = _countPaidTargets(data, recipients);
                  final total = recipients.length;
                  final pct = total == 0 ? 0.0 : (paidCount / total);

                  final bool fullyPaid = (total > 0 && paidCount >= total);

                  String statusLabel;
                  IconData statusIcon;

                  if (total == 0 || paidCount == 0) {
                    statusLabel = loc.t('payment_status_pending');
                    statusIcon = Icons.hourglass_top_rounded;
                  } else if (paidCount >= total) {
                    statusLabel = loc.t('payment_status_paid');
                    statusIcon = Icons.verified_rounded;
                  } else {
                    statusLabel = loc.t('payment_status_partial');
                    statusIcon = Icons.timelapse_rounded;
                  }

                  final chipBg = statusLabel == loc.t('payment_status_paid')
                      ? Colors.green.withOpacity(0.12)
                      : (statusLabel == loc.t('payment_status_partial')
                      ? Colors.orange.withOpacity(0.12)
                      : Colors.grey.withOpacity(0.12));

                  final chipFg = statusLabel == loc.t('payment_status_paid')
                      ? Colors.green.shade700
                      : (statusLabel == loc.t('payment_status_partial')
                      ? Colors.orange.shade800
                      : Colors.grey.shade700);

                  final recipientNames = (data['recipientNames'] is Map)
                      ? (data['recipientNames'] as Map)
                      .map((k, v) => MapEntry(k.toString(), v.toString()))
                      : <String, String>{};

                  final myPaid = isRecipient ? _isPaidForUser(data, user.uid) : false;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HEADER
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      groupName.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (createdAtStr.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          createdAtStr,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // CHIP + MENU (admin)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: chipBg,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                          color: chipFg.withOpacity(0.35)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon,
                                            size: 16, color: chipFg),
                                        const SizedBox(width: 6),
                                        Text(
                                          statusLabel,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: chipFg,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isAdminOfGroup) ...[
                                    const SizedBox(width: 6),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_horiz),
                                      onSelected: (value) async {
                                        if (value == 'delete') {
                                          await _confirmAndDeletePayment(
                                            context,
                                            paymentId: paymentId,
                                            groupName: groupName,
                                          );
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.delete,
                                                  color: Colors.red),
                                              const SizedBox(width: 10),
                                              Text(
                                                loc.t('button_delete'),
                                                style: const TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // NOTE + AMOUNT
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  note.isEmpty
                                      ? loc.t('payment_default_title')
                                      : note,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (amountStr.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                Text(
                                  amountStr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          if (dueStr.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.event,
                                    size: 16, color: Colors.grey.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  "${loc.t('payment_due_date_label')}: $dueStr",
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 12),

                          // PROGRESS GLOBALE
                          if (total > 0) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "$paidCount / $total",
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],

                          // ✅ STATO PERSONALE: SOLO se NON admin e SOLO se è recipient
                          if (!isAdminOfGroup && isRecipient) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: myPaid
                                    ? Colors.green.withOpacity(0.12)
                                    : Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    myPaid
                                        ? Icons.check_circle
                                        : Icons.hourglass_top,
                                    size: 16,
                                    color: myPaid
                                        ? Colors.green.shade700
                                        : Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    myPaid
                                        ? loc.t('payment_status_paid')
                                        : loc.t('payment_status_pending'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: myPaid
                                          ? Colors.green.shade700
                                          : Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // DETTAGLI DESTINATARI SOLO ADMIN
                          if (isAdminOfGroup &&
                              recipients.isNotEmpty &&
                              recipientNames.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              loc.t('payment_recipients_label'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: recipients.map((uid) {
                                final name = recipientNames[uid] ?? 'Utente';
                                final paid = _isPaidForUser(data, uid);
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: paid
                                        ? Colors.green.withOpacity(0.12)
                                        : Colors.grey.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        paid
                                            ? Icons.check_circle
                                            : Icons.hourglass_top,
                                        size: 14,
                                        color: paid
                                            ? Colors.green.shade700
                                            : Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: paid
                                              ? Colors.green.shade700
                                              : Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],

                          // PULSANTE ADMIN: "SEGNA PAGATO"
                          if (isAdminOfGroup) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: IconButton(
                                tooltip: fullyPaid
                                    ? loc.t('payment_status_paid')
                                    : loc.t('payment_status_pending'),
                                onPressed: fullyPaid
                                    ? null
                                    : () => _setPaymentPaidByAdmin(
                                  context,
                                  paymentId: paymentId,
                                ),
                                icon: Icon(
                                  fullyPaid
                                      ? Icons.check_circle
                                      : Icons.check_circle_outline,
                                  size: 26,
                                  color: fullyPaid
                                      ? Colors.green.shade700
                                      : colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
