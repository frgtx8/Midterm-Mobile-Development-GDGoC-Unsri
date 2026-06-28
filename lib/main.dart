import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for id_ID locale
  await initializeDateFormatting('id_ID', null);

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize dependency injection
  await initDependencies();

  runApp(const MyApp());
}
