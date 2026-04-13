import 'package:flutter/material.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  bool _completed = false;

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
          '2 Chelsea · #2 On...',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Priority Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: const [
                    _PriorityChip(label: 'LOWEST', color: Colors.purple),
                    SizedBox(width: 8),
                    _PriorityChip(label: 'LOW', color: Colors.blue),
                    SizedBox(width: 8),
                    _PriorityChip(label: 'MEDIUM', color: Color(0xFF29B6F6), selected: true),
                    SizedBox(width: 8),
                    _PriorityChip(label: 'HIGH', color: Colors.orange),
                    SizedBox(width: 8),
                    _PriorityChip(label: 'URGENT', color: Colors.red),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const ListTile(
                leading: Icon(Icons.build_outlined),
                title: Text('Maintenance'),
                trailing: Icon(Icons.keyboard_arrow_down),
              ),

              const Divider(),
              const ListTile(
                leading: Icon(Icons.error_outline, color: Colors.red),
                title: Text('Title (required)'),
                subtitle: Text('Task title is required.', style: TextStyle(color: Colors.red)),
              ),

              const Divider(),
              const ListTile(
                leading: Icon(Icons.subject),
                title: Text('Description'),
              ),

              const Divider(),
              const ListTile(
                leading: Icon(Icons.widgets_outlined),
                title: Text('Select element'),
                trailing: Icon(Icons.keyboard_arrow_down),
              ),

              const Divider(),
              const ListTile(
                leading: Icon(Icons.attach_file),
                title: Text('Add attachment'),
              ),

              const Divider(),
              CheckboxListTile(
                value: _completed,
                onChanged: (val) => setState(() => _completed = val!),
                title: const Text('I completed this issue'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Report',
                    style: TextStyle(fontSize: 17, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;

  const _PriorityChip({required this.label, required this.color, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        border: Border.all(color: selected ? color : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}