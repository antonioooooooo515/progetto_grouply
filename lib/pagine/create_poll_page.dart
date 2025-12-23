import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../localization/app_localizations.dart';
import '../widgets/soft_card.dart';

class CreatePollPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const CreatePollPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<CreatePollPage> createState() => _CreatePollPageState();
}

class _CreatePollPageState extends State<CreatePollPage> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool _loading = false;

  // ✅ nuovo
  bool _allowMultiple = false;

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 8) return;
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    final c = _optionControllers.removeAt(index);
    c.dispose();
    setState(() {});
  }

  bool _isValid() {
    final q = _questionController.text.trim();
    if (q.isEmpty) return false;

    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return options.length >= 2;
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context);

    if (!_isValid()) {
      final q = _questionController.text.trim();
      if (q.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.t('poll_missing_fields_error'))),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('poll_min_options_error'))),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('toast_login_required'))),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final question = _questionController.text.trim();
      final options = _optionControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance.collection('polls').add({
        'groupId': widget.groupId,
        'groupName': widget.groupName,
        'question': question,
        'options': options,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'isActive': true,

        // ✅ nuovo: per supportare voto multiplo in home
        'allowMultiple': _allowMultiple,

        // voto iniziale vuoto (lo useremo nella home)
        'votes': <String, dynamic>{},
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('poll_created_success'))),
      );
      Navigator.pop(context);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('create_poll_title')),
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
                    loc.t('poll_question_label'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _questionController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: loc.t('poll_question_hint'),
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

            // ✅ nuovo: scelta multipla
            SoftCard(
              child: SwitchListTile(
                value: _allowMultiple,
                onChanged: _loading ? null : (v) => setState(() => _allowMultiple = v),
                title: Text(loc.t('poll_allow_multiple')),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 16),

            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.t('home_tab_polls'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ...List.generate(_optionControllers.length, (i) {
                    final isRemovable = _optionControllers.length > 2 && i >= 2;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _optionControllers[i],
                              decoration: InputDecoration(
                                labelText: loc.t(
                                  'poll_option_label',
                                  params: {'number': '${i + 1}'},
                                ),
                                filled: true,
                                fillColor: colors.surfaceVariant.withOpacity(0.35),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (isRemovable)
                            IconButton(
                              onPressed: _loading ? null : () => _removeOption(i),
                              icon: const Icon(Icons.close),
                              tooltip: loc.t('poll_remove_option'),
                            ),
                        ],
                      ),
                    );
                  }),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _loading ? null : _addOption,
                      icon: const Icon(Icons.add),
                      label: Text(loc.t('poll_add_option')),
                    ),
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
                    : const Icon(Icons.publish),
                label: Text(
                  _loading ? loc.t('poll_creating') : loc.t('poll_publish'),
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
