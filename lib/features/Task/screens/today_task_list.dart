import 'package:flutter/material.dart';
import '../../Api/api_controller.dart';
import '../../Models/task_model.dart';
import 'task_detail_screen.dart';

class TodayTaskList extends StatefulWidget {
  const TodayTaskList({super.key});

  @override
  State<TodayTaskList> createState() => _TodayTaskListState();
}

class _TodayTaskListState extends State<TodayTaskList> {
  List<TaskModel> _tasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await ApiController.getMyTasks();
    if (!mounted) return;
    if (result['success'] == true) {
      final List data = result['data'];
      final allTasks = data.map((e) => TaskModel.fromJson(e)).toList();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      setState(() {
        _tasks = allTasks.where((t) {
          if (t.dueDate == null) return false;
          final due = DateTime.tryParse(t.dueDate!);
          if (due == null) return false;
          final dueDay = DateTime(due.year, due.month, due.day);
          return dueDay == today;
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['message'];
        _isLoading = false;
      });
    }
  }

  // ── Dark theme palette ──
  static const Color _bg         = Color(0xFF0A0A0F);
  static const Color _surface    = Color(0xFF111118);
  static const Color _surfaceAlt = Color(0xFF16161F);
  static const Color _orange     = Color(0xFFFF7300);
  static const Color _textPri    = Color(0xFFFFFFFF);
  static const Color _textSec    = Color(0xFF8A8A9A);
  static const Color _border     = Color(0xFF1E1E2E);
  static const Color _errorRed   = Color(0xFFFF6B6B);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _orange),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: _errorRed, size: 42),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: _textSec)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadTasks,
              child: Text('Retry', style: TextStyle(color: _orange)),
            ),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 180,
                height: 120,
                decoration: BoxDecoration(
                  color: _surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border, width: 1),
                ),
                child: const Center(
                  child: Icon(
                    Icons.assignment_outlined,
                    size: 52,
                    color: _textSec,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'No assigned tasks for today.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _textPri,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Try changing your dates to see your assigned tasks.',
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.45,
                  color: _textSec,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      );
    }

    // Group by priority
    final urgent = _tasks.where((t) => t.priority == 'URGENT').toList();
    final high   = _tasks.where((t) => t.priority == 'HIGH').toList();
    final medium = _tasks.where((t) => t.priority == 'MEDIUM').toList();
    final low    = _tasks.where((t) => t.priority == 'LOW').toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (urgent.isNotEmpty) ...[
          const _PriorityGroupHeader(label: 'URGENT'),
          ...urgent.map((t) => TaskCard(task: t)),
        ],
        if (high.isNotEmpty) ...[
          const _PriorityGroupHeader(label: 'HIGH'),
          ...high.map((t) => TaskCard(task: t)),
        ],
        if (medium.isNotEmpty) ...[
          const _PriorityGroupHeader(label: 'MEDIUM'),
          ...medium.map((t) => TaskCard(task: t)),
        ],
        if (low.isNotEmpty) ...[
          const _PriorityGroupHeader(label: 'LOW'),
          ...low.map((t) => TaskCard(task: t)),
        ],
      ],
    );
  }
}

// ── Priority group header ─────────────────────────────────────────────────────
class _PriorityGroupHeader extends StatelessWidget {
  final String label;
  const _PriorityGroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      color: const Color(0xFF16161F),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFF7300),
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ── Single task card ──────────────────────────────────────────────────────────
class TaskCard extends StatefulWidget {
  final TaskModel task;
  const TaskCard({super.key, required this.task});

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  void _openCommentDialog() {
    final TextEditingController commentController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF111118),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Add Comment',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              content: TextField(
                controller: commentController,
                minLines: 3,
                maxLines: 5,
                autofocus: true,
                onChanged: (_) => setDialogState(() {}),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Write a comment…',
                  hintStyle: const TextStyle(color: Color(0xFF8A8A9A)),
                  filled: true,
                  fillColor: const Color(0xFF1E1E2E),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2A2A3A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2A2A3A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF7300), width: 1.5),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF8A8A9A))),
                ),
                ElevatedButton(
                  onPressed: commentController.text.trim().isEmpty || isSending
                      ? null
                      : () async {
                          setDialogState(() => isSending = true);

                          final result = await ApiController.makeComment(
                            widget.task.id,
                            commentController.text.trim(),
                          );

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['success'] == true
                                    ? 'Comment posted successfully'
                                    : result['message'] ?? 'Failed to post comment',
                              ),
                              backgroundColor: result['success'] == true
                                  ? const Color(0xFF43A047)
                                  : const Color(0xFFFF6B6B),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7300),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Send', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = widget.task.isOverdue;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailScreen(task: widget.task)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF111118),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverdue
                ? const Color(0xFFFF6B6B).withOpacity(0.3)
                : const Color(0xFF1E1E2E),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isOverdue),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task.propertyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.task.propertyFullAddress,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF8A8A9A),
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.task.title,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.task.departmentName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8A8A9A),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isOverdue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      color: isOverdue ? const Color(0xFF2A1A1A) : const Color(0xFF1E1E2E),
      child: Row(
        children: [
          if (isOverdue) ...[
            const Icon(Icons.warning_amber_rounded, size: 17, color: Color(0xFFFF6B6B)),
            const SizedBox(width: 8),
          ],
          Text(
            widget.task.dueTime ?? widget.task.formattedDueDate,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isOverdue ? const Color(0xFFFF6B6B) : const Color(0xFF8A8A9A),
            ),
          ),
          const Spacer(),
          if (isOverdue)
            const Text(
              'OVERDUE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFF6B6B),
                letterSpacing: 1.0,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7300).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFFFF7300)),
                  const SizedBox(width: 6),
                  Text(
                    'Due ${widget.task.formattedDueDate}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF7300),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFF7300),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline_rounded, size: 15, color: Color(0xFF8A8A9A)),
                const SizedBox(width: 6),
                Text(
                  widget.task.myAssignment.status,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A8A9A),
                  ),
                ),
              ],
            ),
          ),
          if (widget.task.commentsCount > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF8A8A9A)),
                  const SizedBox(width: 5),
                  Text(
                    '${widget.task.commentsCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A8A9A),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF43A047).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFF43A047), size: 21),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _openCommentDialog,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF8A8A9A), size: 19),
            ),
          ),
        ],
      ),
    );
  }
}