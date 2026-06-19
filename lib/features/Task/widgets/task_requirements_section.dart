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

    // Auto upload immediately after crop
    await _uploadImage(itemId, File(croppedFile.path));
  }

  Future<void> _uploadImage(String itemId, File file) async {
    setState(() => _isUploadingMap[itemId] = true);

    final response = await ApiController.uploadSingleFile(
      file: file,
      folder: 'task_requirements',
    );

    setState(() => _isUploadingMap[itemId] = false);

    if (response['success'] == true) {
      setState(() {
        final url = response['data']['cdn_url'] ?? response['data']['original_url'];
        if (url != null) {
          widget.submission.uploadedImageUrls.putIfAbsent(itemId, () => []);
          widget.submission.uploadedImageUrls[itemId]!.add(url as String);

          widget.submission.imageFiles.putIfAbsent(itemId, () => []);
          widget.submission.imageFiles[itemId]!.add(file);
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

  void _removeUploadedImage(String itemId, int index) {
    setState(() {
      widget.submission.uploadedImageUrls[itemId]?.removeAt(index);
      if (widget.submission.uploadedImageUrls[itemId]?.isEmpty ?? true) {
        widget.submission.uploadedImageUrls.remove(itemId);
      }
      // Keep imageFiles in sync
      if (widget.submission.imageFiles[itemId] != null &&
          widget.submission.imageFiles[itemId]!.length > index) {
        widget.submission.imageFiles[itemId]!.removeAt(index);
        if (widget.submission.imageFiles[itemId]!.isEmpty) {
          widget.submission.imageFiles.remove(itemId);
        }
      }
    });
    widget.onChanged();
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

    // PHOTO type always shows uploader
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
                      widget.submission.uploadedImageUrls[itemId]?.clear();
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

  // ── Image uploader (Auto-upload after crop) ─────────────────────────────────
  Widget _buildImageUploader(String itemId) {
    final uploadedFiles = widget.submission.imageFiles[itemId] ?? <File>[];
    final uploadedUrls = widget.submission.uploadedImageUrls[itemId] ?? <String>[];
    final isUploading = _isUploadingMap[itemId] == true;
    final uploadedCount = uploadedUrls.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.camera_alt_outlined, size: 15, color: Color(0xFFFF7300)),
            const SizedBox(width: 6),
            Text(
              _imageMandatoryHeadline(uploadedCount),
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF7300)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Uploaded images
        if (uploadedCount > 0) ...[
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF43A047)),
              const SizedBox(width: 5),
              Text(
                '$uploadedCount image${uploadedCount == 1 ? '' : 's'} saved',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF43A047),
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(uploadedCount, (index) {
              final hasLocalFile =
                  index < uploadedFiles.length && uploadedFiles[index].existsSync();
              return Stack(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF43A047), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: hasLocalFile
                          ? Image.file(uploadedFiles[index],
                              height: 100, width: 100, fit: BoxFit.cover)
                          : Image.network(
                              uploadedUrls[index],
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image,
                                    color: Color(0xFF8A8A9A), size: 28),
                              ),
                            ),
                    ),
                  ),
                  // Green check badge
                  const Positioned(
                    bottom: 5,
                    left: 5,
                    child: Icon(Icons.check_circle, color: Color(0xFF43A047), size: 16),
                  ),
                  // Red delete button
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () => _removeUploadedImage(itemId, index),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Color(0xFFFF6B6B)),
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
                  'Add Photo',
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

  String _imageMandatoryHeadline(int uploadedCount) {
    if (uploadedCount == 0) return 'Photo Required';
    return 'Photos ($uploadedCount Saved)';
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