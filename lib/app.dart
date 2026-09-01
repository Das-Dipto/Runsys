import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';

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
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: UpgradeAlert(
            showIgnore: false,
            showLater: false,
            barrierDismissible: false, // renamed from canDismissDialog
            dialogStyle: UpgradeDialogStyle.material,
            shouldPopScope: () => false, // block back-button dismiss too
            upgrader: Upgrader(
              debugLogging: false,
              messages: UpgraderMessages(code: 'en'),
              // No minAppVersion — always compares against current store version
            ),
            child: child!,
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}