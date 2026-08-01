// admin_task_table.dart
import 'package:Runsys/features/Authentication/Providers/auth_providers.dart';
import 'package:flutter/material.dart';
import '../../../Api/api_controller.dart'; 
import './task_detail_dialog.dart';  
import '../../../Models/task_model.dart';
import '../../../Task/screens/task_detail_screen.dart';
import 'package:provider/provider.dart';


class TaskRow {
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
  final Map<String, dynamic> raw;   // ← add this

  const TaskRow({
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
    required this.raw,
  });
}

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
  final String? searchQuery;
 final DateTime? fromDate;
  final DateTime? toDate;
  final List<String>? statuses;

  const AdminTaskTable({super.key, this.searchQuery, this.fromDate, this.toDate, this.statuses});

  @override
  State<AdminTaskTable> createState() => _AdminTaskTableState();
}

class _AdminTaskTableState extends State<AdminTaskTable> {
  final ScrollController _hScroll = ScrollController();

  bool _isLoading = true;
  String? _errorMessage;
  List<TaskRow> _tasks = [];   // ← Fixed

  int _currentPage = 1;
int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  @override
void didUpdateWidget(covariant AdminTaskTable oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.fromDate != widget.fromDate ||
      oldWidget.toDate != widget.toDate ||
      oldWidget.statuses != widget.statuses) {
    _fetchTasks();
  }
}

bool _isMyTask(TaskRow task, int myUserId) {
  final assignees = task.raw['assignee_details'] as List? ?? [];
  return assignees.any((a) => (a['id'] as num?)?.toInt() == myUserId);
}

  Future<void> _fetchTasks({int? page}) async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

    final result = (widget.searchQuery != null && widget.searchQuery!.isNotEmpty)
      ? await ApiController.searchTasks(widget.searchQuery!)
      : await ApiController.getAllTasks(page: page ?? _currentPage);

  if (result['success'] == true) {
    final List<dynamic> apiData = result['data'];
    final meta = result['meta'];

      final List<TaskRow> mappedTasks = apiData.map((item) {
        final dueDateTime = item['due_date'] != null 
            ? DateTime.parse(item['due_date']).toLocal() 
            : null;

        return TaskRow(   // ← Fixed
          task: item['title'] ?? 'Untitled Task',
          property: item['property_name'] ?? '',
          propertyAddress: item['property_address'] ?? '',
          department: item['department_name'] ?? '',
          subdepartment: item['subdepartment_name'] ?? '',
          assignments: item['assignee_details'] != null
              ? (item['assignee_details'] as List)
                  .map<String>((a) => a['full_name']?.toString() ?? '')
                  .where((name) => name.isNotEmpty)
                  .toList()
              : [],
          dueDate: dueDateTime != null ? 'Due: ${dueDateTime.toString().split(' ')[0]}' : 'No Due',
          dueDateLabel: dueDateTime != null ? dueDateTime.toString().split(' ')[0] : '',
          dueDateRed: dueDateTime != null && dueDateTime.isBefore(DateTime.now()),
          issues: 0,
          comments: item['comments_count'] ?? 0,
          status: (item['status']?.toString() ?? 'PENDING').toUpperCase(),
          priority: (item['priority']?.toString() ?? 'MEDIUM').toUpperCase(),
          cost: '\$0',
          billTo: '',
          requestedBy: item['requested_by'] ?? item['created_by_name'] ?? '',
          tags: item['tags'] != null && (item['tags'] as List).isNotEmpty
              ? (item['tags'] as List).join(', ')
              : '',
          createdDate: item['created_at'] != null
              ? DateTime.parse(item['created_at']).toLocal().toString().split(' ')[0]
              : '',
          createdBy: item['created_by_name'] ?? '',
          dateCompleted: item['status'] == 'COMPLETED' ? 'Completed' : '-',
          completedBy: '',
          dateUpdated: item['updated_at'] != null
              ? DateTime.parse(item['updated_at']).toLocal().toString().split(' ')[0]
              : '',
          raw: item as Map<String, dynamic>,   // ← add this
        );
      }).toList();

     setState(() {
      _tasks = mappedTasks;
      _isLoading = false;
      _currentPage = meta?['current_page'] ?? (page ?? _currentPage);
      _totalPages = meta?['total_pages'] ?? 1;
    });
  } else {
    setState(() {
      _errorMessage = result['message'] ?? 'Failed to load tasks';
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
            ElevatedButton(onPressed: _fetchTasks, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return const Center(child: Text('No tasks available'));
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
            child: Column(
  children: [
    _buildHeader(),
    Expanded(   // ✅ fills remaining space instead of guessing a height
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _tasks.length,
        itemBuilder: (context, index) => _buildRow(_tasks[index], index),
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

Widget _buildRow(TaskRow task, int index) {
  final isEven = index % 2 == 0;
  const grey12 = TextStyle(color: Color(0xFF8A8A9A), fontSize: 12);
  const white12 = TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500);

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
            title: task.task,
            property: task.property,
            propertyAddress: task.propertyAddress,
            department: task.department,
            subDepartment: task.subdepartment,
            assignees: task.assignments,
            dueDateLabel: task.dueDateLabel,
            status: task.status,
            priority: task.priority,
            createdBy: task.createdBy,
            createdDate: task.createdDate,
            updatedDate: task.dateUpdated,
            comments: task.comments,
          ),
        );
      }
    },
    child: 
   Container(
  padding: EdgeInsets.only(
    left: isMine ? 13 : 16,   // ✅ compensate for the 3px border
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
      cell(0, _taskCell(task)),
      cell(1, _propertyCell(task)),
      cell(2, txt(task.department, style: white12)),
      cell(3, txt(task.subdepartment)),
      cell(4, _assignmentCell(task)),
      cell(5, _dueDateCell(task)),
      cell(6, txt('${task.issues} issues')),
      cell(7, txt('${task.comments}')),
      cell(8, _statusBadge(task.status)),
      cell(9, txt(task.priority)),
      cell(10, txt(task.cost)),
      cell(11, txt(task.billTo)),
      cell(12, txt(task.requestedBy)),
      cell(13, txt(task.tags)),
      cell(14, txt(task.createdDate)),
      cell(15, txt(task.createdBy)),
      cell(16, txt(task.dateCompleted)),
      cell(17, txt(task.completedBy)),
      cell(18, txt(task.dateUpdated)),
    ],
  ),
),
  );
}
  Widget _taskCell(TaskRow t) => Column(   // ← Fixed
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.task,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
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

  Widget _propertyCell(TaskRow t) => Column(   // ← Fixed
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.property,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (t.propertyAddress.isNotEmpty)
            Text(
              t.propertyAddress,
              style: const TextStyle(color: Color(0xFF8A8A9A), fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      );

  Widget _assignmentCell(TaskRow t) => Column(   // ← Fixed
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: t.assignments
            .map((a) => Text(
                  a,
                  style: const TextStyle(color: Color(0xFF8A8A9A), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ))
            .toList(),
      );

  Widget _dueDateCell(TaskRow t) => Row(   // ← Fixed
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
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}