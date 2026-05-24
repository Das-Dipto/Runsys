import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../widgets/task_submission_handler.dart';
import '../../Api/api_controller.dart';

class TaskRequirementsSection extends StatefulWidget {
  final Map<String, dynamic> detail;
  final TaskSubmissionHandler submission;
  final VoidCallback onChanged;

  const TaskRequirementsSection({
    super.key,
    required this.detail,
    required this.submission,
    required this.onChanged,
  });

  @override
  State<TaskRequirementsSection> createState() => _TaskRequirementsSectionState();
}

class _TaskRequirementsSectionState extends State<TaskRequirementsSection> {
  final _picker = ImagePicker();
  final Map<String, List<File>> _localPendingImages = {};
  final Map<String, bool> _isUploadingMap = {};

  Future<void> _showImageSourceDialog(String itemId) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
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
                leading: const Icon(Icons.photo_library, color: Color(0xFFFF7300)),
                title: const Text("Upload from Phone", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndCropImage(itemId, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFFF7300)),
                title: const Text("Take Photo", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndCropImage(itemId, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndCropImage(String itemId, ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: const Color(0xFFFF7300),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
        ),
        IOSUiSettings(minimumAspectRatio: 1.0),
      ],
    );

    if (croppedFile == null) return;

    setState(() {
      _localPendingImages.putIfAbsent(itemId, () => []);
      _localPendingImages[itemId]!.add(File(croppedFile.path));
    });
    widget.onChanged();
  }

  void _removeLocalImage(String itemId, int index) {
    setState(() {
      _localPendingImages[itemId]?.removeAt(index);
      if (_localPendingImages[itemId]?.isEmpty ?? true) {
        _localPendingImages.remove(itemId);
      }
    });
    widget.onChanged();
  }

  Future<void> _uploadPendingImages(String itemId) async {
    final pendingFiles = _localPendingImages[itemId];
    if (pendingFiles == null || pendingFiles.isEmpty) return;

    setState(() => _isUploadingMap[itemId] = true);

    Map<String, dynamic> response;
    if (pendingFiles.length == 1) {
      response = await ApiController.uploadSingleFile(
        file: pendingFiles.first,
        folder: 'task_requirements',
      );
    } else {
      response = await ApiController.uploadMultipleFiles(
        files: pendingFiles,
        folder: 'task_requirements',
      );
    }

    setState(() => _isUploadingMap[itemId] = false);

    if (response['success'] == true) {
      setState(() {
        _localPendingImages.remove(itemId);
        widget.submission.imageFiles.putIfAbsent(itemId, () => []);

        if (response['data'] is List) {
          for (var item in response['data']) {
            final url = item['cdn_url'] ?? item['original_url'];
            if (url != null) {
              widget.submission.uploadedImageUrls
                  .putIfAbsent(itemId, () => [])
                  .add(url as String);
            }
          }
        } else if (response['data'] is Map) {
          final url = response['data']['cdn_url'] ?? response['data']['original_url'];
          if (url != null) {
            widget.submission.uploadedImageUrls
                .putIfAbsent(itemId, () => [])
                .add(url as String);
          }
        }
      });

      widget.onChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['message'] ?? 'Image uploaded successfully!'),
          backgroundColor: const Color(0xFF43A047),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['message'] ?? 'Upload failed. Try again.'),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = (widget.detail['template']['sections'] as List?) ?? [];
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
            ...items.map<Widget>((item) => _buildTemplateItem(item)),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTemplateItem(Map<String, dynamic> item) {
    final type = item['type'] ?? '';
    final itemId = item['id'].toString();
    final imageMandatory = item['image_mandatory'] == true;

    widget.submission.initItem(item);

    bool showImageUploader = false;
    if (imageMandatory) {
      if (type == 'YES_NO') {
        showImageUploader = widget.submission.yesNoAnswers[itemId] == 'YES';
      } else {
        showImageUploader = true;
      }
    }

    // PHOTO type always shows uploader regardless of image_mandatory
    if (type == 'PHOTO') showImageUploader = true;

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
          // Question + type badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item['question'] ?? '',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7300).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type,
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF7300)),
                ),
              ),
            ],
          ),

          // ── YES_NO ──────────────────────────────────────────────────────
          if (type == 'YES_NO') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _SelectableYesNoBtn(
                  label: 'Yes',
                  color: const Color(0xFF43A047),
                  isSelected: widget.submission.yesNoAnswers[itemId] == 'YES',
                  onTap: () {
                    setState(() => widget.submission.yesNoAnswers[itemId] = 'YES');
                    widget.onChanged();
                  },
                ),
                const SizedBox(width: 10),
                _SelectableYesNoBtn(
                  label: 'No',
                  color: const Color(0xFFFF6B6B),
                  isSelected: widget.submission.yesNoAnswers[itemId] == 'NO',
                  onTap: () {
                    setState(() {
                      widget.submission.yesNoAnswers[itemId] = 'NO';
                      widget.submission.imageFiles[itemId]?.clear();
                      _localPendingImages[itemId]?.clear();
                    });
                    widget.onChanged();
                  },
                ),
              ],
            ),
          ],

          // ── CHECKLIST ────────────────────────────────────────────────────
          if (type == 'CHECKLIST') ...[
            const SizedBox(height: 12),
            ...(item['options'] as List? ?? []).map<Widget>((opt) {
              final optText = opt['text'] ?? '';
              final isSelected = widget.submission.checklistAnswers[itemId] == optText;
              return GestureDetector(
                onTap: () {
                  setState(() => widget.submission.checklistAnswers[itemId] = optText);
                  widget.onChanged();
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF7300).withOpacity(0.15)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFF7300)
                                : const Color(0xFF8A8A9A),
                            width: isSelected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 13, color: Color(0xFFFF7300))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(optText,
                          style: const TextStyle(fontSize: 14, color: Colors.white)),
                    ],
                  ),
                ),
              );
            }),
          ],

          // ── REPORT ───────────────────────────────────────────────────────
          if (type == 'REPORT') ...[
            const SizedBox(height: 12),
            TextField(
              controller: widget.submission.reportControllers[itemId],
              minLines: 3,
              maxLines: 6,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              onChanged: (_) => widget.onChanged(),
              decoration: _textInputDecoration('Enter report…'),
            ),
          ],

          // ── TEXT ─────────────────────────────────────────────────────────
          if (type == 'TEXT') ...[
            const SizedBox(height: 12),
            TextField(
              controller: widget.submission.reportControllers[itemId],
              minLines: 2,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              onChanged: (_) => widget.onChanged(),
              decoration: _textInputDecoration('Enter text…'),
            ),
          ],

          // ── CONDITION ────────────────────────────────────────────────────
          if (type == 'CONDITION') ...[
            const SizedBox(height: 12),
            TextField(
              controller: widget.submission.reportControllers[itemId],
              minLines: 2,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              onChanged: (_) => widget.onChanged(),
              decoration: _textInputDecoration('Describe condition…'),
            ),
          ],

          // ── COUNT ────────────────────────────────────────────────────────
          if (type == 'COUNT') ...[
            const SizedBox(height: 12),
            TextField(
              controller: widget.submission.reportControllers[itemId],
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              onChanged: (_) => widget.onChanged(),
              decoration: _textInputDecoration('Enter count…'),
            ),
          ],

          // ── RATING ───────────────────────────────────────────────────────
          if (type == 'RATING') ...[
            const SizedBox(height: 12),
            _buildStarRating(itemId),
          ],

          // ── PHOTO — no extra input, uploader handles everything ──────────

          // ── Image uploader ───────────────────────────────────────────────
          if (showImageUploader) ...[
            const SizedBox(height: 12),
            _buildImageUploader(itemId),
          ],
        ],
      ),
    );
  }

  // ── Star Rating ────────────────────────────────────────────────────────────
  Widget _buildStarRating(String itemId) {
    final currentRating =
        int.tryParse(widget.submission.reportControllers[itemId]?.text ?? '') ?? 0;
    return Row(
      children: List.generate(5, (index) {
        final star = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() {
              widget.submission.reportControllers[itemId]?.text = star.toString();
            });
            widget.onChanged();
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              star <= currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 36,
              color: star <= currentRating
                  ? const Color(0xFFFF7300)
                  : const Color(0xFF8A8A9A),
            ),
          ),
        );
      }),
    );
  }

  // ── Shared text input decoration ───────────────────────────────────────────
  InputDecoration _textInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF8A8A9A)),
      filled: true,
      fillColor: const Color(0xFF111118),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E1E2E))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E1E2E))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF7300), width: 1.5)),
    );
  }

  // ── Image uploader ─────────────────────────────────────────────────────────
  Widget _buildImageUploader(String itemId) {
    final pendingImages = _localPendingImages[itemId] ?? <File>[];
    final uploadedImages = widget.submission.imageFiles[itemId] ?? <File>[];
    final isUploading = _isUploadingMap[itemId] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.camera_alt_outlined, size: 15, color: Color(0xFFFF7300)),
            const SizedBox(width: 6),
            Text(
              _imageMandatoryHeadline(uploadedImages, pendingImages),
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF7300)),
            ),
          ],
        ),
        if (pendingImages.isNotEmpty) ...[
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: isUploading ? null : () => _uploadPendingImages(itemId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7300),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFFF7300).withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: isUploading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_upload_outlined, size: 16),
            label: Text(
              pendingImages.length == 1
                  ? "Save Image"
                  : "Upload All (${pendingImages.length})",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        const SizedBox(height: 10),

        // Uploaded previews
        if (uploadedImages.isNotEmpty) ...[
          const Text("Uploaded to Server:",
              style: TextStyle(
                  fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(uploadedImages.length, (index) {
              return Opacity(
                opacity: 0.6,
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF43A047), width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(uploadedImages[index],
                            height: 100, width: 100, fit: BoxFit.cover),
                      ),
                      const Positioned(
                        bottom: 4,
                        right: 4,
                        child: Icon(Icons.check_circle,
                            color: Color(0xFF43A047), size: 18),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
        ],

        // Staged previews
        if (pendingImages.isNotEmpty) ...[
          const Text("Staged Preview (Click Upload):",
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFFF7300),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(pendingImages.length, (index) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFFF7300).withOpacity(0.5), width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.file(pendingImages[index],
                          height: 120, width: 120, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _removeLocalImage(itemId, index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
        ],

        // Add photo button
        GestureDetector(
          onTap: isUploading ? null : () => _showImageSourceDialog(itemId),
          child: Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF111118),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFFF7300).withOpacity(0.4), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 26, color: const Color(0xFFFF7300).withOpacity(0.8)),
                const SizedBox(height: 4),
                const Text(
                  'Add Photo to Batch',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFFF7300),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _imageMandatoryHeadline(List uploaded, List pending) {
    if (uploaded.isEmpty && pending.isEmpty) return 'Photo Required';
    return 'Photos (${uploaded.length} Active / ${pending.length} Unsaved)';
  }
}

// ── Local widgets ──────────────────────────────────────────────────────────────
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