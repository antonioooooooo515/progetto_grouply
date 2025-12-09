import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../localization/app_localizations.dart';
import '../widgets/big_button.dart';
import 'location_picker_page.dart';

class CreateRecurringEventPage extends StatefulWidget {
  final String groupId;
  final String groupSport;

  const CreateRecurringEventPage({
    super.key,
    required this.groupId,
    this.groupSport = '',
  });

  @override
  State<CreateRecurringEventPage> createState() => _CreateRecurringEventPageState();
}

class _CreateRecurringEventPageState extends State<CreateRecurringEventPage> {
  late TextEditingController _nameController;
  final TextEditingController _locationController = TextEditingController();

  TimeOfDay? _selectedTime;
  DateTime? _selectedDate;

  String? _selectedRecurrence; // 'daily', 'weekly', 'monthly'

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nameController.text.isEmpty) {
      _nameController.text = AppLocalizations.of(context).t('default_event_training');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  IconData _getSportIcon() {
    final s = widget.groupSport.toLowerCase();
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerPage(),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _locationController.text = result;
      });
    }
  }

  Future<void> _saveEvent() async {
    final loc = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nameController.text.isEmpty || _selectedDate == null || _selectedTime == null || _selectedRecurrence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('error_missing_fields')), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      int occurrences = 1;
      if (_selectedRecurrence == 'daily') occurrences = 30; // 1 mese
      if (_selectedRecurrence == 'weekly') occurrences = 12; // 3 mesi
      if (_selectedRecurrence == 'monthly') occurrences = 3;  // 3 mesi

      final batch = FirebaseFirestore.instance.batch();

      for (int i = 0; i < occurrences; i++) {
        DateTime instanceDate = _selectedDate!;
        if (_selectedRecurrence == 'daily') {
          instanceDate = instanceDate.add(Duration(days: i));
        } else if (_selectedRecurrence == 'weekly') {
          instanceDate = instanceDate.add(Duration(days: i * 7));
        } else if (_selectedRecurrence == 'monthly') {
          instanceDate = DateTime(instanceDate.year, instanceDate.month + i, instanceDate.day);
        }

        final DateTime eventDateTime = DateTime(
          instanceDate.year, instanceDate.month, instanceDate.day,
          _selectedTime!.hour, _selectedTime!.minute,
        );

        final docRef = FirebaseFirestore.instance.collection('events').doc();

        final eventData = {
          'groupId': widget.groupId,
          'type': 'training',
          'title': _nameController.text.trim(),
          'matchType': 'training',
          'startDateTime': Timestamp.fromDate(eventDateTime),
          'location': _locationController.text.trim(), // Unico campo location
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'isRecurring': true,
          'recurrenceType': _selectedRecurrence,
        };

        batch.set(docRef, eventData);
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('event_created_success')), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    final recurrenceTypes = [
      {'val': 'daily', 'label': loc.t('recurrence_daily')},
      {'val': 'weekly', 'label': loc.t('recurrence_weekly')},
      {'val': 'monthly', 'label': loc.t('recurrence_monthly')},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('create_recurring_event_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 1. NOME EVENTO (Default "Allenamento")
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: loc.t('label_event_name'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(_getSportIcon()),
              ),
            ),
            const SizedBox(height: 16),

            // 2. DATA E ORA
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: loc.t('label_date'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                            : "--/--/--",
                        style: TextStyle(color: _selectedDate != null ? colors.onSurface : Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: loc.t('label_start_time'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                      child: Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : "--:--",
                        style: TextStyle(color: _selectedTime != null ? colors.onSurface : Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. LUOGO (Singolo campo)
            TextField(
              controller: _locationController,
              readOnly: true,
              onTap: _pickLocation,
              decoration: InputDecoration(
                labelText: loc.t('label_location'), // Usa la chiave generica
                hintText: loc.t('map_select_placeholder'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                suffixIcon: const Icon(Icons.chevron_right),
              ),
            ),
            const SizedBox(height: 32),

            // 4. RIPETIZIONE (In fondo)
            DropdownButtonFormField<String>(
              value: _selectedRecurrence,
              decoration: InputDecoration(
                labelText: loc.t('label_recurrence'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.repeat),
              ),
              items: recurrenceTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['val'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedRecurrence = val),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4, bottom: 20),
              child: Text(
                loc.t('recurrence_info'),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),

            // 5. BOTTONE CREA
            BigButton(
              text: loc.t('button_create'),
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveEvent,
            ),
          ],
        ),
      ),
    );
  }
}