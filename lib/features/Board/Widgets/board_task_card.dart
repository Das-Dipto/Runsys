import 'package:flutter/material.dart';
import 'board_card_dialog.dart';

class BoardTaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final bool isGrid;

  const BoardTaskCard({
    super.key,
    required this.task,
    required this.isGrid,
  });

  Color _priorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT': return const Color(0xFFFF6B6B);
      case 'HIGH':   return const Color(0xFFFF7300);
      case 'MEDIUM': return const Color(0xFF1E88E5);
      default:       return const Color(0xFF8A8A9A);
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':   return const Color(0xFF43A047);
      case 'IN_PROGRESS': return const Color(0xFFFF7300);
      case 'OVERDUE':     return const Color(0xFFFF6B6B);
      default:            return const Color(0xFF1E88E5);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '—';
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final String status     = (task['status'] as String? ?? '').toUpperCase();
    final bool isOverdue    = task['is_overdue'] == true;
    final bool isCompleted  = status == 'COMPLETED';
    final Color accentColor = isOverdue ? const Color(0xFFFF6B6B) : _statusColor(status);

    final List labels    = task['labels'] as List? ?? [];
    final int comments   = (task['comment_count'] as num?)?.toInt() ?? 0;

    final List assignees     = task['assignees'] as List? ?? [];
    final String? assignedAt = assignees.isNotEmpty
        ? assignees[0]['assigned_at'] as String?
        : null;

    return GestureDetector(
      onTap: () => BoardCardDialog.show(context, task),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111118),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E1E2E)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 4, color: accentColor),
            Padding(
              padding: EdgeInsets.all(isGrid ? 12 : 14),
              child: isGrid
                  ? _gridContent(isOverdue, isCompleted, labels, comments, assignedAt)
                  : _listContent(isOverdue, isCompleted, labels, comments, assignedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridContent(
    bool isOverdue,
    bool isCompleted,
    List labels,
    int comments,
    String? assignedAt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title row: title left, assigned date right ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                task['title'] as String? ?? '',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: const Color(0xFF8A8A9A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (assignedAt != null) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Assign Date',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF8A8A9A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(assignedAt),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF8A8A9A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (isCompleted) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: Color(0xFF43A047)),
            ],
          ],
        ),

        const SizedBox(height: 8),

        // Labels
        if (labels.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: labels
                .take(2)
                .map<Widget>((l) => _Tag(
                      label: l['name']?.toString() ?? '',
                      colorName: l['color']?.toString(),
                    ))
                .toList(),
          ),

        const SizedBox(height: 10),

        // Bottom row: overdue/pending + comments
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 13,
              color: isOverdue
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFF8A8A9A),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                isOverdue
                    ? 'Overdue'
                    : isCompleted
                        ? 'Completed'
                        : 'Pending',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isOverdue
                      ? const Color(0xFFFF6B6B)
                      : isCompleted
                          ? const Color(0xFF43A047)
                          : const Color(0xFFFF7300),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (comments > 0) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 13, color: Color(0xFF8A8A9A)),
              const SizedBox(width: 3),
              Text('$comments',
                  style: const TextStyle(
                      fontSize: 11.5, color: Color(0xFF8A8A9A))),
            ],
          ],
        ),
      ],
    );
  }

  Widget _listContent(
    bool isOverdue,
    bool isCompleted,
    List labels,
    int comments,
    String? assignedAt,
  ) {
    final String priority = task['priority'] as String? ?? 'MEDIUM';
    final String board    = task['board_name'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title row: title left, assigned date right ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority + board
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _priorityColor(priority).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          priority,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _priorityColor(priority),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          board,
                          style: const TextStyle(
                              fontSize: 11.5, color: Color(0xFF8A8A9A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    task['title'] as String? ?? '',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: const Color(0xFF8A8A9A),
                    ),
                  ),
                ],
              ),
            ),
            // Assigned date — top right
            if (assignedAt != null) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Assign Date',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8A8A9A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(assignedAt),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF8A8A9A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (isCompleted) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded,
                  size: 24, color: Color(0xFF43A047)),
            ],
          ],
        ),

        const SizedBox(height: 10),

        // Labels
        if (labels.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: labels
                .map<Widget>((l) => _Tag(
                      label: l['name']?.toString() ?? '',
                      colorName: l['color']?.toString(),
                    ))
                .toList(),
          ),

        if (labels.isNotEmpty) const SizedBox(height: 10),

        // Bottom meta row
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 13,
              color: isOverdue
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFF8A8A9A),
            ),
            const SizedBox(width: 4),
            Text(
              isOverdue
                  ? 'Overdue'
                  : isCompleted
                      ? 'Completed'
                      : 'Pending',
              style: TextStyle(
                fontSize: 12,
                color: isOverdue
                    ? const Color(0xFFFF6B6B)
                    : isCompleted
                        ? const Color(0xFF43A047)
                        : const Color(0xFFFF7300),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (comments > 0) ...[
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 13, color: Color(0xFF8A8A9A)),
              const SizedBox(width: 4),
              Text('$comments',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF8A8A9A))),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Tag chip ──
class _Tag extends StatelessWidget {
  final String label;
  final String? colorName;

  const _Tag({required this.label, this.colorName});

  static const _namedColors = {
    'blue':   Color(0xFF42A5F5),
    'pink':   Color(0xFFEC407A),
    'red':    Color(0xFFEF5350),
    'green':  Color(0xFF66BB6A),
    'yellow': Color(0xFFFFCA28),
    'purple': Color(0xFFAB47BC),
    'teal':   Color(0xFF26A69A),
    'orange': Color(0xFFFF7300),
  };

  static const _fallbackColors = [
    Color(0xFF5C6BC0),
    Color(0xFFAB47BC),
    Color(0xFF26A69A),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
  ];

  Color get _color {
    if (colorName != null) {
      final named = _namedColors[colorName!.toLowerCase()];
      if (named != null) return named;
    }
    return _fallbackColors[label.hashCode.abs() % _fallbackColors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}