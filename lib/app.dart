import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './features/Authentication/Providers/auth_providers.dart';
import './features/Authentication/Screens/splash_screen.dart';

class RunsysApp extends StatelessWidget {
  const RunsysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Runsys',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      // ✅ This fixes provider availability across all routes
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            // Add future providers here
          ],
          child: child!,
        );
      },
    );
  }
}