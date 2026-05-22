// task_detail_dialog.dart
import 'package:flutter/material.dart';

class TaskDetailDialog extends StatelessWidget {
  // Individual fields instead of whole TaskRow
  final String title;
  final String property;
  final String propertyAddress;
  final String department;
  final String subDepartment;
  final List<String> assignees;
  final String dueDateLabel;
  final String status;
  final String priority;
  final String createdBy;
  final String createdDate;
  final String updatedDate;
  final int comments;

  const TaskDetailDialog({
    super.key,
    required this.title,
    required this.property,
    required this.propertyAddress,
    required this.department,
    required this.subDepartment,
    required this.assignees,
    required this.dueDateLabel,
    required this.status,
    required this.priority,
    required this.createdBy,
    required this.createdDate,
    required this.updatedDate,
    required this.comments,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111118),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.task_alt_rounded, color: Color(0xFFFF7300), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF1E1E2E), height: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Property', property),
                    if (propertyAddress.isNotEmpty)
                      _buildInfoRow('Address', propertyAddress),

                    const SizedBox(height: 16),
                    _buildInfoRow('Department', department),
                    _buildInfoRow('Sub Department', subDepartment.isEmpty ? 'N/A' : subDepartment),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildBadge('Status', status)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildBadge('Priority', priority)),
                      ],
                    ),

                    const SizedBox(height: 20),
                    _buildInfoRow('Due Date', dueDateLabel.isNotEmpty ? dueDateLabel : 'Not Set'),

                    if (assignees.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text('Assignees', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...assignees.map((assignee) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(assignee, style: const TextStyle(color: Colors.white)),
                        ),
                      )),
                    ],

                    const SizedBox(height: 24),
                    const Text('Description', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      title, // You can pass real description later
                      style: const TextStyle(color: Color(0xFF8A8A9A), height: 1.5),
                    ),

                    const SizedBox(height: 24),
                    _buildInfoRow('Created By', createdBy),
                    _buildInfoRow('Created Date', createdDate),
                    _buildInfoRow('Updated', updatedDate),
                    _buildInfoRow('Comments', comments.toString()),
                  ],
                ),
              ),
            ),

            // Bottom Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Color(0xFF1E1E2E)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Color(0xFF8A8A9A), fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, String value) {
    Color color = const Color(0xFFFF7300);
    if (value == 'IN PROGRESS') color = Colors.green;
    if (value == 'COMPLETED') color = Colors.blue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8A8A9A), fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}