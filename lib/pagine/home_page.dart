import 'dart:math';
import 'dart:convert'; // Per decodificare le immagini
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final TabController _homeTabController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    // 3 Tabs: Eventi, Post, Sondaggi
    _homeTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _homeTabController.dispose();
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

  // --- LOGICA GRUPPI (CREAZIONE/UNIONE) ---

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
          SnackBar(content: Text("Errore: $e"), backgroundColor: Colors.red),
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        titleSpacing: 0,

        // TAB BAR HOME (Centrata e Ovale)
        title: _currentIndex == 0
            ? TabBar(
          controller: _homeTabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          splashBorderRadius: BorderRadius.circular(50),
          labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          labelColor: colors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: colors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          tabs: [
            Tab(text: loc.t('home_tab_events')),
            Tab(text: loc.t('home_tab_posts')),
            Tab(text: loc.t('home_tab_polls')),
          ],
        )
            : null,
        actions: [
          IconButton(
            iconSize: 32,
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // HOME TAB VIEW
          TabBarView(
            controller: _homeTabController,
            children: [
              const _HomeTimelineContent(), // EVENTI
              const _HomePostsContent(),    // 🔥 POSTS (Lista Aggregata)
              Center(child: Text(loc.t('home_no_polls'), style: TextStyle(color: Colors.grey))), // SONDAGGI (Placeholder)
            ],
          ),

          GroupPage(),
          MessagesPage(),
          PaymentsPage(),
        ],
      ),

      // 🔥 NAVBAR CORRETTA (ICONE CENTRATE)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
        selectedItemColor: const Color(0xFFE91E63),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,   // 👈 NASCONDE LABELS -> ICONE CENTRATE
        showUnselectedLabels: false, // 👈 NASCONDE LABELS -> ICONE CENTRATE
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), activeIcon: Icon(Icons.payments), label: ''),
        ],
      ),

      // FAB solo per la pagina Gruppi (Index 1)
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
// WIDGET AGENDA / TIMELINE (EVENTI)
// ----------------------------------------------------------------------

class _HomeTimelineContent extends StatelessWidget {
  const _HomeTimelineContent();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final loc = AppLocalizations.of(context);

    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: user.uid)
          .snapshots(),
      builder: (context, groupsSnapshot) {
        if (!groupsSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        final Map<String, String> groupNames = {};
        final List<String> groupIds = [];

        for (var doc in groupsSnapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          groupNames[doc.id] = data['name'] ?? 'Gruppo';
          groupIds.add(doc.id);
        }

        if (groupIds.isEmpty) {
          return Center(child: Text(loc.t('home_no_groups'), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)));
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
            if (!eventsSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (eventsSnapshot.data!.docs.isEmpty) return Center(child: Text(loc.t('home_no_events'), style: TextStyle(color: Colors.grey.shade600)));

            final groupedEvents = _groupEventsByDay(eventsSnapshot.data!.docs);

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedEvents.keys.length,
              itemBuilder: (context, index) {
                final dateKey = groupedEvents.keys.elementAt(index);
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
                        colors: Theme.of(context).colorScheme,
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

// ----------------------------------------------------------------------
// 🔥 WIDGET LISTA POST (AGGIORNATO CON CANCELLAZIONE)
// ----------------------------------------------------------------------

class _HomePostsContent extends StatelessWidget {
  const _HomePostsContent();

  Future<void> _deletePost(BuildContext context, String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Elimina Post"),
        content: const Text("Vuoi davvero eliminare questo post?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annulla")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Elimina", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post eliminato.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final loc = AppLocalizations.of(context);

    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: user.uid)
          .snapshots(),
      builder: (context, groupsSnapshot) {
        if (!groupsSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        final List<String> groupIds = groupsSnapshot.data!.docs.map((d) => d.id).toList();
        final safeGroupIds = groupIds.take(10).toList();

        if (safeGroupIds.isEmpty) {
          return Center(child: Text(loc.t('home_no_groups')));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('groupId', whereIn: safeGroupIds)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, postsSnapshot) {
            if (postsSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!postsSnapshot.hasData || postsSnapshot.data!.docs.isEmpty) return Center(child: Text(loc.t('home_no_posts')));

            final posts = postsSnapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final postDoc = posts[index];
                final postData = postDoc.data() as Map<String, dynamic>;

                // 🔥 LOGICA CANCELLAZIONE HOME: Solo se sono l'autore
                final canDelete = postData['authorId'] == user.uid;

                return _PostCard(
                  postData: postData,
                  canDelete: canDelete,
                  onDelete: () => _deletePost(context, postDoc.id),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ----------------------------------------------------------------------
// WIDGET CARD POST (CON MENU CANCELLAZIONE)
// ----------------------------------------------------------------------

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> postData;
  final bool canDelete;
  final VoidCallback onDelete;

  const _PostCard({
    required this.postData,
    required this.canDelete,
    required this.onDelete
  });

  @override
  Widget build(BuildContext context) {
    final String title = postData['title'] ?? 'Senza titolo';
    final String desc = postData['description'] ?? '';
    final String groupName = postData['groupName'] ?? 'Gruppo';
    final Timestamp? ts = postData['createdAt'];
    final String dateStr = ts != null
        ? DateFormat('dd MMM HH:mm').format(ts.toDate())
        : '';

    final String? imageBase64 = postData['imageBase64'];
    final String? fileName = postData['fileName'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(groupName.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),

                // 🔥 MENU 3 PUNTINI (SOLO SE SEI AUTORE DEL POST)
                if (canDelete)
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_horiz, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Elimina post', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Titolo
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            // Descrizione
            Text(desc, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),

            // Immagine
            if (imageBase64 != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(base64Decode(imageBase64), width: double.infinity, height: 200, fit: BoxFit.cover),
                ),
              ),

            // Allegato
            if (fileName != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                child: Row(
                  children: [
                    const Icon(Icons.description, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// WIDGET DATA & EVENT CARD (PER AGENDA)
// ----------------------------------------------------------------------

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final AppLocalizations loc;

  const _DateHeader({required this.date, required this.loc});

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
      label = loc.t('label_today');
    } else if (isSameDay(date, tomorrow)) {
      label = loc.t('label_tomorrow');
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
    final String? customTitle = event['title'];

    String title = "Evento";
    Color lineColor = Colors.green;

    if (customTitle != null && customTitle.isNotEmpty) {
      title = customTitle;
      lineColor = Colors.teal;
    } else if (matchType == 'home') {
      title = "${event['homeTeam']} vs ${event['awayTeam']}";
      lineColor = Colors.blue;
    } else if (matchType == 'away') {
      title = "${event['homeTeam']} vs ${event['awayTeam']}";
      lineColor = Colors.orange;
    } else if (matchType == 'tournament') {
      title = "Torneo";
      lineColor = Colors.amber;
    } else {
      title = "${event['homeTeam'] ?? '?'} vs ${event['awayTeam'] ?? '?'}";
    }

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
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
                  Text(timeStr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.onSurface)),
                ],
              ),
              const SizedBox(width: 16),
              Container(width: 4, height: 40, decoration: BoxDecoration(color: lineColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(groupName.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primary.withOpacity(0.8), letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (event['location'] != null && event['location'].toString().isNotEmpty)
                      Text(event['location'], style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}