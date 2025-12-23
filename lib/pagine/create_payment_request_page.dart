import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../localization/app_localizations.dart';
import '../widgets/soft_card.dart';

class CreatePaymentRequestPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String adminId;

  /// uid -> displayName
  final Map<String, String> recipients;

  const CreatePaymentRequestPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.adminId,
    required this.recipients,
  });

  @override
  State<CreatePaymentRequestPage> createState() =>
      _CreatePaymentRequestPageState();
}

class _CreatePaymentRequestPageState extends State<CreatePaymentRequestPage> {
  static const String kCollection = 'payment_requests';

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _dueDate;
  bool _loading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? _parseAmount(String raw) {
    final s = raw.trim().replaceAll(',', '.');
    final v = double.tryParse(s);
    if (v == null) return null;
    if (v <= 0) return null;
    return v;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _dueDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('toast_login_required'))),
      );
      return;
    }

    // SOLO ADMIN
    if (user.uid != widget.adminId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.t('payment_admin_only_error')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('payment_no_recipients_error'))),
      );
      return;
    }

    final amount = _parseAmount(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('payment_invalid_amount_error'))),
      );
      return;
    }

    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('payment_missing_fields_error'))),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final recipients = widget.recipients.keys.toList();

      final Map<String, dynamic> statusByUser = {
        for (final uid in recipients)
          uid: {
            'status': 'pending',
            'paidAt': null,
          }
      };

      await FirebaseFirestore.instance.collection(kCollection).add({
        'groupId': widget.groupId,
        'groupName': widget.groupName,

        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),

        'amount': amount,
        'note': note,

        'dueDate': _dueDate == null ? null : Timestamp.fromDate(_dueDate!),

        // destinatari
        'recipients': recipients,
        'recipientNames': widget.recipients,

        // stato
        'statusByUser': statusByUser,

        'isActive': true,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('payment_request_created_success'))),
      );

      Navigator.pop(context); // torna a selezione
      Navigator.pop(context); // torna al gruppo
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    final recipientsList = widget.recipients.values.toList();
    final dueDateStr = _dueDate == null
        ? loc.t('payment_pick_date')
        : DateFormat('dd/MM/yyyy').format(_dueDate!);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('payment_create_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.t('payment_recipients_label'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recipientsList.map((name) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.t('payment_amount_label'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: loc.t('payment_amount_hint'),
                      filled: true,
                      fillColor: colors.surfaceVariant.withOpacity(0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      prefixText: "€ ",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.t('payment_note_label'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: loc.t('payment_note_hint'),
                      filled: true,
                      fillColor: colors.surfaceVariant.withOpacity(0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SoftCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.t('payment_due_date_label'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dueDateStr,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _loading ? null : _pickDate,
                    icon: const Icon(Icons.event),
                    label: Text(loc.t('payment_pick_date')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.send),
                label: Text(
                  _loading
                      ? loc.t('payment_creating')
                      : loc.t('payment_send_request'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
