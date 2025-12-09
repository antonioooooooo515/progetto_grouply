import 'dart:convert'; // per base64

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/big_button.dart';
import '../localization/app_localizations.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _sportController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  String? _selectedMonth;
  String? _selectedGender;

  // stringa base64 dell'immagine profilo
  String? _profileImageBase64;

  bool _isLoading = true;            // carica dati iniziali
  bool _isSaving = false;            // sta salvando il profilo
  bool _isUploadingImage = false;    // sta caricando la foto

  final List<String> _months = const [
    'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
    'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre',
  ];

  final List<String> _genders = const [
    'Maschio', 'Femmina', 'Altro',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dayController.dispose();
    _yearController.dispose();
    _sportController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};

        _nameController.text = (data['displayName'] ?? '') as String;
        _dayController.text =
        data['birthDay'] != null ? data['birthDay'].toString() : '';
        _yearController.text =
        data['birthYear'] != null ? data['birthYear'].toString() : '';

        String? savedMonth = data['birthMonth'] as String?;
        if (_months.contains(savedMonth)) {
          _selectedMonth = savedMonth;
        }

        String? savedGender = data['gender'] as String?;
        if (_genders.contains(savedGender)) {
          _selectedGender = savedGender;
        }

        _sportController.text = (data['sport'] ?? '') as String;
        _roleController.text = (data['role'] ?? '') as String;
        _profileImageBase64 = data['profileImageBase64'] as String?;
      }
    } catch (e) {
      debugPrint("Errore caricamento profilo: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _roundedInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: Colors.grey.shade400,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(
          color: Color(0xFFE91E63),
          width: 1.5,
        ),
      ),
    );
  }

  // --- MODIFICATA PER GESTIRE IL LIMITE FIREBASE ---
  Future<void> _changePhoto() async {
    final loc = AppLocalizations.of(context);

    if (_isUploadingImage || _isSaving) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.t('toast_login_required'))),
        );
        return;
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        // ⚠️ Riduzione aggressiva per profilo
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 60,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      // ⚠️ Controllo dimensione
      if ((bytes.lengthInBytes / 1024) > 700) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Immagine troppo pesante per Firestore. Riprova.")),
        );
        return;
      }

      setState(() {
        _isUploadingImage = true;
      });

      final base64Str = base64Encode(bytes);

      setState(() {
        _profileImageBase64 = base64Str;
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'profileImageBase64': base64Str,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.t('toast_photo_error')}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.t('toast_login_required'))),
        );
        return;
      }

      setState(() => _isSaving = true);

      int? day = _dayController.text.isNotEmpty
          ? int.tryParse(_dayController.text)
          : null;
      int? year = _yearController.text.isNotEmpty
          ? int.tryParse(_yearController.text)
          : null;

      final data = {
        'displayName': _nameController.text.trim(),
        'birthDay': day,
        'birthMonth': _selectedMonth,
        'birthYear': year,
        'gender': _selectedGender,
        'sport': _sportController.text.trim(),
        'role': _roleController.text.trim(),
        // L'immagine è già stata salvata da _changePhoto, ma la rimandiamo per sicurezza se presente
        if (_profileImageBase64 != null) 'profileImageBase64': _profileImageBase64,
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.t('toast_save_success'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  ImageProvider? _getProfileImageProvider() {
    if (_profileImageBase64 == null) return null;
    try {
      final bytes = base64Decode(_profileImageBase64!);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.t('profile_title')),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('profile_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _changePhoto,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: colors.primary.withOpacity(0.2),
                        backgroundImage: _getProfileImageProvider(),
                        child: _getProfileImageProvider() == null
                            ? Icon(
                          Icons.person,
                          size: 40,
                          color: colors.primary,
                        )
                            : null,
                      ),
                      if (_isUploadingImage)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    loc.t('profile_change_photo'),
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Nome
          TextField(
            controller: _nameController,
            decoration: _roundedInputDecoration(loc.t('label_name')),
          ),
          const SizedBox(height: 16),

          // Giorno, mese, anno di nascita
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _dayController,
                  keyboardType: TextInputType.number,
                  decoration: _roundedInputDecoration(loc.t('label_day')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedMonth,
                  decoration: _roundedInputDecoration(loc.t('label_month')),
                  borderRadius: BorderRadius.circular(20),
                  items: _months
                      .map(
                        (m) => DropdownMenuItem(
                      value: m,
                      child: Text(m),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedMonth = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: _roundedInputDecoration(loc.t('label_year')),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Genere
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.40,
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: _roundedInputDecoration(loc.t('label_gender')),
                borderRadius: BorderRadius.circular(20),
                items: _genders
                    .map(
                      (g) => DropdownMenuItem(
                    value: g,
                    child: Text(g),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedGender = value);
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sport praticato
          TextField(
            controller: _sportController,
            decoration: _roundedInputDecoration(loc.t('label_sport')),
          ),

          const SizedBox(height: 16),

          // Ruolo del giocatore
          TextField(
            controller: _roleController,
            decoration: _roundedInputDecoration(loc.t('label_role')),
          ),

          const SizedBox(height: 30),

          BigButton(
            text: loc.t('button_save'),
            isLoading: _isSaving,
            onPressed: (_isSaving || _isUploadingImage) ? null : _save,
          ),
        ],
      ),
    );
  }
}