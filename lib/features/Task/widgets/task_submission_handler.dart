import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../Api/api_controller.dart';
import '../../Home/Screens/home_screen.dart';

// ── Result of a pre-submit validation check ─────────────────────────────
class UnfulfilledItem {
  final String itemId;
  final String message;
  UnfulfilledItem(this.itemId, this.message);
}

// ── Batch queue: collects item changes, flushes in small groups ─────────
// Mirrors the Next.js BatchQueue — avoids one API call per Save press AND
// avoids one giant request with all n items (which the backend chokes on).
class _BatchQueue {
  final Future<void> Function(List<Map<String, dynamic>> items) onSave;
  final int batchSize;
  final Duration maxDelay;

  _BatchQueue(
    this.onSave, {
    this.batchSize = 10,
    this.maxDelay = const Duration(seconds: 2),
  });

  final Map<String, Map<String, dynamic>> _queue = {};
  Timer? _timer;
  bool _isSaving = false;

  void add(String itemId, Map<String, dynamic> value) {
    _queue[itemId] = value;
    _scheduleSave();
  }

  void _scheduleSave() {
    _timer?.cancel();
    if (_queue.length >= batchSize) {
      _flush();
      return;
    }
    _timer = Timer(maxDelay, _flush);
  }


  Future<bool> _flush() async {
    if (_isSaving || _queue.isEmpty) return true;
    _isSaving = true;

    final items = _queue.entries
        .map((e) => {'item_id': int.parse(e.key), ...e.value})
        .toList();
    _queue.clear();

    bool allSucceeded = true;

    // Send ONE item per API call instead of bundling everything into a
    // single request — the backend can't insert a multi-item batch.
    for (final item in items) {
      try {
        await onSave([item]);
      } catch (_) {
        allSucceeded = false;
        final id = item['item_id'].toString();
        final value = Map<String, dynamic>.from(item)..remove('item_id');
        _queue[id] = value; // re-queue just this one item to retry later
      }
    }

    _isSaving = false;
    if (_queue.isNotEmpty) _scheduleSave();
    return allSucceeded;
  }

  /// Used before Submit. Bounded — if saves keep failing (rate limit,
  /// network), it backs off and eventually gives up instead of hammering
  /// the API. Anything left queued keeps retrying via the normal 2s
  /// debounce in the background.
  Future<void> forceFlush() async {
    _timer?.cancel();
    int attempts = 0;
    const maxAttempts = 5;

    while (_queue.isNotEmpty || _isSaving) {
      if (_isSaving) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }
      final ok = await _flush();
      if (ok) {
        attempts = 0;
      } else {
        attempts++;
        if (attempts >= maxAttempts) break;
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
  }
  
  void destroy() {
    _timer?.cancel();
  }
}

class TaskSubmissionHandler {
  final Map<String, String> yesNoAnswers = {};
  final Map<String, TextEditingController> reportControllers = {};
  final Map<String, String?> checklistAnswers = {};

  Map<String, List<File>> imageFiles = {};
  Map<String, List<File>> localPendingImages = {};
  Map<String, List<dynamic>> uploadedImages = {};
  final Map<String, List<String>> uploadedImageUrls = {};

  // ── Batch save wiring ───────────────────────────────────────────────
  int? _taskId;
  final Map<String, void Function(bool success)> _itemListeners = {};
  late final _BatchQueue _batchQueue = _BatchQueue(_flushBatch);

  void registerItemListener(String itemId, void Function(bool success) listener) {
    _itemListeners[itemId] = listener;
  }

  void unregisterItemListener(String itemId) {
    _itemListeners.remove(itemId);
  }

  /// Called on every field change instead of a per-item Save button.
  /// Debounced (2s) + capped at 10 items per request — see _BatchQueue.
  void queueItemChange(int taskId, String itemId, Map<String, dynamic> saveData) {
    _taskId = taskId;
    _batchQueue.add(itemId, saveData);
  }

  Future<void> forceFlushBatch() => _batchQueue.forceFlush();

  Future<void> _flushBatch(List<Map<String, dynamic>> items) async {
    final taskId = _taskId;
    if (taskId == null) return;

    final result = await ApiController.submitItemResponse(taskId: taskId, items: items);
    final success = result['success'] == true;

    for (final item in items) {
      final id = item['item_id'].toString();
      _itemListeners[id]?.call(success);
    }

    if (!success) {
      // Throwing tells _BatchQueue to re-queue these items and retry later.
      throw Exception(result['message'] ?? 'Batch save failed');
    }
  }

  void dispose() {
    _batchQueue.destroy();
    for (final c in reportControllers.values) {
      c.dispose();
    }
  }

  void initItem(Map<String, dynamic> item) {
    final type = item['type'] ?? '';
    final id = item['id'].toString();

    // Give a text controller to every type that might need answer_text
    if (!reportControllers.containsKey(id)) {
      reportControllers[id] = TextEditingController();
    }
    if (type == 'CHECKLIST' && !checklistAnswers.containsKey(id)) {
      checklistAnswers[id] = null;
    }
    if (!imageFiles.containsKey(id)) {
      imageFiles[id] = [];
    }
    if (!uploadedImageUrls.containsKey(id)) {
      uploadedImageUrls[id] = [];
    }
  }

  /// Same rule set as [validateResponses] but stops at (and returns) the
  /// FIRST unfulfilled item so the UI can scroll/highlight it.
  UnfulfilledItem? findFirstUnfulfilledItem(List sections) {
    for (final section in sections) {
      for (final item in (section['items'] as List? ?? [])) {
        final id = item['id'].toString();
        final type = item['type'] ?? '';
        final question = item['question'] ?? 'A field';
        final imageMandatory = item['image_mandatory'] == true;

        if (type == 'YES_NO' && !yesNoAnswers.containsKey(id)) {
          return UnfulfilledItem(id, '$question requires a Yes or No answer.');
        }
        if (type == 'REPORT' &&
            (reportControllers[id]?.text.trim().isEmpty ?? true)) {
          return UnfulfilledItem(id, '$question cannot be empty.');
        }
        if (type == 'CHECKLIST' &&
            (checklistAnswers[id] == null || checklistAnswers[id]!.isEmpty)) {
          return UnfulfilledItem(id, '$question requires a selection.');
        }

        if (imageMandatory) {
          final hasUploadedImage = uploadedImageUrls[id]?.isNotEmpty ?? false;

          if (type == 'YES_NO') {
            if (yesNoAnswers[id] == 'YES' && !hasUploadedImage) {
              return UnfulfilledItem(id, '$question requires a photo when answered Yes.');
            }
          } else if (['CHECKLIST', 'REPORT'].contains(type)) {
            if (!hasUploadedImage) {
              return UnfulfilledItem(id, '$question requires a photo.');
            }
          }
        }
      }
    }
    return null;
  }

  String? validateResponses(List sections) {
    return findFirstUnfulfilledItem(sections)?.message;
  }

  List<Map<String, dynamic>> buildResponses(List sections) {
    final responses = <Map<String, dynamic>>[];
    for (final section in sections) {
      for (final item in (section['items'] as List? ?? [])) {
        final id = item['id'] as int;
        final idStr = id.toString();
        final type = item['type'] ?? '';

        if (type == 'YES_NO') {
          responses.add({
            'item_id': id,
            'answer_yes_no': yesNoAnswers[idStr] ?? 'YES',
            'files': uploadedImageUrls[idStr] ?? [],
          });
        } else if (type == 'REPORT') {
          responses.add({
            'item_id': id,
            'answer_text': reportControllers[idStr]?.text ?? '',
            'files': uploadedImageUrls[idStr] ?? [],
          });
        } else if (type == 'CHECKLIST') {
          responses.add({
            'item_id': id,
            'answer_text': checklistAnswers[idStr] ?? '',
            'files': uploadedImageUrls[idStr] ?? [],
          });
        } else {
          // Handles: TEXT, CONDITION, COUNT, RATING, PHOTO, and any future types
          responses.add({
            'item_id': id,
            'answer_text': reportControllers[idStr]?.text ?? '',
            'files': uploadedImageUrls[idStr] ?? [],
          });
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
    // Make sure nothing is still sitting in the batch queue before we
    // validate / submit the final payload.
    await forceFlushBatch();

    final error = validateResponses(sections);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(error,
                      style: const TextStyle(fontWeight: FontWeight.w500))),
            ],
          ),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => _SubmitConfirmDialog(
        responses: buildResponses(sections),
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
              MaterialPageRoute(builder: (_) => const HomeScreen(initialTabIndex: 4)),
              (route) => false,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(result['message'] ?? 'Submission failed')),
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment_turned_in_rounded,
                    color: Color(0xFFFF7300), size: 22),
                SizedBox(width: 10),
                Text('Submit Task',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Review your answers:',
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A8A9A),
                    fontWeight: FontWeight.w600)),
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
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF1E1E2E)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            setState(() => _isSubmitting = true);
                            await widget.onConfirm(
                                _remarksCtrl.text, _commentCtrl.text);
                            setState(() => _isSubmitting = false);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7300),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Text('Submit',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
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
          answerDisplay = widget.yesNoAnswers[id] ?? '—';
        } else if (type == 'REPORT') {
          answerDisplay = widget.reportControllers[id]?.text ?? '—';
        } else if (type == 'CHECKLIST') {
          answerDisplay = widget.checklistAnswers[id] ?? '—';
        } else {
          // TEXT, CONDITION, COUNT, RATING, PHOTO etc.
          answerDisplay = widget.reportControllers[id]?.text ?? '—';
        }

        items.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 16, color: Color(0xFF43A047)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(question,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF8A8A9A))),
                    Text(answerDisplay.isEmpty ? '—' : answerDisplay,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
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

  Widget _buildField(
      String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8A8A9A),
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(fontSize: 14, color: Color(0xFF8A8A9A)),
            filled: true,
            fillColor: const Color(0xFF16161F),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E1E2E))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E1E2E))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFFFF7300), width: 1.5)),
          ),
        ),
      ],
    );
  }
}