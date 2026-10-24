import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'data/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian locale for date formatting
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('[SETOKE.SU] Date formatting init warning: $e');
  }

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
    debugPrint('[SETOKE.SU] Supabase connected successfully.');
  } catch (e) {
    debugPrint('[SETOKE.SU] Supabase initialization error: $e');
  }

  runApp(const SetokeApp());
}
