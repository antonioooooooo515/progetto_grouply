import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza i formati data per tutte le lingue (IT, ES, FR, ecc.)
  await initializeDateFormatting();

  runApp(const MyApp());
}