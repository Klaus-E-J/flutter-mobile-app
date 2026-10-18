import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseInitialized = await FirebaseService.initialize();
  runApp(AvaliaProApp(firebaseInitialized: firebaseInitialized));
}
