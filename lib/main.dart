import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TEMP: wipe upgrader's stored "already alerted" state while testing
  final prefs = await SharedPreferences.getInstance();
  for (final key in prefs.getKeys()) {
    if (key.startsWith('upgrader_')) {
      await prefs.remove(key);
    }
  }

  runApp(const RunsysApp());
}