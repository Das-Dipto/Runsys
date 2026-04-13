import 'package:flutter/material.dart';
import 'report_issue_screen.dart';
import 'issue_detail_screen.dart'; // ✅ ADD THIS

class IssuesScreen extends StatelessWidget {
  const IssuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Issues',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.grey.shade100,
            child: const Center(
              child: Text(
                'OPEN MAINTENANCE ISSUES',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildIssueCard(
                  context,
                  title: 'Check Out Maintenance Inspection',
                  reported: 'Apr 1, 2026',
                  scheduled: 'Apr 1, 2026',
                ),
                const SizedBox(height: 12),
                _buildIssueCard(
                  context,
                  title: 'Check Out Maintenance Inspection',
                  reported: 'Mar 25, 2026',
                  scheduled: 'Mar 25, 2026',
                ),
                const SizedBox(height: 12),
                _buildIssueCard(
                  context,
                  title: 'Check Out Maintenance Inspection',
                  reported: 'Mar 3, 2026',
                  scheduled: 'Mar 4, 2026',
                ),
                const SizedBox(height: 12),
                _buildIssueCard(
                  context,
                  title: 'Monthly STR Safety Inspection Checklist',
                  reported: 'Jan 14, 2026',
                  scheduled: 'Jan 16, 2026',
                ),
                const SizedBox(height: 12),
                _buildIssueCard(
                  context,
                  title: 'Annual STR Safety Inspection Checklist',
                  reported: 'Jan 14, 2026',
                  scheduled: 'Jan 16, 2026',
                ),
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    "You've reached the end of your list.",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ReportIssueScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF29B6F6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Report an issue',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(
    BuildContext context, {
    required String title,
    required String reported,
    required String scheduled,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IssueDetailScreen(
            title: title,
            reported: reported,
            scheduled: scheduled,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.flag_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Reported: $reported',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Scheduled: $scheduled',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}