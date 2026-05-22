// lib/Admin/Widgets/assigned_task_table.dart
import 'package:flutter/material.dart';

// ── Dummy model ───────────────────────────────────────────────────────────────
class _AssignedTaskRow {
  final String taskTitle;
  final String priority;
  final List<String> tags;
  final String property;
  final String propertyAddress;
  final String assigneeName;
  final String assigneeDept;
  final String assignedAt;
  final String dueDate;
  final bool dueDateRed;
  final String assignedBy;
  final String status;

  const _AssignedTaskRow({
    required this.taskTitle,
    required this.priority,
    required this.tags,
    required this.property,
    required this.propertyAddress,
    required this.assigneeName,
    required this.assigneeDept,
    required this.assignedAt,
    required this.dueDate,
    required this.dueDateRed,
    required this.assignedBy,
    required this.status,
  });
}

final List<_AssignedTaskRow> _dummyAssigned = [
  const _AssignedTaskRow(
    taskTitle: 'deep clean',
    priority: 'Urgent',
    tags: ['Cash Collection'],
    property: 'demo properties',
    propertyAddress: 'Dhaka, mohammadpur',
    assigneeName: 'Bashir Ahmed',
    assigneeDept: 'Cleaning',
    assignedAt: 'Mar 1, 2026',
    dueDate: 'Mar 4, 2026',
    dueDateRed: true,
    assignedBy: 'Admin',
    status: 'Pending',
  ),
  const _AssignedTaskRow(
    taskTitle: 'Demo template',
    priority: 'Urgent',
    tags: ['VIP Guest', 'Safety'],
    property: 'demo properties',
    propertyAddress: 'Dhaka, mohammadpur',
    assigneeName: 'Bashir Ahmed',
    assigneeDept: 'Cleaning',
    assignedAt: 'Mar 5, 2026',
    dueDate: 'Mar 17, 2026',
    dueDateRed: false,
    assignedBy: 'Admin',
    status: 'In Progress',
  ),
  const _AssignedTaskRow(
    taskTitle: 'Check Out Inspection',
    priority: 'High',
    tags: ['Inspection'],
    property: '32 Silbury',
    propertyAddress: '897 Silbury Boulevard',
    assigneeName: 'Rayhan Ahmed',
    assigneeDept: 'Maintenance',
    assignedAt: 'Mar 10, 2026',
    dueDate: 'Mar 20, 2026',
    dueDateRed: false,
    assignedBy: 'Manager',
    status: 'Pending',
  ),
  const _AssignedTaskRow(
    taskTitle: 'Plumbing Repair',
    priority: 'High',
    tags: ['Plumbing'],
    property: 'Riverside Court',
    propertyAddress: '12 River Rd, Birmingham',
    assigneeName: 'Mike Torres',
    assigneeDept: 'Maintenance',
    assignedAt: 'Mar 12, 2026',
    dueDate: 'Mar 25, 2026',
    dueDateRed: false,
    assignedBy: 'Admin',
    status: 'Pending',
  ),
];

// ── Column config ─────────────────────────────────────────────────────────────
const List<double> _colWidths = [
  200, // TASK DETAILS
  160, // PROPERTY
  150, // ASSIGNEE
  120, // ASSIGNED AT
  130, // DUE DATE
  120, // ASSIGNED BY
];

const List<String> _headers = [
  'TASK DETAILS',
  'PROPERTY',
  'ASSIGNEE',
  'ASSIGNED AT',
  'DUE DATE',
  'ASSIGNED BY',
];

double get _tableWidth =>
    _colWidths.fold(0.0, (double a, double b) => a + b) + 32.0;

// ── Widget ────────────────────────────────────────────────────────────────────
class AssignedTaskTable extends StatefulWidget {
  const AssignedTaskTable({super.key});

  @override
  State<AssignedTaskTable> createState() => _AssignedTaskTableState();
}

class _AssignedTaskTableState extends State<AssignedTaskTable> {
  final ScrollController _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _hScroll,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _hScroll,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _tableWidth,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _dummyAssigned.length,
                  itemBuilder: (context, i) =>
                      _buildRow(_dummyAssigned[i], i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    const style = TextStyle(
      color: Color(0xFF8A8A9A),
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF16161F),
        border: Border(
          top: BorderSide(color: Color(0xFF1E1E2E)),
          bottom: BorderSide(color: Color(0xFF1E1E2E)),
        ),
      ),
      child: Row(
        children: List.generate(
          _headers.length,
          (i) => SizedBox(width: _colWidths[i], child: Text(_headers[i], style: style)),
        ),
      ),
    );
  }

  Widget _buildRow(_AssignedTaskRow task, int index) {
    final isEven = index % 2 == 0;
    const grey12 = TextStyle(color: Color(0xFF8A8A9A), fontSize: 12);

    Widget cell(int i, Widget child) =>
        SizedBox(width: _colWidths[i], child: child);

    Widget txt(String s, {TextStyle style = grey12}) => Text(
          s,
          style: style,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEven
            ? const Color(0xFF0A0A0F)
            : const Color(0xFF16161F).withOpacity(0.6),
        border: const Border(
            bottom: BorderSide(color: Color(0xFF1E1E2E), width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cell(0, _taskDetailsCell(task)),
          cell(1, _propertyCell(task)),
          cell(2, _assigneeCell(task)),
          cell(3, txt(task.assignedAt)),
          cell(4, _dueDateCell(task)),
          cell(5, txt(task.assignedBy)),
        ],
      ),
    );
  }

  Widget _taskDetailsCell(_AssignedTaskRow t) {
    Color priorityColor = const Color(0xFFFF7300);
    if (t.priority == 'High') priorityColor = Colors.deepOrange;
    if (t.priority == 'Medium') priorityColor = Colors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Red urgent dot + title
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 6, top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: priorityColor,
              ),
            ),
            Expanded(
              child: Text(
                t.taskTitle,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Priority + tags row
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _miniChip(t.priority, priorityColor),
            ...t.tags.map((tag) => _miniChip(tag, const Color(0xFF8A8A9A))),
          ],
        ),
      ],
    );
  }

  Widget _miniChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w500),
        ),
      );

  Widget _propertyCell(_AssignedTaskRow t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.business_rounded,
                  color: Color(0xFF8A8A9A), size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  t.property,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (t.propertyAddress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 17),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: Color(0xFF8A8A9A), size: 11),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      t.propertyAddress,
                      style: const TextStyle(
                          color: Color(0xFF8A8A9A), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );

  Widget _assigneeCell(_AssignedTaskRow t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0x22FF7300),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: const Color(0xFFFF7300).withOpacity(0.35)),
            ),
            child: Center(
              child: Text(
                t.assigneeName.isNotEmpty
                    ? t.assigneeName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Color(0xFFFF7300),
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.assigneeName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  t.assigneeDept,
                  style: const TextStyle(
                      color: Color(0xFF8A8A9A), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _dueDateCell(_AssignedTaskRow t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            color: t.dueDateRed ? Colors.red : const Color(0xFF8A8A9A),
            size: 13,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              t.dueDate,
              style: TextStyle(
                color:
                    t.dueDateRed ? Colors.red : const Color(0xFF8A8A9A),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
}