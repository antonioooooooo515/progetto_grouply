import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../localization/app_localizations.dart';
import 'event_type_selector_page.dart';
import 'create_post_page.dart';
import 'create_poll_page.dart';
import 'payment_select_recipients_page.dart';
import 'user_profile_page.dart';
import 'event_details_page.dart';
import 'member_list_page.dart';
import '../widgets/soft_card.dart';

// ✅ NOTIFICHE FOREGROUND
import '../services/push_notification_service.dart';

class GroupDashboardPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupSport;
  final String adminId;
  final String inviteCode;

  const GroupDashboardPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupSport,
    required this.adminId,
    required this.inviteCode,
  });

  @override
  State<GroupDashboardPage> createState() => _GroupDashboardPageState();
}

class _GroupDashboardPageState extends State<GroupDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- STATO SELEZIONE ---
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  String? _selectionType; // 'event' oppure 'post'

  // ✅ Listener foreground (Firestore)
  StreamSubscription<QuerySnapshot>? _eventsSub;
  StreamSubscription<QuerySnapshot>? _postsSub;
  StreamSubscription<QuerySnapshot>? _pollsSub;

  bool _eventsPrimed = false;
  bool _postsPrimed = false;
  bool _pollsPrimed = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
      if (_isSelectionMode) {
        _cancelSelection();
      }
    });

    // ✅ Avvio notifiche FOREGROUND (solo mobile)
    if (!kIsWeb) {
      _startForegroundGroupNotifications();
    }
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _postsSub?.cancel();
    _pollsSub?.cancel();

    _tabController.dispose();
    super.dispose();
  }

  // -------------------------
  // NOTIFICHE FOREGROUND
  // -------------------------

  bool _isFromMe(Map<String, dynamic> data) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return false;

    const keys = ['createdBy', 'creatorId', 'authorId', 'userId', 'senderId'];
    for (final k in keys) {
      final v = (data[k] ?? '').toString().trim();
      if (v == uid) return true;
    }
    return false;
  }

  Future<void> _notifyDashboard({
    required String title,
    required String body,
    Map<String, dynamic>? extraData,
  }) async {
    await PushNotificationsService.instance.showLocal(
      title: title,
      body: body,
      data: {
        'type': 'group_content',
        'groupId': widget.groupId,
        ...(extraData ?? {}),
      },
    );
  }

  void _startForegroundGroupNotifications() {
    // EVENTI (senza orderBy per evitare crash se qualche campo non esiste)
    _eventsSub = FirebaseFirestore.instance
        .collection('events')
        .where('groupId', isEqualTo: widget.groupId)
        .snapshots()
        .listen((snap) async {
      if (!_eventsPrimed) {
        _eventsPrimed = true; // ignora primo caricamento
        return;
      }

      final added =
      snap.docChanges.where((c) => c.type == DocumentChangeType.added).toList();
      if (added.isEmpty) return;

      final doc = added.first.doc;
      final data = (doc.data() as Map<String, dynamic>? ?? {});
      if (_isFromMe(data)) return;

      final customTitle = (data['title'] ?? '').toString().trim();
      final homeTeam = (data['homeTeam'] ?? '').toString().trim();
      final awayTeam = (data['awayTeam'] ?? '').toString().trim();

      final body = customTitle.isNotEmpty
          ? customTitle
          : (homeTeam.isNotEmpty || awayTeam.isNotEmpty)
          ? '$homeTeam vs $awayTeam'
          : 'Tocca per aprire la bacheca';

      await _notifyDashboard(
        title: 'Nuovo evento',
        body: body,
        extraData: {
          'contentType': 'event',
          'contentId': doc.id,
        },
      );
    });

    // POST
    _postsSub = FirebaseFirestore.instance
        .collection('posts')
        .where('groupId', isEqualTo: widget.groupId)
        .snapshots()
        .listen((snap) async {
      if (!_postsPrimed) {
        _postsPrimed = true;
        return;
      }

      final added =
      snap.docChanges.where((c) => c.type == DocumentChangeType.added).toList();
      if (added.isEmpty) return;

      final doc = added.first.doc;
      final data = (doc.data() as Map<String, dynamic>? ?? {});
      if (_isFromMe(data)) return;

      final title = (data['title'] ?? '').toString().trim();
      final desc = (data['description'] ?? '').toString().trim();

      final body =
      title.isNotEmpty ? title : (desc.isNotEmpty ? desc : 'Tocca per aprire la bacheca');

      await _notifyDashboard(
        title: 'Nuovo post',
        body: body,
        extraData: {
          'contentType': 'post',
          'contentId': doc.id,
        },
      );
    });

    // SONDAGGI
    _pollsSub = FirebaseFirestore.instance
        .collection('polls')
        .where('groupId', isEqualTo: widget.groupId)
        .snapshots()
        .listen((snap) async {
      if (!_pollsPrimed) {
        _pollsPrimed = true;
        return;
      }

      final added =
      snap.docChanges.where((c) => c.type == DocumentChangeType.added).toList();
      if (added.isEmpty) return;

      final doc = added.first.doc;
      final data = (doc.data() as Map<String, dynamic>? ?? {});
      if (_isFromMe(data)) return;

      final question = (data['question'] ?? '').toString().trim();
      final title = (data['title'] ?? '').toString().trim();
      final text = (data['text'] ?? '').toString().trim();

      final body = question.isNotEmpty
          ? question
          : (title.isNotEmpty ? title : (text.isNotEmpty ? text : 'Tocca per aprire la bacheca'));

      await _notifyDashboard(
        title: 'Nuovo sondaggio',
        body: body,
        extraData: {
          'contentType': 'poll',
          'contentId': doc.id,
        },
      );
    });
  }

  // --- LOGICA SELEZIONE ---

  void _startSelection(String id, String type) {
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid ?? '';
    final isAdmin = currentUserId == widget.adminId;

    if (!isAdmin) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Solo l'amministratore può eliminare elementi."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_selectionType != null && _selectionType != type) return;

    setState(() {
      _isSelectionMode = true;
      _selectionType = type;
      _selectedIds.add(id);
    });

    HapticFeedback.mediumImpact();
  }

  void _toggleSelection(String id, String type) {
    if (_selectionType != null && _selectionType != type) return;

    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _cancelSelection();
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
      _selectionType = null;
    });
  }

  Future<void> _deleteSelectedItems() async {
    final loc = AppLocalizations.of(context);
    final count = _selectedIds.length;
    final type = _selectionType;

    if (type == null) return;

    final String title =
    type == 'event' ? loc.t('delete_event_title') : "Elimina post";
    final String content = type == 'event'
        ? loc.t('delete_event_confirm')
        : "Vuoi eliminare i $count elementi selezionati?";

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.t('button_cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Elimina",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final batch = FirebaseFirestore.instance.batch();
    final collectionName = type == 'event' ? 'events' : 'posts';

    for (var id in _selectedIds) {
      final ref = FirebaseFirestore.instance.collection(collectionName).doc(id);
      batch.delete(ref);
    }

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$count elementi eliminati")),
      );
      _cancelSelection();
    }
  }

  // --- FAB e ALTRE FUNZIONI ---

  void _showAddOptions(AppLocalizations loc, ColorScheme colors) {
    final String currentSport = widget.groupSport;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),

              // EVENTO
              ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child:
                    const Icon(Icons.calendar_today, color: Colors.blue)),
                title: Text(loc.t('fab_option_event'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventTypeSelectorPage(
                        groupId: widget.groupId,
                        groupSport: currentSport,
                      ),
                    ),
                  );
                },
              ),

              // POST
              ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    child: const Icon(Icons.article, color: Colors.orange)),
                title: Text(loc.t('fab_option_post'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(loc.t('fab_option_post_sub')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatePostPage(
                        groupId: widget.groupId,
                        groupName: widget.groupName,
                        groupSport: widget.groupSport,
                      ),
                    ),
                  );
                },
              ),

              // SONDAGGIO
              ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    child: const Icon(Icons.poll, color: Colors.purple)),
                title: Text(loc.t('fab_option_poll'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(loc.t('fab_option_poll_sub')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatePollPage(
                        groupId: widget.groupId,
                        groupName: widget.groupName,
                      ),
                    ),
                  );
                },
              ),

              // PAGAMENTO ✅
              ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: const Icon(Icons.euro, color: Colors.green)),
                title: Text(loc.t('fab_option_payment'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(loc.t('fab_option_payment_sub')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentSelectRecipientsPage(
                        groupId: widget.groupId,
                        groupName: widget.groupName,
                        adminId: widget.adminId,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _leaveGroup() async {
    final loc = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('dialog_leave_title')),
        content: Text(loc.t('dialog_leave_content')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.t('button_cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(loc.t('info_leave_group'),
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({'members': FieldValue.arrayRemove([user.uid])});

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.t('leave_success'))));
      Navigator.popUntil(context, ModalRoute.withName('/home'));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.t('leave_error', params: {'error': e.toString()}))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user?.uid == widget.adminId;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
        backgroundColor: colors.surfaceVariant,
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: _cancelSelection),
        title: Text("${_selectedIds.length} selezionati"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed:
            _selectedIds.isEmpty ? null : _deleteSelectedItems,
          ),
        ],
      )
          : AppBar(
        title: Text(widget.groupName),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.primary,
          labelColor: colors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
                text: loc.t('tab_board'),
                icon: const Icon(Icons.dashboard_outlined)),
            Tab(
                text: loc.t('tab_members'),
                icon: const Icon(Icons.people_outline)),
            Tab(
                text: loc.t('tab_info'),
                icon: const Icon(Icons.info_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: _isSelectionMode ? const NeverScrollableScrollPhysics() : null,
        children: [
          // 1. BACHECA
          _GroupBoardContent(
            groupId: widget.groupId,
            groupSport: widget.groupSport,
            isAdmin: isAdmin,
            isSelectionMode: _isSelectionMode,
            selectedIds: _selectedIds,
            selectionType: _selectionType,
            onToggleSelection: _toggleSelection,
            onStartSelection: _startSelection,
          ),

          // 2. MEMBRI
          MemberListPage(groupId: widget.groupId, groupName: widget.groupName),

          // 3. INFO
          _GroupInfoContent(
            groupId: widget.groupId,
            groupName: widget.groupName,
            groupSport: widget.groupSport,
            inviteCode: widget.inviteCode,
            adminId: widget.adminId,
            isAdmin: isAdmin,
            onLeaveGroup: _leaveGroup,
          ),
        ],
      ),
      floatingActionButton:
      (!_isSelectionMode && _tabController.index == 0 && isAdmin)
          ? FloatingActionButton(
        onPressed: () => _showAddOptions(loc, colors),
        backgroundColor: colors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }
}

// ----------------------------------------------------------------------
// WIDGET BACHECA (Eventi + Post)
// ----------------------------------------------------------------------
class _GroupBoardContent extends StatelessWidget {
  final String groupId;
  final String groupSport;
  final bool isAdmin;

  final bool isSelectionMode;
  final Set<String> selectedIds;
  final String? selectionType;
  final Function(String, String) onToggleSelection;
  final Function(String, String) onStartSelection;

  const _GroupBoardContent({
    required this.groupId,
    required this.groupSport,
    required this.isAdmin,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.selectionType,
    required this.onToggleSelection,
    required this.onStartSelection,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EVENTI
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .where('groupId', isEqualTo: groupId)
                .where('startDateTime',
                isGreaterThanOrEqualTo: Timestamp.now())
                .orderBy('startDateTime', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text("Errore eventi: ${snapshot.error}");
              }
              if (!snapshot.hasData) {
                return const Center(child: LinearProgressIndicator());
              }

              final events = snapshot.data!.docs;
              if (events.isEmpty) return const SizedBox();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.t('home_upcoming_events'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final eventDoc = events[index];
                      final eventData =
                      eventDoc.data() as Map<String, dynamic>;
                      final eventId = eventDoc.id;

                      final isSelected = selectedIds.contains(eventId);
                      final canSelect =
                      (selectionType == null || selectionType == 'event');

                      return _EventCard(
                        eventId: eventId,
                        event: eventData,
                        colors: Theme.of(context).colorScheme,
                        groupSport: groupSport,
                        isSelectionMode:
                        isSelectionMode && selectionType == 'event',
                        isSelected: isSelected,
                        onTap: () {
                          if (isSelectionMode) {
                            if (canSelect) onToggleSelection(eventId, 'event');
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailsPage(
                                  eventId: eventId,
                                  isAdmin: isAdmin,
                                ),
                              ),
                            );
                          }
                        },
                        onLongPress: () => onStartSelection(eventId, 'event'),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          // POST
          Text(loc.t('home_tab_posts'),
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .where('groupId', isEqualTo: groupId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                      child: Text(loc.t('home_no_posts'),
                          style: TextStyle(color: Colors.grey.shade600))),
                );
              }

              final posts = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final postDoc = posts[index];
                  final postData = postDoc.data() as Map<String, dynamic>;
                  final postId = postDoc.id;

                  final isSelected = selectedIds.contains(postId);
                  final canSelect =
                  (selectionType == null || selectionType == 'post');

                  return _SelectablePostCard(
                    postData: postData,
                    isSelectionMode: isSelectionMode && selectionType == 'post',
                    isSelected: isSelected,
                    onTap: () {
                      if (isSelectionMode) {
                        if (canSelect) onToggleSelection(postId, 'post');
                      }
                    },
                    onLongPress: () => onStartSelection(postId, 'post'),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// CARD EVENTO
// ----------------------------------------------------------------------
class _EventCard extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> event;
  final ColorScheme colors;
  final String groupSport;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _EventCard({
    required this.eventId,
    required this.event,
    required this.colors,
    required this.groupSport,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  IconData _getSportIcon(String sportName) {
    final s = sportName.toLowerCase();
    if (s.contains('pallavolo') || s.contains('volley'))
      return Icons.sports_volleyball;
    if (s.contains('basket') || s.contains('pallacanestro'))
      return Icons.sports_basketball;
    if (s.contains('tennis')) return Icons.sports_tennis;
    if (s.contains('rugby')) return Icons.sports_rugby;
    if (s.contains('football')) return Icons.sports_football;
    return Icons.sports_soccer;
  }

  @override
  Widget build(BuildContext context) {
    final type = event['matchType'] ?? 'friendly';
    final location = event['location'] ?? 'Posizione non specificata';
    final timestamp = event['startDateTime'] as Timestamp?;
    final DateTime? date = timestamp?.toDate();
    final String? customTitle = event['title'];

    IconData iconData;
    Color iconColor;
    String title = "Evento";

    if (customTitle != null && customTitle.isNotEmpty) {
      iconData = Icons.fitness_center;
      iconColor = Colors.teal;
      title = customTitle;
    } else if (type == 'home') {
      iconData = Icons.home;
      iconColor = Colors.blue;
      title = "${event['homeTeam']} vs ${event['awayTeam']}";
    } else if (type == 'away') {
      iconData = Icons.directions_bus;
      iconColor = Colors.orange;
      title = "${event['homeTeam']} vs ${event['awayTeam']}";
    } else if (type == 'tournament') {
      iconData = Icons.emoji_events;
      iconColor = Colors.amber;
      title = "Torneo";
    } else {
      iconData = _getSportIcon(groupSport);
      iconColor = Colors.green;
      title =
      "${event['homeTeam'] ?? 'Squadra'} vs ${event['awayTeam'] ?? 'Squadra'}";
    }

    String dateStr = "--/--";
    String timeStr = "--:--";
    if (date != null) {
      dateStr =
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
      timeStr =
      "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }

    final cardColor =
    isSelected ? colors.primaryContainer.withOpacity(0.3) : null;
    final borderColor = isSelected ? colors.primary : Colors.transparent;

    return Card(
      elevation: isSelected ? 0 : 2,
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: colors.primary.withOpacity(0.2),
        highlightColor: colors.primary.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? colors.primary : Colors.grey,
                  ),
                ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text(dateStr,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(timeStr,
                        style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(iconData, size: 20, color: iconColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isSelectionMode)
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// CARD POST
// ----------------------------------------------------------------------
class _SelectablePostCard extends StatelessWidget {
  final Map<String, dynamic> postData;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SelectablePostCard({
    required this.postData,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final String title = postData['title'] ?? 'Senza titolo';
    final String desc = postData['description'] ?? '';
    final Timestamp? ts = postData['createdAt'];
    final String dateStr =
    ts != null ? DateFormat('dd MMM HH:mm').format(ts.toDate()) : '';
    final String? imageBase64 = postData['imageBase64'];
    final String? fileName = postData['fileName'];

    final cardColor =
    isSelected ? colors.primaryContainer.withOpacity(0.3) : null;
    final borderColor = isSelected ? colors.primary : Colors.transparent;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 0 : 2,
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: colors.primary.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 4),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? colors.primary : Colors.grey,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr,
                        style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(desc, style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 12),
                    if (imageBase64 != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(imageBase64),
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    if (fileName != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.description, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(fileName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),
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
}

// ----------------------------------------------------------------------
// WIDGET INFO GRUPPO
// ----------------------------------------------------------------------
class _GroupInfoContent extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String groupSport;
  final String inviteCode;
  final String adminId;
  final bool isAdmin;
  final Future<void> Function() onLeaveGroup;

  const _GroupInfoContent({
    required this.groupId,
    required this.groupName,
    required this.groupSport,
    required this.inviteCode,
    required this.adminId,
    required this.isAdmin,
    required this.onLeaveGroup,
  });

  IconData _getSportIcon(String sportName) {
    final s = sportName.toLowerCase();
    if (s.contains('pallavolo') || s.contains('volley'))
      return Icons.sports_volleyball;
    if (s.contains('basket') || s.contains('pallacanestro'))
      return Icons.sports_basketball;
    if (s.contains('tennis')) return Icons.sports_tennis;
    if (s.contains('rugby')) return Icons.sports_rugby;
    if (s.contains('football')) return Icons.sports_football;
    return Icons.sports_soccer;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final isGroupAdmin = user?.uid == adminId;
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftCard(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.t('info_invite_code_label'),
                      style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(inviteCode,
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                              letterSpacing: 2.0)),
                      IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: inviteCode));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(loc.t('info_code_copied'))));
                          },
                          icon: const Icon(Icons.copy)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SoftCard(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.t('info_sport'),
                      style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(_getSportIcon(groupSport),
                            color: colors.primary, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Text(groupSport,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 30),
                  Text("Admin",
                      style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 8),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(adminId)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text("Caricamento...");
                      final userData =
                      snapshot.data!.data() as Map<String, dynamic>?;
                      final name = userData?['displayName'] ?? "Admin";
                      final String? photoBase64 =
                      userData?['profileImageBase64'];

                      ImageProvider? imageProvider;
                      if (photoBase64 != null) {
                        try {
                          imageProvider = MemoryImage(base64Decode(photoBase64));
                        } catch (_) {}
                      }

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfilePage(
                                  userId: adminId, userName: name),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: colors.primary.withOpacity(0.1),
                              backgroundImage: imageProvider,
                              child: imageProvider == null
                                  ? const Icon(Icons.person, size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          if (!isGroupAdmin)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLeaveGroup,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(loc.t('info_leave_group'),
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
