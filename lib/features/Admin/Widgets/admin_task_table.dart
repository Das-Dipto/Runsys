// admin_task_table.dart
import 'package:flutter/material.dart';

class _TaskRow {
  final String task;
  final String property;
  final String propertyAddress;
  final String department;
  final String subdepartment;
  final List<String> assignments;
  final String dueDate;
  final String dueDateLabel;
  final bool dueDateRed;
  final int issues;
  final int comments;
  final String status;
  final String priority;
  final String cost;
  final String billTo;
  final String requestedBy;
  final String tags;
  final String createdDate;
  final String createdBy;
  final String dateCompleted;
  final String completedBy;
  final String dateUpdated;

  const _TaskRow({
    required this.task,
    required this.property,
    required this.propertyAddress,
    required this.department,
    required this.subdepartment,
    required this.assignments,
    required this.dueDate,
    required this.dueDateLabel,
    required this.dueDateRed,
    required this.issues,
    required this.comments,
    required this.status,
    required this.priority,
    required this.cost,
    required this.billTo,
    required this.requestedBy,
    required this.tags,
    required this.createdDate,
    required this.createdBy,
    required this.dateCompleted,
    required this.completedBy,
    required this.dateUpdated,
  });
}

final List<_TaskRow> dummyTasks = [
  const _TaskRow(
    task: 'Demo template',
    property: 'Default Property',
    propertyAddress: '',
    department: 'Cleaning',
    subdepartment: 'test',
    assignments: ['Bashir Ahmed'],
    dueDate: 'Due: Sun Apr 5',
    dueDateLabel: 'Sun Apr 5',
    dueDateRed: true,
    issues: 0,
    comments: 0,
    status: 'PENDING',
    priority: 'High',
    cost: '\$120',
    billTo: 'Client A',
    requestedBy: 'Admin',
    tags: 'urgent',
    createdDate: 'Apr 1',
    createdBy: 'John',
    dateCompleted: '-',
    completedBy: '-',
    dateUpdated: 'Apr 2',
  ),
  const _TaskRow(
    task: 'urjent clean',
    property: 'demo properties',
    propertyAddress: 'Dhaka, mohammadpur',
    department: 'Cleaning',
    subdepartment: 'test',
    assignments: ['Bashir Ahmed', 'Bashir Ahmed'],
    dueDate: 'Due: Sun Apr 5',
    dueDateLabel: 'Sun Apr 5',
    dueDateRed: true,
    issues: 0,
    comments: 0,
    status: 'PENDING',
    priority: 'Medium',
    cost: '\$80',
    billTo: 'Client B',
    requestedBy: 'Manager',
    tags: 'clean',
    createdDate: 'Apr 1',
    createdBy: 'Sara',
    dateCompleted: '-',
    completedBy: '-',
    dateUpdated: 'Apr 3',
  ),
  const _TaskRow(
    task: 'Check Out Maintenance Inspection',
    property: '32 Silbury',
    propertyAddress: '897 Silbury Boulevard Milton Keynes',
    department: 'Cleaning',
    subdepartment: 'test',
    assignments: ['Bashir ahmed', 'Rayhan ahmed'],
    dueDate: 'Due: Mon Apr 6',
    dueDateLabel: 'Mon Apr 6',
    dueDateRed: true,
    issues: 1,
    comments: 1,
    status: 'PENDING',
    priority: 'High',
    cost: '\$200',
    billTo: 'Client C',
    requestedBy: 'Admin',
    tags: 'inspection',
    createdDate: 'Apr 2',
    createdBy: 'John',
    dateCompleted: '-',
    completedBy: '-',
    dateUpdated: 'Apr 4',
  ),
  const _TaskRow(
    task: 'Deep Clean Common Areas',
    property: 'Skyline Tower',
    propertyAddress: '45 High Street, Manchester',
    department: 'Cleaning',
    subdepartment: 'Common Areas',
    assignments: ['Sarah Johnson'],
    dueDate: 'Due: Wed Apr 8',
    dueDateLabel: 'Wed Apr 8',
    dueDateRed: false,
    issues: 0,
    comments: 2,
    status: 'IN PROGRESS',
    priority: 'Low',
    cost: '\$150',
    billTo: 'Client D',
    requestedBy: 'Supervisor',
    tags: 'deep-clean',
    createdDate: 'Apr 3',
    createdBy: 'Mike',
    dateCompleted: '-',
    completedBy: '-',
    dateUpdated: 'Apr 5',
  ),
  const _TaskRow(
    task: 'Plumbing Repair — Unit 4B',
    property: 'Riverside Court',
    propertyAddress: '12 River Rd, Birmingham',
    department: 'Maintenance',
    subdepartment: 'Plumbing',
    assignments: ['Mike Torres'],
    dueDate: 'Due: Thu Apr 9',
    dueDateLabel: 'Thu Apr 9',
    dueDateRed: false,
    issues: 2,
    comments: 3,
    status: 'PENDING',
    priority: 'High',
    cost: '\$350',
    billTo: 'Client E',
    requestedBy: 'Tenant',
    tags: 'plumbing',
    createdDate: 'Apr 4',
    createdBy: 'Admin',
    dateCompleted: '-',
    completedBy: '-',
    dateUpdated: 'Apr 6',
  ),
];

// ── Fixed column widths ───────────────────────────────────────────────────────
const List<double> _colWidths = [
  180, // TASK
  150, // PROPERTY
  110, // DEPT
  110, // SUB DEPT
  130, // ASSIGNMENT
  110, // DUE DATE
  80,  // ISSUES
  90,  // COMMENTS
  110, // STATUS
  90,  // PRIORITY
  80,  // COST
  100, // BILL TO
  120, // REQUESTED BY
  100, // TAGS
  90,  // CREATED
  110, // CREATED BY
  100, // COMPLETED
  100, // COMP BY
  100, // UPDATED
];

const List<String> _headers = [
  'TASK',         'PROPERTY',    'DEPT',       'SUB DEPT',
  'ASSIGNMENT',   'DUE DATE',    'ISSUES',     'COMMENTS',
  'STATUS',       'PRIORITY',    'COST',       'BILL TO',
  'REQUESTED BY', 'TAGS',        'CREATED',    'CREATED BY',
  'COMPLETED',    'COMP BY',     'UPDATED',
];

double get _tableWidth => _colWidths.fold(0.0, (double a, double b) => a + b) + 32.0;

class AdminTaskTable extends StatefulWidget {
  const AdminTaskTable({super.key});

  @override
  State<AdminTaskTable> createState() => _AdminTaskTableState();
}

class _AdminTaskTableState extends State<AdminTaskTable> {
  final ScrollController _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Strategy: ONE horizontal SingleChildScrollView wraps a Column
    // that has the header + all rows. The parent (Expanded in dashboard)
    // gives bounded height, so we use a vertical ListView OUTSIDE this
    // widget. But since AdminTaskTable itself is inside Expanded, we use
    // a Column with a fixed-height header + Expanded ListView for rows,
    // all wrapped in one horizontal scroll.
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
              // ── Sticky header ──
              _buildHeader(),

              // ── Scrollable rows ──
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: dummyTasks.length,
                  itemBuilder: (context, index) =>
                      _buildRow(dummyTasks[index], index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────
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
          (i) => SizedBox(
            width: _colWidths[i],
            child: Text(_headers[i], style: style),
          ),
        ),
      ),
    );
  }

  // ── Row ───────────────────────────────────────────────────────────────────────
  Widget _buildRow(_TaskRow task, int index) {
    final isEven = index % 2 == 0;
    const grey12 = TextStyle(color: Color(0xFF8A8A9A), fontSize: 12);
    const white12 = TextStyle(
        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500);

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
          // 0 TASK
          cell(0, _taskCell(task)),
          // 1 PROPERTY
          cell(1, _propertyCell(task)),
          // 2 DEPT
          cell(2, txt(task.department, style: white12)),
          // 3 SUB DEPT
          cell(3, txt(task.subdepartment)),
          // 4 ASSIGNMENT
          cell(4, _assignmentCell(task)),
          // 5 DUE DATE
          cell(5, _dueDateCell(task)),
          // 6 ISSUES
          cell(6, txt('${task.issues} issues')),
          // 7 COMMENTS
          cell(7, txt('${task.comments}')),
          // 8 STATUS
          cell(8, _statusBadge(task.status)),
          // 9 PRIORITY
          cell(9, txt(task.priority)),
          // 10 COST
          cell(10, txt(task.cost)),
          // 11 BILL TO
          cell(11, txt(task.billTo)),
          // 12 REQUESTED BY
          cell(12, txt(task.requestedBy)),
          // 13 TAGS
          cell(13, txt(task.tags)),
          // 14 CREATED
          cell(14, txt(task.createdDate)),
          // 15 CREATED BY
          cell(15, txt(task.createdBy)),
          // 16 COMPLETED
          cell(16, txt(task.dateCompleted)),
          // 17 COMP BY
          cell(17, txt(task.completedBy)),
          // 18 UPDATED
          cell(18, txt(task.dateUpdated)),
        ],
      ),
    );
  }

  Widget _taskCell(_TaskRow t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.task,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            t.dueDate,
            style: const TextStyle(color: Color(0xFF8A8A9A), fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );

  Widget _propertyCell(_TaskRow t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.property,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (t.propertyAddress.isNotEmpty)
            Text(
              t.propertyAddress,
              style:
                  const TextStyle(color: Color(0xFF8A8A9A), fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      );

  Widget _assignmentCell(_TaskRow t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: t.assignments
            .map((a) => Text(
                  a,
                  style: const TextStyle(
                      color: Color(0xFF8A8A9A), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ))
            .toList(),
      );

  Widget _dueDateCell(_TaskRow t) => Row(
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
              t.dueDateLabel,
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

  Widget _statusBadge(String status) {
    Color color = const Color(0xFFFF7300);
    if (status == 'IN PROGRESS') color = Colors.green;
    if (status == 'COMPLETED') color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w700),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}