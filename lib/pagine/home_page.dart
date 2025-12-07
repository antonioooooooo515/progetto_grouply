import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Per le date

import 'group_page.dart';
import 'messages_page.dart';
import 'payments_page.dart';
import 'event_details_page.dart';
import '../localization/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  // --- LOGICA GRUPPI ---

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      6,
          (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }

  Future<void> _createGroup(String name, String sport) async {
    final user = FirebaseAuth.instance.currentUser;
    final loc = AppLocalizations.of(context);

    if (user == null) return;

    try {
      String inviteCode = _generateInviteCode();
      final docRef = FirebaseFirestore.instance.collection('groups').doc();

      final groupData = {
        'id': docRef.id,
        'name': name,
        'sport': sport,
        'inviteCode': inviteCode,
        'adminId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'members': [user.uid],
      };

      await docRef.set(groupData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.t('snack_group_created', params: {'code': inviteCode}),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.t('snack_create_error', params: {'error': e.toString()}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _joinGroupLogic(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    final loc = AppLocalizations.of(context);

    if (user == null) return loc.t('error_user_not_found');

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return loc.t('error_code_not_found');
      }

      final groupDoc = querySnapshot.docs.first;
      final groupData = groupDoc.data();
      final members = List<String>.from(groupData['members'] ?? []);

      if (members.contains(user.uid)) {
        return loc.t('error_already_member');
      }

      await groupDoc.reference.update({
        'members': FieldValue.arrayUnion([user.uid]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.t('snack_join_success', params: {'groupName': groupData['name']})),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;

    } catch (e) {
      return loc.t('snack_join_error', params: {'error': e.toString()});
    }
  }

  void _showJoinGroupDialog() {
    final loc = AppLocalizations.of(context);
    final codeController = TextEditingController();
    String? errorMessage;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(loc.t('dialog_join_group_title')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: loc.t('label_insert_code'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      counterText: "",
                      errorText: errorMessage,
                      errorMaxLines: 2,
                    ),
                    maxLength: 6,
                    onChanged: (_) {
                      if (errorMessage != null) {
                        setStateDialog(() => errorMessage = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text(loc.t('button_cancel')),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    setStateDialog(() => errorMessage = null);
                    final code = codeController.text.trim().toUpperCase();

                    if (code.length != 6) {
                      setStateDialog(() {
                        errorMessage = loc.t('validation_code_length');
                      });
                      return;
                    }

                    setStateDialog(() => isLoading = true);
                    final errorString = await _joinGroupLogic(code);

                    if (context.mounted) {
                      setStateDialog(() => isLoading = false);
                      if (errorString == null) {
                        Navigator.of(context).pop();
                      } else {
                        setStateDialog(() {
                          errorMessage = errorString;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(loc.t('button_join')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateGroupDialog() {
    final loc = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final sportController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(loc.t('dialog_create_group_title')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: loc.t('label_team_name'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sportController,
                    decoration: InputDecoration(
                      labelText: loc.t('label_team_sport'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text(loc.t('button_cancel')),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    if (nameController.text.trim().isEmpty) return;

                    setStateDialog(() => isLoading = true);
                    await _createGroup(nameController.text.trim(), sportController.text.trim());
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(loc.t('button_create')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGroupOptionsDialog() {
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.t('home_groups_dialog_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(Icons.group_add),
                  title: Text(loc.t('home_groups_create')),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showCreateGroupDialog();
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.qr_code),
                  title: Text(loc.t('home_groups_join')),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showJoinGroupDialog();
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(loc.t('close_button')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: null,
        leading: null,
        actions: [
          IconButton(
            iconSize: 32,
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          _HomeTimelineContent(), // Index 0: Agenda
          GroupPage(),            // Index 1: Gruppi
          MessagesPage(),         // Index 2: Messaggi
          PaymentsPage(),         // Index 3: Pagamenti
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
        selectedItemColor: const Color(0xFFE91E63),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            activeIcon: Icon(Icons.payments),
            label: '',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
        onPressed: _showGroupOptionsDialog,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}

// ----------------------------------------------------------------------
// WIDGET AGENDA / TIMELINE
// ----------------------------------------------------------------------

class _HomeTimelineContent extends StatelessWidget {
  const _HomeTimelineContent();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: user.uid)
          .snapshots(),
      builder: (context, groupsSnapshot) {
        if (groupsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!groupsSnapshot.hasData || groupsSnapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    loc.t('home_no_groups'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        }

        final Map<String, String> groupNames = {};
        final List<String> groupIds = [];

        for (var doc in groupsSnapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          groupNames[doc.id] = data['name'] ?? 'Gruppo';
          groupIds.add(doc.id);
        }

        final safeGroupIds = groupIds.take(10).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .where('groupId', whereIn: safeGroupIds)
              .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.now())
              .orderBy('startDateTime', descending: false)
              .limit(50)
              .snapshots(),
          builder: (context, eventsSnapshot) {
            if (eventsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!eventsSnapshot.hasData || eventsSnapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  loc.t('home_no_events'),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              );
            }

            final groupedEvents = _groupEventsByDay(eventsSnapshot.data!.docs);

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedEvents.keys.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      loc.t('home_upcoming_events'),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                final dateKey = groupedEvents.keys.elementAt(index - 1);
                final eventsForDay = groupedEvents[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DateHeader(date: dateKey, loc: loc),
                    const SizedBox(height: 8),
                    ...eventsForDay.map((eventDoc) {
                      final eventData = eventDoc.data() as Map<String, dynamic>;
                      final groupId = eventData['groupId'];
                      final groupName = groupNames[groupId] ?? 'Gruppo';

                      return _HomeEventCard(
                        eventId: eventDoc.id,
                        event: eventData,
                        groupName: groupName,
                        colors: colors,
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Map<DateTime, List<QueryDocumentSnapshot>> _groupEventsByDay(List<QueryDocumentSnapshot> docs) {
    final Map<DateTime, List<QueryDocumentSnapshot>> grouped = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? ts = data['startDateTime'];
      if (ts == null) continue;
      final date = ts.toDate();
      final dayKey = DateTime(date.year, date.month, date.day);
      if (!grouped.containsKey(dayKey)) {
        grouped[dayKey] = [];
      }
      grouped[dayKey]!.add(doc);
    }
    return grouped;
  }
}

// 🔥 HEADER DATA CORRETTO (USA LE TRADUZIONI)
class _DateHeader extends StatelessWidget {
  final DateTime date;
  final AppLocalizations loc;

  const _DateHeader({required this.date, required this.loc});

  // Funzione sicura per confrontare i giorni ignorando l'ora
  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    String label;
    final localeCode = loc.locale.languageCode;

    if (isSameDay(date, now)) {
      label = loc.t('label_today'); // 👈 TRADOTTO
    } else if (isSameDay(date, tomorrow)) {
      label = loc.t('label_tomorrow'); // 👈 TRADOTTO
    } else {
      label = DateFormat('EEEE d MMMM', localeCode).format(date);
      label = label[0].toUpperCase() + label.substring(1);
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _HomeEventCard extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> event;
  final String groupName;
  final ColorScheme colors;

  const _HomeEventCard({
    required this.eventId,
    required this.event,
    required this.groupName,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = event['startDateTime'] as Timestamp?;
    final DateTime? date = timestamp?.toDate();
    final timeStr = date != null ? DateFormat.Hm().format(date) : "--:--";

    final matchType = event['matchType'] ?? 'friendly';
    String title = "Evento";

    if (matchType == 'tournament') {
      title = "Torneo";
    } else {
      title = "${event['homeTeam'] ?? '?'} vs ${event['awayTeam'] ?? '?'}";
    }

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsPage(
                eventId: eventId,
                isAdmin: false,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _getEventColor(matchType),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colors.primary.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (event['location'] != null)
                      Text(
                        event['location'],
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'home': return Colors.blue;
      case 'away': return Colors.orange;
      case 'tournament': return Colors.amber;
      default: return Colors.green;
    }
  }
}