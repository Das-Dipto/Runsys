// lib/Admin/Widgets/assigned_task_table.dart
import 'package:flutter/material.dart';
import '../../../Api/api_controller.dart';

import 'package:provider/provider.dart';
import '../../../Authentication/Providers/auth_providers.dart';
import '../../Dashboard/Widgets/task_detail_dialog.dart';
import '../../../Models/task_model.dart';
import '../../../Task/screens/task_detail_screen.dart';

// ── Model (mapped from API) ─────────────────────────────────────────────────
class AssignedTaskRow {
  final String taskTitle;
  final String priority;
  final List<String> tags;
  final String property;
  final String propertyAddress;
  final List<String> assigneeNames;   // ✅ changed from single name
  final String assigneeDept;
  final String assignedAt;
  final String dueDate;
  final bool dueDateRed;
  final String assignedBy;
  final String status;
  final Map<String, dynamic> raw;

  const AssignedTaskRow({
    required this.taskTitle,
    required this.priority,
    required this.tags,
    required this.property,
    required this.propertyAddress,
    required this.assigneeNames,
    required this.assigneeDept,
    required this.assignedAt,
    required this.dueDate,
    required this.dueDateRed,
    required this.assignedBy,
    required this.status,
    required this.raw,
  });


  factory AssignedTaskRow.fromJson(Map<String, dynamic> item) {
    final assignedAtDt = item['assigned_at'] != null
        ? DateTime.tryParse(item['assigned_at'])?.toLocal()
        : null;
    final dueDt = item['due_date'] != null
        ? DateTime.tryParse(item['due_date'])?.toLocal()
        : null;

    final assigneeList = (item['assignee_details'] is List)
        ? (item['assignee_details'] as List)
        : [];

    return AssignedTaskRow(
      taskTitle: item['title'] ?? 'Untitled Task',
      priority: (item['priority']?.toString() ?? 'MEDIUM'),
      tags: item['tags'] != null
          ? List<String>.from((item['tags'] as List).map((t) => t.toString()))
          : [],
      property: item['property_name'] ?? '',
      propertyAddress: item['property_address'] ?? '',
      assigneeNames: assigneeList
          .map<String>((a) => a['full_name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList(),
      assigneeDept: assigneeList.isNotEmpty
          ? (assigneeList.first['department_name']?.toString() ?? item['department_name'] ?? '')
          : (item['department_name'] ?? ''),
      assignedAt: assignedAtDt != null ? assignedAtDt.toString().split(' ')[0] : '-',
      dueDate: dueDt != null ? dueDt.toString().split(' ')[0] : '-',
      dueDateRed: dueDt != null && dueDt.isBefore(DateTime.now()),
      assignedBy: item['created_by_name'] ?? '',
      status: (item['assignment_status']?.toString() ?? item['status']?.toString() ?? 'PENDING').toUpperCase(),
      raw: item,
    );
  }

}

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
  final void Function(int total, int pending, int completed)? onCountsLoaded;
  final String? searchQuery;
  const AssignedTaskTable({super.key, this.onCountsLoaded, this.searchQuery});

  @override
  State<AssignedTaskTable> createState() => _AssignedTaskTableState();
}

class _AssignedTaskTableState extends State<AssignedTaskTable> {
  final ScrollController _hScroll = ScrollController();

  bool _isLoading = true;
  String? _errorMessage;
  List<AssignedTaskRow> _tasks = [];

  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  @override
void didUpdateWidget(covariant AssignedTaskTable oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.searchQuery != widget.searchQuery) {
    _fetchTasks(page: 1);
  }
}

bool _isMyTask(AssignedTaskRow task, int myUserId) {
  final assignees = task.raw['assignee_details'] as List? ?? [];
  return assignees.any((a) => (a['id'] as num?)?.toInt() == myUserId);
}

Future<void> _fetchTasks({int? page}) async {
 setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  final result = await ApiController.getAssignedTasks(
    page: page ?? _currentPage,
    search: widget.searchQuery,
  );


  if (result['success'] == true) {
    final List<dynamic> apiData = result['data'];
    final meta = result['meta'];

    final mapped = apiData
        .map((item) => AssignedTaskRow.fromJson(item as Map<String, dynamic>))
        .toList();

    setState(() {
      _tasks = mapped;
      _isLoading = false;
      _currentPage = meta?['current_page'] ?? (page ?? _currentPage);
      _totalPages = meta?['total_pages'] ?? 1;
    });

    // ✅ counts logic goes here, after meta exists
    final counts = meta?['counts'];
    if (counts != null) {
      widget.onCountsLoaded?.call(
        counts['total'] ?? 0,
        counts['pending'] ?? 0,
        counts['completed'] ?? 0,
      );
    }
  } else {
    setState(() {
      _errorMessage = result['message'] ?? 'Failed to load assigned tasks';
      _isLoading = false;
    });
  }
}
  void _goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    _fetchTasks(page: page);
  }

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => _fetchTasks(), child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return const Center(
        child: Text('No assigned tasks', style: TextStyle(color: Color(0xFF8A8A9A))),
      );
    }

    return Scrollbar(
      controller: _hScroll,
      thumbVisibility: true,
      trackVisibility: true,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _hScroll,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _tableWidth,
                child:
                 Column(
  children: [
    _buildHeader(),
    Expanded(   // ✅ takes only the remaining, actual space
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _tasks.length,
        itemBuilder: (context, i) => _buildRow(_tasks[i], i),
      ),
    ),
  ],
),



              ),
            ),
          ),
          _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildPaginationBar() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF16161F),
        border: Border(top: BorderSide(color: Color(0xFF1E1E2E))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF8A8A9A)),
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
          ),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_totalPages, (i) {
                  final pageNum = i + 1;
                  final isActive = pageNum == _currentPage;
                  return GestureDetector(
                    onTap: () => _goToPage(pageNum),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFFF7300) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive ? const Color(0xFFFF7300) : const Color(0xFF1E1E2E),
                        ),
                      ),
                      child: Text(
                        '$pageNum',
                        style: TextStyle(
                          color: isActive ? Colors.white : const Color(0xFF8A8A9A),
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A8A9A)),
            onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
          ),
        ],
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

Widget _buildRow(AssignedTaskRow task, int index) {
  final isEven = index % 2 == 0;
  const grey12 = TextStyle(color: Color(0xFF8A8A9A), fontSize: 12);

  Widget cell(int i, Widget child) => SizedBox(width: _colWidths[i], child: child);
  Widget txt(String s, {TextStyle style = grey12}) => Text(
        s,
        style: style,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );

  // ✅ check ownership before building the row
  final myUserId = context.read<AuthProvider>().user?.id ?? 0;
  final isMine = _isMyTask(task, myUserId);

  return GestureDetector(
    onTap: () async {
      if (isMine) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(
              task: TaskModel.fromJson(task.raw, currentUserId: myUserId),
            ),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => TaskDetailDialog(
            title: task.taskTitle,
            property: task.property,
            propertyAddress: task.propertyAddress,
            department: task.assigneeDept,
            subDepartment: '',
            assignees: task.assigneeNames,
            dueDateLabel: task.dueDate,
            status: task.status,
            priority: task.priority,
            createdBy: task.assignedBy,
            createdDate: task.assignedAt,
            updatedDate: task.dueDate,
            comments: 0,
          ),
        );
      }
    },
    child: Container(
      padding: EdgeInsets.only(
        left: isMine ? 13 : 16,   // ✅ compensate for the 3px left border
        right: 16,
        top: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: isMine
            ? const Color(0xFFFF7300).withOpacity(0.08)
            : (isEven ? const Color(0xFF0A0A0F) : const Color(0xFF16161F).withOpacity(0.6)),
        border: Border(
          bottom: const BorderSide(color: Color(0xFF1E1E2E), width: 0.5),
          left: isMine
              ? const BorderSide(color: Color(0xFFFF7300), width: 3)
              : BorderSide.none,
        ),
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
    ),
  );
}

Widget _taskDetailsCell(AssignedTaskRow t) {
    Color priorityColor = const Color(0xFFFF7300);
    if (t.priority.toUpperCase() == 'HIGH') priorityColor = Colors.deepOrange;
    if (t.priority.toUpperCase() == 'MEDIUM') priorityColor = Colors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 6, top: 2),
              decoration: BoxDecoration(shape: BoxShape.circle, color: priorityColor),
            ),
            Expanded(
              child: Text(
                t.taskTitle,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
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
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
      );

  Widget _propertyCell(AssignedTaskRow t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.business_rounded, color: Color(0xFF8A8A9A), size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  t.property,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
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
                  const Icon(Icons.location_on_outlined, color: Color(0xFF8A8A9A), size: 11),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      t.propertyAddress,
                      style: const TextStyle(color: Color(0xFF8A8A9A), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );

  Widget _assigneeCell(AssignedTaskRow t) => Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0x22FF7300),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFF7300).withOpacity(0.35)),
          ),
          child: Center(
            child: Text(
              t.assigneeNames.isNotEmpty ? t.assigneeNames.first[0].toUpperCase() : '?',
              style: const TextStyle(color: Color(0xFFFF7300), fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ show every assignee name, one per line
              ...t.assigneeNames.map((name) => Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
              if (t.assigneeDept.isNotEmpty)
                Text(
                  t.assigneeDept,
                  style: const TextStyle(color: Color(0xFF8A8A9A), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );

  Widget _dueDateCell(AssignedTaskRow t) => Row(
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
                color: t.dueDateRed ? Colors.red : const Color(0xFF8A8A9A),
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