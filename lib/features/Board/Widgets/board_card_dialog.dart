import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../Api/api_controller.dart';

class BoardCardDialog extends StatefulWidget {
  final Map<String, dynamic> task;

  const BoardCardDialog({super.key, required this.task});

  static void show(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => BoardCardDialog(task: task),
    );
  }

  @override
  State<BoardCardDialog> createState() => _BoardCardDialogState();
}

class _SubmitButton extends StatefulWidget {
  final int cardId;
  final VoidCallback onSuccess;

  const _SubmitButton({required this.cardId, required this.onSuccess});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    final result = await ApiController.submitCardAsCompleted(widget.cardId);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to submit task'),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _submit,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.send_rounded, size: 20),
      label: Text(
        _isLoading ? 'Submitting...' : 'Submit',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF7300),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _BoardCardDialogState extends State<BoardCardDialog> {
  // checklistId → selected itemId
  final Map<String, String?> _selectedItems = {};
  final Map<String, bool>    _loadingItems  = {};

  static const Color _surface    = Color(0xFF111118);
  static const Color _surfaceAlt = Color(0xFF16161F);
  static const Color _orange     = Color(0xFFFF7300);
  static const Color _green      = Color(0xFF43A047);
  static const Color _red        = Color(0xFFFF6B6B);
  static const Color _textSec    = Color(0xFF8A8A9A);
  static const Color _border     = Color(0xFF1E1E2E);

  @override
  void initState() {
    super.initState();
    // Pre-fill already-done items
    final checklists = widget.task['checklists'] as List? ?? [];
    for (final cl in checklists) {
      final clId  = cl['id']?.toString() ?? '';
      final items = cl['items'] as List? ?? [];
      for (final item in items) {
        if (item['is_done'] == true) {
          _selectedItems[clId] = item['id']?.toString();
        }
      }
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '—';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m  = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }

  bool _isHtml(String? text) {
    if (text == null) return false;
    return text.trimLeft().startsWith('<');
  }

  bool get _isOverdue {
    final due = widget.task['due_date'] as String?;
    if (due == null) return false;
    return DateTime.tryParse(due)?.isBefore(DateTime.now()) ?? false;
  }

  Future<void> _onItemTap({
    required String clId,
    required String itemId,
    required bool currentDone,
  }) async {
    final cardId      = (widget.task['id'] as num).toInt();
    final checklistId = int.tryParse(clId) ?? 0;
    final itemIdInt   = int.tryParse(itemId) ?? 0;
    final newStatus   = !currentDone;

    final loadKey = '$clId-$itemId';
    setState(() {
      _loadingItems[loadKey] = true;
      _selectedItems[clId]   = itemId;
    });

    final result = await ApiController.updateChecklistItem(
      cardId:      cardId,
      checklistId: checklistId,
      itemId:      itemIdInt,
      isDone:      newStatus,
    );

    if (!mounted) return;

    setState(() => _loadingItems[loadKey] = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Option selected',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Revert selection on failure
      setState(() => _selectedItems.remove(clId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update'),
            backgroundColor: _red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final task           = widget.task;
    final String title        = task['title'] as String? ?? '';
    final String? description = task['description'] as String?;
    final String? dueDate     = task['due_date'] as String?;
    final String? dueTime     = task['due_time'] as String?;
    final String? boardName   = task['board_name'] as String?;
    final List assignees      = task['assignees'] as List? ?? [];
    final List labels         = task['labels'] as List? ?? [];
    final List checklists     = task['checklists'] as List? ?? [];
    final int commentCount    = (task['comment_count'] as num?)?.toInt() ?? 0;
    final int attachCount     = (task['attachment_count'] as num?)?.toInt() ?? 0;
    final int checklistCount  = (task['checklist_count'] as num?)?.toInt() ?? 0;
    final String? createdAt   = task['created_at'] as String?;
    final String? updatedAt   = task['updated_at'] as String?;
    final String status       = (task['status'] as String? ?? '').toUpperCase();
    final bool isCompleted    = status == 'COMPLETED';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(title, boardName, context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDescription(description),
                    const SizedBox(height: 20),

                    LayoutBuilder(builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth > 380;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildChecklists(checklists)),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDueDate(dueDate, dueTime),
                                  if (assignees.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    _buildMembers(assignees),
                                  ],
                                  if (labels.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    _buildLabels(labels),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildChecklists(checklists),
                          const SizedBox(height: 16),
                          _buildDueDate(dueDate, dueTime),
                          if (assignees.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildMembers(assignees),
                          ],
                          if (labels.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildLabels(labels),
                          ],
                        ],
                      );
                    }),

                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFF1E1E2E)),
                    const SizedBox(height: 16),

                    _buildCounters(commentCount, attachCount, checklistCount),
                    const SizedBox(height: 20),
SizedBox(
  width: double.infinity,
  height: 48,
  child: isCompleted
      ? ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
          label: const Text('Completed',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _green.withOpacity(0.4),
            foregroundColor: Colors.white70,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        )
      : _SubmitButton(
          cardId: (widget.task['id'] as num).toInt(),
          onSuccess: () {
            if (mounted) {
              Navigator.pop(context); // Close dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Task submitted successfully'),
                  ],
                ),
                backgroundColor: const Color(0xFF43A047),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            }
          },
        ),
),
                    const SizedBox(height: 16),
                    _buildFooterDates(createdAt, updatedAt),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(String title, String? boardName, BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E1E2E))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (boardName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _orange.withOpacity(0.25)),
                    ),
                    child: Text(boardName,
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF7300))),
                  ),
                Text(title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4,
                      height: 1.2,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF8A8A9A)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Description ──────────────────────────────────────────────────────────
  Widget _buildDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return const Text('No Description Found',
          style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8A8A9A),
              fontStyle: FontStyle.italic));
    }
    if (_isHtml(description)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Html(
          data: description,
          style: {
            'body': Style(
                fontSize: FontSize(14),
                color: Colors.white,
                margin: Margins.zero,
                padding: HtmlPaddings.zero),
            'p': Style(
                fontSize: FontSize(14),
                color: Colors.white,
                margin: Margins.only(bottom: 4)),
          },
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Text(description,
          style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5)),
    );
  }

  // ── Checklists ───────────────────────────────────────────────────────────
  Widget _buildChecklists(List checklists) {
    if (checklists.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(Icons.check_circle_outline_rounded, 'CHECKLISTS'),
        const SizedBox(height: 12),
        ...checklists.map<Widget>((cl) {
          final clId    = cl['id']?.toString() ?? '';
          final clTitle = cl['title'] as String? ?? 'Checklist';
          final items   = cl['items'] as List? ?? [];
          final doneCount = items.where((i) => i['is_done'] == true).length;
          final pct = items.isEmpty ? 0 : ((doneCount / items.length) * 100).round();

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF43A047)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(clTitle,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                    Text('$pct%',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF43A047))),
                  ],
                ),
                const SizedBox(height: 10),
                ...items.map<Widget>((item) {
                  final itemId   = item['id']?.toString() ?? '';
                  final itemText = item['item_text'] as String? ?? '';
                  final isDone   = item['is_done'] == true;
                  final isSelected = _selectedItems[clId] == itemId || isDone;
                  final loadKey    = '$clId-$itemId';
                  final isLoading  = _loadingItems[loadKey] == true;

                  return GestureDetector(
                    onTap: isLoading
                        ? null
                        : () => _onItemTap(
                              clId: clId,
                              itemId: itemId,
                              currentDone: isDone,
                            ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF43A047)),
                                )
                              : Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF43A047)
                                          : const Color(0xFF8A8A9A),
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? const Color(0xFF43A047).withOpacity(0.15)
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check_rounded,
                                          size: 13, color: Color(0xFF43A047))
                                      : null,
                                ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              itemText,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isSelected
                                    ? const Color(0xFF43A047)
                                    : Colors.white,
                                decoration:
                                    isDone ? TextDecoration.lineThrough : null,
                                decorationColor: const Color(0xFF8A8A9A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Due Date ─────────────────────────────────────────────────────────────
  Widget _buildDueDate(String? dueDate, String? dueTime) {
    final dateStr  = _formatDate(dueDate);
    final timeStr  = dueTime != null && dueTime.isNotEmpty
        ? _formatTime(dueTime)
        : dueDate != null ? _formatTime(dueDate) : '';
    final bool overdue = _isOverdue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(Icons.calendar_month_rounded, 'DUE DATE'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: overdue ? _red.withOpacity(0.12) : _surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: overdue ? _red.withOpacity(0.4) : _border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded,
                  size: 16,
                  color: overdue ? _red : const Color(0xFF8A8A9A)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: overdue ? _red : Colors.white)),
                  if (timeStr.isNotEmpty)
                    Text(timeStr,
                        style: const TextStyle(
                            fontSize: 11.5, color: Color(0xFF8A8A9A))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Members ──────────────────────────────────────────────────────────────
  Widget _buildMembers(List assignees) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(Icons.group_outlined, 'MEMBERS'),
        const SizedBox(height: 8),
        ...assignees.map<Widget>((a) {
          final name    = a['name'] as String? ?? 'Unknown';
          final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(initial,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF7300))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Labels ───────────────────────────────────────────────────────────────
  Widget _buildLabels(List labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(Icons.label_outline_rounded, 'LABELS'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: labels.map<Widget>((l) {
            final name      = l['name'] as String? ?? '';
            final colorName = l['color'] as String? ?? '';
            final color     = _labelColor(colorName);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(name,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Counters ─────────────────────────────────────────────────────────────
  Widget _buildCounters(int comments, int attachments, int checklists) {
    return Row(
      children: [
        _Counter(icon: Icons.chat_bubble_outline_rounded,
            label: 'Comments', count: comments),
        const SizedBox(width: 20),
        _Counter(icon: Icons.attach_file_rounded,
            label: 'Attachments', count: attachments),
        const SizedBox(width: 20),
        _Counter(icon: Icons.check_circle_outline_rounded,
            label: 'Checklists', count: checklists),
      ],
    );
  }

  // ── Footer Dates ─────────────────────────────────────────────────────────
  Widget _buildFooterDates(String? createdAt, String? updatedAt) {
    return Row(
      children: [
        const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF8A8A9A)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Created ${_formatDate(createdAt)}  •  Updated ${_formatDate(updatedAt)}',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF8A8A9A)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _textSec),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A8A9A),
                letterSpacing: 0.8)),
      ],
    );
  }

  Color _labelColor(String colorName) {
    const map = {
      'blue':   Color(0xFF42A5F5),
      'pink':   Color(0xFFEC407A),
      'red':    Color(0xFFEF5350),
      'green':  Color(0xFF66BB6A),
      'yellow': Color(0xFFFFCA28),
      'purple': Color(0xFFAB47BC),
      'teal':   Color(0xFF26A69A),
      'orange': Color(0xFFFF7300),
    };
    return map[colorName.toLowerCase()] ?? const Color(0xFF8A8A9A);
  }
}

// ── Counter widget ────────────────────────────────────────────────────────────
class _Counter extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _Counter({required this.icon, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF8A8A9A)),
            const SizedBox(width: 5),
            Text('$count',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF8A8A9A))),
      ],
    );
  }
}
