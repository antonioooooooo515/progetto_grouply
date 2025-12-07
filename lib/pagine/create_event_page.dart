import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../localization/app_localizations.dart';
import '../widgets/big_button.dart';
import 'location_picker_page.dart';

class CreateEventPage extends StatefulWidget {
  final String groupId;
  final String groupSport; // Serve per l'icona dinamica

  const CreateEventPage({
    super.key,
    required this.groupId,
    this.groupSport = '',
  });

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final TextEditingController _homeTeamController = TextEditingController();
  final TextEditingController _awayTeamController = TextEditingController();
  final List<TextEditingController> _tournamentTeamsControllers = [];
  final TextEditingController _meetingPointController = TextEditingController();
  final TextEditingController _matchLocationController = TextEditingController();

  String? _selectedMatchType;
  TimeOfDay? _selectedTime;
  TimeOfDay? _selectedMeetingTime;
  DateTime? _selectedDate;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addTournamentTeam();
    _addTournamentTeam();
  }

  @override
  void dispose() {
    _homeTeamController.dispose();
    _awayTeamController.dispose();
    _meetingPointController.dispose();
    _matchLocationController.dispose();
    for (var controller in _tournamentTeamsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // 🔥 FUNZIONE PER ICONA DINAMICA
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
    return Icons.sports_soccer; // Default
  }

  void _addTournamentTeam() {
    setState(() {
      _tournamentTeamsControllers.add(TextEditingController());
    });
  }

  void _removeTournamentTeam(int index) {
    if (_tournamentTeamsControllers.length > 2) {
      setState(() {
        _tournamentTeamsControllers[index].dispose();
        _tournamentTeamsControllers.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Un torneo deve avere almeno 2 squadre!")),
      );
    }
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

  Future<void> _pickMeetingTime() async {
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
      setState(() => _selectedMeetingTime = picked);
    }
  }

  Future<void> _pickLocation(TextEditingController controller) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerPage(),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        controller.text = result;
      });
    }
  }

  Future<void> _saveEvent() async {
    final loc = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_selectedMatchType == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('error_missing_fields')), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final DateTime eventDateTime = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedTime!.hour, _selectedTime!.minute,
      );

      Timestamp? meetingTimestamp;
      if (_selectedMeetingTime != null) {
        final DateTime meetingDateTime = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
          _selectedMeetingTime!.hour, _selectedMeetingTime!.minute,
        );
        meetingTimestamp = Timestamp.fromDate(meetingDateTime);
      }

      Map<String, dynamic> teamsData = {};
      if (_selectedMatchType == 'tournament') {
        teamsData['teams'] = _tournamentTeamsControllers
            .map((c) => c.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();
      } else {
        teamsData['homeTeam'] = _homeTeamController.text.trim();
        teamsData['awayTeam'] = _awayTeamController.text.trim();
      }

      final eventData = {
        'groupId': widget.groupId,
        'type': 'match',
        'matchType': _selectedMatchType,
        'startDateTime': Timestamp.fromDate(eventDateTime),
        'meetingDateTime': meetingTimestamp,
        'meetingPoint': _meetingPointController.text.trim(),
        'location': _matchLocationController.text.trim(),
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        ...teamsData,
      };

      await FirebaseFirestore.instance.collection('events').add(eventData);

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

    final matchTypes = [
      {'val': 'home', 'label': loc.t('match_type_home')},
      {'val': 'away', 'label': loc.t('match_type_away')},
      {'val': 'tournament', 'label': loc.t('match_type_tournament')},
      {'val': 'friendly', 'label': loc.t('match_type_friendly')},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('create_event_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 1. TIPO DI PARTITA (Icona Dinamica)
            DropdownButtonFormField<String>(
              value: _selectedMatchType,
              decoration: InputDecoration(
                labelText: loc.t('label_match_type'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                // 🔥 ORA L'ICONA È DINAMICA!
                prefixIcon: Icon(_getSportIcon()),
              ),
              items: matchTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['val'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedMatchType = val),
            ),
            const SizedBox(height: 16),

            // 2. SQUADRE
            if (_selectedMatchType == 'tournament')
              _buildTournamentSection(loc, colors)
            else
              _buildSingleMatchSection(loc),

            const SizedBox(height: 16),

            // 3. DATA E ORA PARTITA
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

            // 4. LUOGO PARTITA
            TextField(
              controller: _matchLocationController,
              readOnly: true,
              onTap: () => _pickLocation(_matchLocationController),
              decoration: InputDecoration(
                labelText: loc.t('label_match_location'),
                hintText: loc.t('map_select_placeholder'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                suffixIcon: const Icon(Icons.chevron_right),
              ),
            ),
            const SizedBox(height: 16),

            // 5. RITROVO: LUOGO + ORARIO
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _meetingPointController,
                    readOnly: true,
                    onTap: () => _pickLocation(_meetingPointController),
                    decoration: InputDecoration(
                      labelText: loc.t('label_meeting_point'),
                      hintText: loc.t('map_select_placeholder'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.map, color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: _pickMeetingTime,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: loc.t('label_meeting_time'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        // 🔥 ORA L'ICONA È ACCESS_TIME
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                      child: Text(
                        _selectedMeetingTime != null
                            ? _selectedMeetingTime!.format(context)
                            : "--:--",
                        style: TextStyle(
                          color: _selectedMeetingTime != null ? colors.onSurface : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

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

  Widget _buildSingleMatchSection(AppLocalizations loc) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _homeTeamController,
            decoration: InputDecoration(
              labelText: loc.t('label_home_team'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text("VS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _awayTeamController,
            decoration: InputDecoration(
              labelText: loc.t('label_away_team'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentSection(AppLocalizations loc, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.t('label_tournament_teams'),
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tournamentTeamsControllers.length,
          separatorBuilder: (ctx, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tournamentTeamsControllers[index],
                    decoration: InputDecoration(
                      hintText: loc.t('hint_team_n', params: {'number': '${index + 1}'}),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (_tournamentTeamsControllers.length > 2)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => _removeTournamentTeam(index),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _addTournamentTeam,
            icon: const Icon(Icons.add),
            label: Text(loc.t('btn_add_team')),
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}