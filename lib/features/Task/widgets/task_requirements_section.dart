import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../widgets/task_submission_handler.dart';
import '../../Api/api_controller.dart';

/// Renders all sections/items of a task's requirement template.
///
/// Behavior change from before:
///  - There is no more "Done" button.
///  - Each item tracks its own "dirty" state locally. As soon as the user
///    changes ANYTHING on an item (answer, checklist, photo, etc.) a
///    "Save" button appears under that item.
///  - Pressing Save calls `ApiController.submitItemResponse` for THAT item
///    only (not the whole task) and shows a saved/error state.
class TaskRequirementsSection extends StatefulWidget {
  final Map<String, dynamic> detail;
  final TaskSubmissionHandler submission;
  final int taskId;

  /// Previously-submitted answers keyed by item id as a string, e.g.
  /// `{"749": {"answer_text": "4"}}`. Comes from
  /// `detail['existing_responses']['answers']` on the task detail response.
  /// Used to pre-fill each item and mark it as already "Saved".
  final Map<String, dynamic> existingAnswers;

  /// Fired on every field change (kept for backward compatibility with
  /// whatever the parent screen was already doing with it, e.g. enabling
  /// a "Submit task" button).
  final VoidCallback onChanged;

  /// Optional: fired when an individual item is successfully saved to the
  /// API. Useful for a parent screen that wants a "12 of 36 saved" counter.
  final ValueChanged<String>? onItemSaved;

  /// Optional: fired when a previously-saved item becomes dirty again
  /// (user edited it after saving).
  final ValueChanged<String>? onItemEdited;
  final bool readOnly;    

  const TaskRequirementsSection({
    super.key,
    required this.detail,
    required this.submission,
    required this.taskId,
    required this.onChanged,
    this.existingAnswers = const {},
    this.onItemSaved,
    this.onItemEdited,
    this.readOnly = false, 
  });

  @override
  State<TaskRequirementsSection> createState() => _TaskRequirementsSectionState();
}

class _TaskRequirementsSectionState extends State<TaskRequirementsSection> {
  @override
  Widget build(BuildContext context) {
    final sections = (widget.detail['template']?['sections'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map<Widget>((section) {
        final items = (section['items'] as List?) ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF16161F),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E1E2E)),
              ),
              child: Text(
                section['title'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF7300),
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...items.map<Widget>((item) {
              final itemId = item['id'].toString();
              widget.submission.initItem(item);
              return _RequirementItemCard(
                key: ValueKey(itemId),
                item: item,
                submission: widget.submission,
                taskId: widget.taskId,
                existingAnswer: widget.existingAnswers[itemId] as Map?,
                onChanged: widget.onChanged,
                onSaved: () => widget.onItemSaved?.call(itemId),
                onEdited: () => widget.onItemEdited?.call(itemId),
                readOnly: widget.readOnly,
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Single requirement item card. Owns its own dirty/saving/saved state and
// is responsible for calling the API when the user taps "Save".
// ─────────────────────────────────────────────────────────────────────────

class _RequirementItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final TaskSubmissionHandler submission;
  final int taskId;

  /// This item's previously-saved answer, if any, e.g. {"answer_text": "4"}.
  final Map? existingAnswer;

  final VoidCallback onChanged;
  final VoidCallback onSaved;
  final VoidCallback onEdited;
  final bool readOnly;      

  const _RequirementItemCard({
    super.key,
    required this.item,
    required this.submission,
    required this.taskId,
    required this.onChanged,
    required this.onSaved,
    required this.onEdited,
    this.existingAnswer,
    this.readOnly = false,
  });

  @override
  State<_RequirementItemCard> createState() => _RequirementItemCardState();
}

class _RequirementItemCardState extends State<_RequirementItemCard> {
  static const Color _orange = Color(0xFFFF7300);
  static const Color _green = Color(0xFF43A047);
  static const Color _red = Color(0xFFFF6B6B);
  static const Color _textSec = Color(0xFF8A8A9A);

  final _picker = ImagePicker();

  bool _isDirty = false;
  bool _isSaved = false;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;

  String get _itemId => widget.item['id'].toString();
  String get _type => widget.item['type'] ?? '';
  bool get _imageMandatory => widget.item['image_mandatory'] == true;

  bool get _readOnly => widget.readOnly;

  @override
  void initState() {
    super.initState();
    _prefillFromExistingAnswer();
  }

  // ── Pre-fill from a previously-saved answer ─────────────────────────────
  // Runs once when the card is created. Writes the saved value straight
  // into the same submission fields the live UI reads/writes, then marks
  // the card as already "Saved" so the Save button doesn't show until the
  // user actually changes something.
  void _prefillFromExistingAnswer() {
    final answer = widget.existingAnswer;
    if (answer == null) return;

    final s = widget.submission;
    final answerText = (answer['answer_text'] ?? '').toString();
    final rawFiles = (answer['files'] as List?) ?? const [];
    final existingFiles = rawFiles
        .map<String>((f) {
          if (f is String) return f;
          if (f is Map) {
            return (f['cdn_url'] ?? f['url'] ?? f['file_url'] ?? f['original_url'] ?? '').toString();
          }
          return '';
        })
        .where((url) => url.isNotEmpty)
        .toList();

    switch (_type) {
      case 'RATING':
      case 'COUNT':
        s.reportControllers[_itemId]?.text = answerText;
        break;
      case 'YES_NO':
        final normalized = answerText.trim().toUpperCase();
        s.yesNoAnswers[_itemId] = (normalized == 'YES' || normalized == 'YES_NO' || normalized == 'Y')
            ? 'YES'
            : 'NO';
        break;
      case 'CHECKLIST':
        s.checklistAnswers[_itemId] = answerText;
        break;
      case 'TEXT':
      case 'REPORT':
      case 'CONDITION':
        s.reportControllers[_itemId]?.text = answerText;
        break;
      case 'PHOTO':
        break; // files handled below for every type that supports them
    }

    if (existingFiles.isNotEmpty) {
      s.uploadedImageUrls[_itemId] = existingFiles;
    }

    // Show this item as already saved, not dirty, until the user edits it.
    _isSaved = true;
    _isDirty = false;
  }

  // ── Dirty tracking ────────────────────────────────────────────────────
  void _markDirty() {
    if (_readOnly) return; 
    if (!_isDirty || _isSaved) {
      setState(() {
        _isDirty = true;
        _isSaved = false;
      });
      widget.onEdited();
    }
    widget.onChanged();
  }

  // ── Build the API payload for THIS item based on its type ───────────────
  Map<String, dynamic> _buildPayload() {
    final s = widget.submission;
    final files = s.uploadedImageUrls[_itemId] ?? <String>[];

    switch (_type) {
      case 'YES_NO':
        return {
          'item_id': widget.item['id'],
          'answer_yes_no': s.yesNoAnswers[_itemId] ?? '',
          if (files.isNotEmpty) 'files': files,
        };
      case 'CHECKLIST':
        return {
          'item_id': widget.item['id'],
          'answer_text': s.checklistAnswers[_itemId] ?? '',
        };
      case 'REPORT':
      case 'TEXT':
      case 'CONDITION':
        return {
          'item_id': widget.item['id'],
          'answer_text': s.reportControllers[_itemId]?.text ?? '',
          if (files.isNotEmpty) 'files': files,
        };
      case 'COUNT':
        return {
          'item_id': widget.item['id'],
          'count_value': int.tryParse(s.reportControllers[_itemId]?.text ?? '') ?? 0,
        };
      case 'RATING':
        return {
          'item_id': widget.item['id'],
          'rating_value': int.tryParse(s.reportControllers[_itemId]?.text ?? '') ?? 0,
        };
      case 'PHOTO':
        return {
          'item_id': widget.item['id'],
          'files': files,
        };
      default:
        return {'item_id': widget.item['id']};
    }
  }

  // ── Save button pressed ───────────────────────────────────────────────
  Future<void> _onSavePressed() async {
    setState(() => _isSubmitting = true);

    final result = await ApiController.submitItemResponse(
      taskId: widget.taskId,
      items: [_buildPayload()],
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _isSubmitting = false;
        _isDirty = false;
        _isSaved = true;
      });
      widget.onSaved();
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Failed to save'),
        backgroundColor: _red,
      ));
    }
  }

  // ── Image pick / crop / upload (per-item, self-contained) ──────────────
  Future<void> _showImageSourceDialog() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Image Source",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _orange),
              title: const Text("Upload from Phone", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _orange),
              title: const Text("Take Photo", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _pickAndCropImage(source);
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: _orange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
        ),
        IOSUiSettings(minimumAspectRatio: 1.0),
      ],
    );
    if (croppedFile == null) return;

    await _uploadImage(File(croppedFile.path));
  }

  Future<void> _uploadImage(File file) async {
    setState(() => _isUploadingImage = true);

    final response = await ApiController.uploadSingleFile(
      file: file,
      folder: 'task_requirements',
    );

    if (!mounted) return;
    setState(() => _isUploadingImage = false);

    if (response['success'] == true) {
      final url = response['data']?['cdn_url'] ?? response['data']?['original_url'];
      if (url != null) {
        widget.submission.uploadedImageUrls.putIfAbsent(_itemId, () => []);
        widget.submission.uploadedImageUrls[_itemId]!.add(url as String);

        widget.submission.imageFiles.putIfAbsent(_itemId, () => []);
        widget.submission.imageFiles[_itemId]!.add(file);
      }
      _markDirty();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['message'] ?? 'Image uploaded successfully!'),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['message'] ?? 'Upload failed. Try again.'),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _removeUploadedImage(int index) {
    setState(() {
      widget.submission.uploadedImageUrls[_itemId]?.removeAt(index);
      if (widget.submission.uploadedImageUrls[_itemId]?.isEmpty ?? true) {
        widget.submission.uploadedImageUrls.remove(_itemId);
      }
      if ((widget.submission.imageFiles[_itemId]?.length ?? 0) > index) {
        widget.submission.imageFiles[_itemId]!.removeAt(index);
        if (widget.submission.imageFiles[_itemId]!.isEmpty) {
          widget.submission.imageFiles.remove(_itemId);
        }
      }
    });
    _markDirty();
  }

  // ── UI ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    bool showImageUploader = false;
    if (_imageMandatory) {
      showImageUploader = _type == 'YES_NO'
          ? widget.submission.yesNoAnswers[_itemId] == 'YES'
          : true;
    }
    if (_type == 'PHOTO') showImageUploader = true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E1E2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.item['question'] ?? '',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _type,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _orange),
                ),
              ),
            ],
          ),

          if (_type == 'YES_NO') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _SelectableYesNoBtn(
                  label: 'Yes',
                  color: _green,
                  isSelected: widget.submission.yesNoAnswers[_itemId] == 'YES',
                 onTap: _readOnly ? () {} : () {
                  setState(() => widget.submission.yesNoAnswers[_itemId] = 'YES');
                  _markDirty();
                },
                ),
                const SizedBox(width: 10),
                _SelectableYesNoBtn(
                  label: 'No',
                  color: _red,
                  isSelected: widget.submission.yesNoAnswers[_itemId] == 'NO',
                  onTap: _readOnly ? () {} : () {
                    setState(() {
                      widget.submission.yesNoAnswers[_itemId] = 'NO';
                      widget.submission.imageFiles[_itemId]?.clear();
                      widget.submission.uploadedImageUrls[_itemId]?.clear();
                    });
                    _markDirty();
                  },
                ),
              ],
            ),
          ],

          if (_type == 'CHECKLIST') ...[
            const SizedBox(height: 12),
            ...(widget.item['options'] as List? ?? []).map<Widget>((opt) {
              final optText = opt['text'] ?? '';
              final isSelected = widget.submission.checklistAnswers[_itemId] == optText;
              return GestureDetector(
               onTap: _readOnly ? null : () {
  setState(() => widget.submission.checklistAnswers[_itemId] = optText);
  _markDirty();
},
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isSelected ? _orange.withOpacity(0.15) : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? _orange : const Color(0xFF8A8A9A),
                            width: isSelected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 13, color: _orange) : null,
                      ),
                      const SizedBox(width: 12),
                      Text(optText, style: const TextStyle(fontSize: 14, color: Colors.white)),
                    ],
                  ),
                ),
              );
            }),
          ],

          if (_type == 'REPORT') ...[
            const SizedBox(height: 12),
            TextField(
              controller: widget.submission.reportControllers[_itemId],
              minLines: 3,
              maxLines: 6,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              onChanged: (_) => _markDirty(),
              decoration: _textInputDecoration('Enter report…'),
              enabled: !_readOnly,
            ),
          ],

          if (_type == 'TEXT') ...[
            const SizedBox(height: 12),
            TextField(
              controller: widget.submission.reportControllers[_itemId],
              minLines: 2,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              onChanged: (_) => _markDirty(),
              decoration: _textInputDecoration('Enter text…'),
              enabled: !_readOnly,
            ),
          ],

          if (_type == 'CONDITION') ...[
            const SizedBox(height: 12),
            TextField(
              controller: widget.submission.reportControllers[_itemId],
              minLines: 2,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              onChanged: (_) => _markDirty(),
              decoration: _textInputDecoration('Describe condition…'),
              enabled: !_readOnly,
            ),
          ],

          if (_type == 'COUNT') ...[
            const SizedBox(height: 12),
            TextField(
              controller: widget.submission.reportControllers[_itemId],
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              onChanged: (_) => _markDirty(),
              decoration: _textInputDecoration('Enter count…'),
              enabled: !_readOnly,
            ),
          ],

          if (_type == 'RATING') ...[
            const SizedBox(height: 12),
            _buildStarRating(),
          ],

          if (showImageUploader) ...[
            const SizedBox(height: 12),
            _buildImageUploader(),
          ],

          // ── Save button / Saved indicator ─────────────────────────────
          if (_isDirty || _isSubmitting) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _onSavePressed,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(
                  _isSubmitting ? 'Saving...' : 'Save',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _orange.withOpacity(0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ] else if (_isSaved) ...[
            const SizedBox(height: 14),
            const Row(children: [
              Icon(Icons.check_circle_rounded, size: 18, color: _green),
              SizedBox(width: 6),
              Text('Saved', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _green)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    final currentRating = int.tryParse(widget.submission.reportControllers[_itemId]?.text ?? '') ?? 0;
    return Row(
      children: List.generate(5, (index) {
        final star = index + 1;
        return GestureDetector(
         onTap: _readOnly ? null : () {
  setState(() {
    widget.submission.reportControllers[_itemId]?.text = star.toString();
  });
  _markDirty();
},
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              star <= currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 36,
              color: star <= currentRating ? _orange : _textSec,
            ),
          ),
        );
      }),
    );
  }

  InputDecoration _textInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: _textSec),
      filled: true,
      fillColor: const Color(0xFF111118),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E1E2E))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E1E2E))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _orange, width: 1.5)),
    );
  }

  Widget _buildImageUploader() {
    final uploadedFiles = widget.submission.imageFiles[_itemId] ?? <File>[];
    final uploadedUrls = widget.submission.uploadedImageUrls[_itemId] ?? <String>[];
    final uploadedCount = uploadedUrls.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.camera_alt_outlined, size: 15, color: _orange),
            const SizedBox(width: 6),
            Text(
              uploadedCount == 0 ? 'Photo Required' : 'Photos ($uploadedCount Saved)',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _orange),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (uploadedCount > 0) ...[
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 13, color: _green),
              const SizedBox(width: 5),
              Text(
                '$uploadedCount image${uploadedCount == 1 ? '' : 's'} added',
                style: const TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(uploadedCount, (index) {
              final hasLocalFile = index < uploadedFiles.length && uploadedFiles[index].existsSync();
              return Stack(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _green, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: hasLocalFile
                          ? Image.file(uploadedFiles[index], height: 100, width: 100, fit: BoxFit.cover)
                          : Image.network(
                              uploadedUrls[index],
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Center(child: Icon(Icons.broken_image, color: _textSec, size: 28)),
                            ),
                    ),
                  ),
                  const Positioned(
                    bottom: 5,
                    left: 5,
                    child: Icon(Icons.check_circle, color: _green, size: 16),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: _readOnly
      ? const SizedBox.shrink()
      : GestureDetector(
                      onTap: () => _removeUploadedImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: _red),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
        ],
        if (!_readOnly)
        GestureDetector(
          onTap: _isUploadingImage ? null : _showImageSourceDialog,
          child: Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF111118),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _orange.withOpacity(0.4), width: 1.5),
            ),
            child: _isUploadingImage
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _orange),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 26, color: _orange.withOpacity(0.8)),
                      const SizedBox(height: 4),
                      const Text(
                        'Add Photo',
                        style: TextStyle(fontSize: 13, color: _orange, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Local widgets ──────────────────────────────────────────────────────────
class _SelectableYesNoBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableYesNoBtn({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.18) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.4),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}