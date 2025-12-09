import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../localization/app_localizations.dart';
import '../widgets/big_button.dart';

class CreatePostPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String groupSport;

  const CreatePostPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupSport,
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  bool _isSaving = false;

  // Dati Foto
  String? _imageBase64;

  // Dati Allegato
  String? _fileName;
  String? _fileBase64;
  int? _fileSize;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- FUNZIONE PICK IMAGE (MODIFICATA PER RISPARMIARE SPAZIO) ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();

    // ⚠️ MODIFICA: Ridotto a 800x800 e qualità 50 per stare sotto 1MB (limite Firestore)
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();

      // ⚠️ CONTROLLO SICUREZZA: Se > 700KB (circa), blocchiamo per evitare crash Firestore
      // Il limite Firestore è 1MB, ma il Base64 aumenta la dimensione del ~33%.
      final sizeInKb = bytes.lengthInBytes / 1024;
      if (sizeInKb > 700) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Immagine troppo pesante! Riprova con una più piccola o fai uno screenshot."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      setState(() {
        _imageBase64 = base64Encode(bytes);
      });
    }
  }

  // --- FUNZIONE PICK FILE ---
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'txt', 'mp4', 'mov'],
      withData: true,
    );

    if (result != null) {
      PlatformFile pFile = result.files.single;

      Uint8List? fileBytes;

      if (kIsWeb) {
        fileBytes = pFile.bytes;
      } else {
        if (pFile.path != null) {
          fileBytes = await File(pFile.path!).readAsBytes();
        }
      }

      if (fileBytes != null) {
        // Controllo preventivo anche per i file (limite ~700KB per sicurezza)
        final sizeInKb = fileBytes.lengthInBytes / 1024;
        if (sizeInKb > 750) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("File troppo grande per Firestore (Limite 1MB)."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _fileName = pFile.name;
          _fileSize = pFile.size;
          _fileBase64 = base64Encode(fileBytes!);
        });
      }
    }
  }

  IconData _getSportIcon(String sportName) {
    final s = sportName.toLowerCase();
    if (s.contains('pallavolo') || s.contains('volley')) return Icons.sports_volleyball;
    if (s.contains('basket') || s.contains('pallacanestro')) return Icons.sports_basketball;
    if (s.contains('tennis')) return Icons.sports_tennis;
    if (s.contains('rugby')) return Icons.sports_rugby;
    if (s.contains('football')) return Icons.sports_football;
    return Icons.sports_soccer;
  }

  Future<void> _savePost() async {
    final loc = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_titleController.text.trim().isEmpty || _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('error_missing_fields')), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final postData = {
        'groupId': widget.groupId,
        'groupName': widget.groupName,
        'authorId': user.uid,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),

        // Salviamo ENTRAMBI se presenti
        'imageBase64': _imageBase64,
        'fileName': _fileName,
        'fileBase64': _fileBase64,
        'likes': [],
      };

      await FirebaseFirestore.instance.collection('posts').add(postData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('post_created_success')), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      String errorMessage = "Errore durante il salvataggio: $e";
      if (e.toString().contains("larger than 1048576 bytes")) {
        errorMessage = "Limite superato! Il post (testo + immagini) pesa più di 1MB.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('create_post_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // CARD "PUBBLICA IN"
            Text(loc.t('label_publish_in'), style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: colors.primaryContainer.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colors.primary.withOpacity(0.2))),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(backgroundColor: colors.primary, child: Icon(_getSportIcon(widget.groupSport), color: Colors.white)),
                title: Text(widget.groupName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colors.onSurface)),
                subtitle: Text(widget.groupSport, style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
            const SizedBox(height: 24),

            // CAMPI TESTO
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: loc.t('label_post_title'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 5,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                labelText: loc.t('label_post_description'),
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // --- ANTEPRIMA MEDIA ---

            // 1. FOTO
            if (_imageBase64 != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(_imageBase64!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _imageBase64 = null)),
                    ),
                  ),
                ],
              ),

            if (_imageBase64 != null && _fileName != null)
              const SizedBox(height: 16),

            // 2. FILE ALLEGATO
            if (_fileName != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description, color: Colors.red, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_fileName!, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (_fileSize != null)
                            Text("${(_fileSize! / 1024).toStringAsFixed(1)} KB", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() { _fileName = null; _fileBase64 = null; }),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // BOTTONI SCELTA
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_camera),
                    label: Text(loc.t('btn_add_media')),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(loc.t('btn_add_attachment')),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            BigButton(
              text: loc.t('btn_publish'),
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _savePost,
            ),
          ],
        ),
      ),
    );
  }
}