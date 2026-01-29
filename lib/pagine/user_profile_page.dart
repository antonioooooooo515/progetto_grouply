import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import '../localization/app_localizations.dart';

class UserProfilePage extends StatelessWidget {
  final String userId;
  final String userName;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.userName,
  });

  IconData _getSportIcon(String sportName) {
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(loc.t('profile_not_found')));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String name = data['displayName'] ?? loc.t('without_name');
          final String role = data['role'] ?? '-';
          final String sport = data['sport'] ?? '-'; // Se vuoto mette "-"
          final String? profileImageBase64 = data['profileImageBase64'];

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
                //FOTO PROFILO
                CircleAvatar(
                  radius: 60,
                  backgroundColor: colors.primary.withOpacity(0.1),
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? Icon(Icons.person, size: 60, color: colors.primary)
                      : null,
                ),
                const SizedBox(height: 24),

                //NOME
                Text(
                  name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                //SPORT
                _buildInfoCard(
                    context,
                    _getSportIcon(sport),
                    loc.t('label_sport'),
                    sport
                ),

                const SizedBox(height: 12),

                //RUOLO
                _buildInfoCard(
                    context,
                    Icons.person_outline,
                    loc.t('label_role'),
                    role
                ),

                const SizedBox(height: 12),

                //DATA DI NASCITA
                _buildInfoCard(
                    context,
                    Icons.cake,
                    loc.t('birth_date'),
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