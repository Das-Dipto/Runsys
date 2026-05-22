// lib/Admin/Screens/company_info_screen.dart
import 'package:flutter/material.dart';

class CompanyInfoScreen extends StatelessWidget {
  const CompanyInfoScreen({super.key});

  static const Color _bg      = Color(0xFF0A0A0F);
  static const Color _surface = Color(0xFF111118);
  static const Color _border  = Color(0xFF1E1E2E);
  static const Color _textPri = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: _surface,
                border: Border(bottom: BorderSide(color: _border, width: 1)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: _textPri, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Company Info',
                    style: TextStyle(
                        color: _textPri,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Company Info — coming soon',
                  style: TextStyle(color: Color(0xFF8A8A9A), fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}