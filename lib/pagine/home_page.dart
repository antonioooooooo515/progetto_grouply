import 'dart:math'; // Per generare il codice casuale
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'group_page.dart';
import 'messages_page.dart';
import 'payments_page.dart';
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

  // --- LOGICA CREAZIONE GRUPPO ---

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
      // 1. Genera codice
      String inviteCode = _generateInviteCode();

      // 2. Riferimento al documento (ID automatico)
      final docRef = FirebaseFirestore.instance.collection('groups').doc();

      // 3. Dati da salvare
      final groupData = {
        'id': docRef.id,
        'name': name,
        'sport': sport,
        'inviteCode': inviteCode,
        'adminId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'members': [user.uid], // L'admin è il primo membro
      };

      // 4. Scrittura su Firestore
      await docRef.set(groupData);

      if (mounted) {
        // Chiude il dialog se è ancora aperto (gestito nel metodo _showCreateGroupDialog)
        // Mostra conferma
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

  void _showCreateGroupDialog() {
    final loc = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final sportController = TextEditingController();

    // Variabile di stato locale per il dialog (per mostrare il caricamento)
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(loc.t('dialog_create_group_title')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: loc.t('label_team_name'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sportController,
                    decoration: InputDecoration(
                      labelText: loc.t('label_team_sport'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

                    // Chiamata alla funzione di creazione
                    await _createGroup(
                      nameController.text.trim(),
                      sportController.text.trim(),
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop(); // Chiude il dialog
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
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

                // Opzione: CREA GRUPPO
                ListTile(
                  leading: const Icon(Icons.group_add),
                  title: Text(loc.t('home_groups_create')),
                  onTap: () {
                    Navigator.of(context).pop(); // Chiude il menu opzioni
                    _showCreateGroupDialog();    // Apre il dialog di creazione
                  },
                ),

                // Opzione: UNISCITI A GRUPPO
                ListTile(
                  leading: const Icon(Icons.qr_code),
                  title: Text(loc.t('home_groups_join')),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.t('home_groups_join_snackbar')),
                      ),
                    );
                    // TODO: vai alla pagina di inserimento codice
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
          _HomePageContent(), // index 0 (Home)
          GroupPage(),        // index 1 (Gruppi)
          MessagesPage(),     // index 2 (Messaggi)
          PaymentsPage(),     // index 3 (Pagamenti)
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
        selectedItemColor: const Color(0xFFE91E63),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed, // Impedisce ai pulsanti di muoversi se sono più di 3
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
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

      // FAB SOLO NELLA SEZIONE GRUPPO (index 1)
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

class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    return Center(
      child: Text(
        loc.t('home_message'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          color: colors.onSurface,
        ),
      ),
    );
  }
}