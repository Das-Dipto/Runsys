import 'package:flutter/material.dart';
import 'report_issue_screen.dart';

class ElementDetailScreen extends StatefulWidget {
  final String title;

  const ElementDetailScreen({super.key, required this.title});

  @override
  State<ElementDetailScreen> createState() => _ElementDetailScreenState();
}

class _ElementDetailScreenState extends State<ElementDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text('Ed...', style: TextStyle(color: Color(0xFF29B6F6), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF29B6F6),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF29B6F6),
            tabs: const [
              Tab(text: 'OVERVIEW'),
              Tab(text: 'ABOUT'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // OVERVIEW Tab
                _buildOverviewTab(),

                // ABOUT Tab
                const Center(
                  child: Text(
                    'No about information for this item.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const Text('No photos yet.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          const Text('Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const Text('No documents yet.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          const Text('NO MAINTENANCE ISSUES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 20),

  Center(
  child: Column(
    children: [
      Icon(
        Icons.celebration,           // ← Correct icon
        size: 80,
        color: Colors.grey.shade300,
      ),
      const SizedBox(height: 16),
      const Text(
        'There are currently no issues reported',
        style: TextStyle(color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    ],
  ),
),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // Open Report Issue Screen
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssueScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF29B6F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Report an issue',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}