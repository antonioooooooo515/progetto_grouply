import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Per decodificare la foto

import '../localization/app_localizations.dart';

class UserProfilePage extends StatelessWidget {
  final String userId;
  final String userName;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.userName,
  });

  // 🔥 FUNZIONE INTELLIGENTE PER L'ICONA DELLO SPORT
  IconData _getSportIcon(String sportName) {
    // Convertiamo in minuscolo per evitare problemi (es. "Calcio" vs "calcio")
    final s = sportName.toLowerCase();

    if (s.contains('pallavolo') || s.contains('volley')) {
      return Icons.sports_volleyball;
    } else if (s.contains('basket') || s.contains('pallacanestro')) {
      return Icons.sports_basketball;
    } else if (s.contains('tennis')) {
      return Icons.sports_tennis;
    } else if (s.contains('rugby')) {
      return Icons.sports_rugby;
    } else if (s.contains('football americano')) {
      return Icons.sports_football;
    } else if (s.contains('golf')) {
      return Icons.sports_golf;
    } else if (s.contains('baseball')) {
      return Icons.sports_baseball;
    } else if (s.contains('pallamano') || s.contains('handball')) {
      return Icons.sports_handball;
    } else if (s.contains('calcio') || s.contains('soccer') || s.contains('football')) {
      return Icons.sports_soccer;
    }

    // Icona generica se lo sport non è riconosciuto
    return Icons.sports_score;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          // 1. Caricamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Errore o Utente non trovato
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Profilo non trovato"));
          }

          // 3. Dati Utente
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String name = data['displayName'] ?? 'Senza nome';
          final String role = data['role'] ?? '-';
          final String sport = data['sport'] ?? '-'; // Se vuoto mette "-"
          final String? profileImageBase64 = data['profileImageBase64'];

          // Costruzione data di nascita
          String birthDate = "-";
          if (data['birthDay'] != null && data['birthMonth'] != null && data['birthYear'] != null) {
            birthDate = "${data['birthDay']} ${data['birthMonth']} ${data['birthYear']}";
          }

          ImageProvider? imageProvider;
          if (profileImageBase64 != null) {
            try {
              imageProvider = MemoryImage(base64Decode(profileImageBase64));
            } catch (_) {}
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // FOTO PROFILO GRANDE
                CircleAvatar(
                  radius: 60,
                  backgroundColor: colors.primary.withOpacity(0.1),
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? Icon(Icons.person, size: 60, color: colors.primary)
                      : null,
                ),
                const SizedBox(height: 24),

                // NOME
                Text(
                  name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // 🔥 ORDINE CAMBIATO: PRIMA LO SPORT
                _buildInfoCard(
                    context,
                    _getSportIcon(sport), // Usa l'icona dinamica qui!
                    loc.t('label_sport'),
                    sport
                ),

                const SizedBox(height: 12),

                // POI IL RUOLO
                _buildInfoCard(
                    context,
                    Icons.person_outline, // Icona generica per il ruolo
                    loc.t('label_role'),
                    role
                ),

                const SizedBox(height: 12),

                // INFINE DATA DI NASCITA
                _buildInfoCard(
                    context,
                    Icons.cake,
                    "Data di nascita", // (Puoi aggiungere questa chiave alle traduzioni se vuoi)
                    birthDate
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String label, String value) {
    // Se il valore è vuoto o "-", rendiamo la card un po' più trasparente
    final isUnknown = (value == '-' || value.isEmpty);
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: isUnknown ? Colors.grey : theme.colorScheme.primary),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isUnknown ? Colors.grey : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}