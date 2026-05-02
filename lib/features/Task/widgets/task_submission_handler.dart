import 'package:flutter/material.dart';
import '../../Api/api_controller.dart';
import '../../Home/Screens/home_screen.dart';

class TaskSubmissionHandler {
  // Holds YES_NO answers: itemId -> "YES" | "NO"
  final Map<String, String> yesNoAnswers = {};
  // Holds REPORT/text answers: itemId -> controller
  final Map<String, TextEditingController> reportControllers = {};
  // Holds CHECKLIST selected option text: itemId -> selected option text
  final Map<String, String?> checklistAnswers = {};

  void dispose() {
    for (final c in reportControllers.values) c.dispose();
  }

  void initItem(Map<String, dynamic> item) {
    final type = item['type'] ?? '';
    final id = item['id'].toString();

    if (type == 'YES_NO' && !yesNoAnswers.containsKey(id)) {
      // yesNoAnswers[id] = 'YES';
    }
    if (type == 'REPORT' && !reportControllers.containsKey(id)) {
      reportControllers[id] = TextEditingController();
    }
    if (type == 'CHECKLIST' && !checklistAnswers.containsKey(id)) {
      checklistAnswers[id] = null;
    }
  }

  String? validateResponses(List sections) {
  for (final section in sections) {
    for (final item in (section['items'] as List? ?? [])) {
      final id = item['id'].toString();
      final type = item['type'] ?? '';
      final question = item['question'] ?? 'A field';

      if (type == 'YES_NO' && !yesNoAnswers.containsKey(id)) {
        return '$question requires a Yes or No answer.';
      }
      if (type == 'REPORT' && (reportControllers[id]?.text.trim().isEmpty ?? true)) {
        return '$question cannot be empty.';
      }
      if (type == 'CHECKLIST' && (checklistAnswers[id] == null || checklistAnswers[id]!.isEmpty)) {
        return '$question requires a selection.';
      }
    }
  }
  return null; // all valid
}

  List<Map<String, dynamic>> buildResponses(List sections) {
    final responses = <Map<String, dynamic>>[];
    for (final section in sections) {
      for (final item in (section['items'] as List? ?? [])) {
        final id = item['id'] as int;
        final idStr = id.toString();
        final type = item['type'] ?? '';

        if (type == 'YES_NO') {
          responses.add({'item_id': id, 'answer_yes_no': yesNoAnswers[idStr] ?? 'YES'});
        } else if (type == 'REPORT') {
          responses.add({'item_id': id, 'answer_text': reportControllers[idStr]?.text ?? ''});
        } else if (type == 'CHECKLIST') {
          responses.add({'item_id': id, 'answer_text': checklistAnswers[idStr] ?? ''});
        }
      }
    }
    return responses;
  }

  /// Shows confirmation dialog then submits
Future<void> showConfirmAndSubmit({
  required BuildContext context,
  required int taskId,
  required int timeLogId,
  required List sections,
  required VoidCallback onSuccess,
  required Future<void> Function() onStopTimer,
}) async {
  // ← ADD: validate first
  final error = validateResponses(sections);
  if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(error, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: const Color(0xFFFF6B6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return; // ← don't open dialog
  }

  final responses = buildResponses(sections);

  await showDialog(
    context: context,
    builder: (ctx) => _SubmitConfirmDialog(
      responses: responses,
      sections: sections,
      yesNoAnswers: yesNoAnswers,
      reportControllers: reportControllers,
      checklistAnswers: checklistAnswers,
      onConfirm: (remarks, comment) async {
        Navigator.pop(ctx);
        final result = await ApiController.submitTask(
          taskId: taskId,
          responses: buildResponses(sections),
          timeLogId: timeLogId,
          remarks: remarks,
          comment: comment,
        );
        if (!context.mounted) return;
        if (result['success'] == true) {
          onSuccess();
          await onStopTimer();
          if (!context.mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Submission failed')),
          );
        }
      },
    ),
  );
}

}

// ── Confirm Dialog ─────────────────────────────────────────────────────────

class _SubmitConfirmDialog extends StatefulWidget {
  final List<Map<String, dynamic>> responses;
  final List sections;
  final Map<String, String> yesNoAnswers;
  final Map<String, TextEditingController> reportControllers;
  final Map<String, String?> checklistAnswers;
  final Future<void> Function(String remarks, String comment) onConfirm;

  const _SubmitConfirmDialog({
    required this.responses,
    required this.sections,
    required this.yesNoAnswers,
    required this.reportControllers,
    required this.checklistAnswers,
    required this.onConfirm,
  });

  @override
  State<_SubmitConfirmDialog> createState() => _SubmitConfirmDialogState();
}

class _SubmitConfirmDialogState extends State<_SubmitConfirmDialog> {
  final _remarksCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _remarksCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111118),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment_turned_in_rounded, color: Color(0xFFFF7300), size: 22),
                SizedBox(width: 10),
                Text('Submit Task',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Review your answers:',
                style: TextStyle(fontSize: 13, color: Color(0xFF8A8A9A), fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildAnswerSummary(),
            const SizedBox(height: 20),
            _buildField('Remarks', _remarksCtrl, 'Add remarks…'),
            const SizedBox(height: 14),
            _buildField('Comment', _commentCtrl, 'Add a comment…'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF1E1E2E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            setState(() => _isSubmitting = true);
                            await widget.onConfirm(_remarksCtrl.text, _commentCtrl.text);
                            setState(() => _isSubmitting = false);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7300),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Submit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerSummary() {
    final items = <Widget>[];
    for (final section in widget.sections) {
      for (final item in (section['items'] as List? ?? [])) {
        final id = item['id'].toString();
        final type = item['type'] ?? '';
        final question = item['question'] ?? '';
        String answerDisplay = '';

        if (type == 'YES_NO') {
          answerDisplay = widget.yesNoAnswers[id] ?? 'YES';
        } else if (type == 'REPORT') {
          answerDisplay = widget.reportControllers[id]?.text ?? '';
        } else if (type == 'CHECKLIST') {
          answerDisplay = widget.checklistAnswers[id] ?? '—';
        }

        items.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF43A047)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(question,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF8A8A9A))),
                    Text(answerDisplay.isEmpty ? '—' : answerDisplay,
                        style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ));
      }
    }
    return Column(children: items);
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8A8A9A), fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF8A8A9A)),
            filled: true,
            fillColor: const Color(0xFF16161F),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E1E2E)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E1E2E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF7300), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}