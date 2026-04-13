import 'package:flutter/material.dart';

class AttachmentsScreen extends StatefulWidget {
  final String taskType;
  final String propertyName;
  final String address;

  const AttachmentsScreen({
    super.key,
    required this.taskType,
    required this.propertyName,
    required this.address,
  });

  @override
  State<AttachmentsScreen> createState() => _AttachmentsScreenState();
}

class _AttachmentsScreenState extends State<AttachmentsScreen> {
  static const Color _accent = Color(0xFF29B6F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attachments',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Paperclip Icon
              Icon(
                Icons.attach_file_rounded,
                size: 92,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 32),

              const Text(
                'No attachments for this task.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'Any attachments from you, office admins,\nor vendors will show up here.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accent,
        elevation: 4,
        onPressed: () => _showAttachBottomSheet(context),
        child: const Icon(
          Icons.attach_file_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  // Bottom Sheet
  void _showAttachBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'ATTACH FILE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Divider(height: 1),

              _BottomSheetOption(
                icon: Icons.camera_alt_outlined,
                title: 'Take photo',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement camera
                },
              ),
              _BottomSheetOption(
                icon: Icons.photo_library_outlined,
                title: 'View gallery',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement gallery picker
                },
              ),
              _BottomSheetOption(
                icon: Icons.upload_file_outlined,
                title: 'Upload file',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement file picker
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// Bottom Sheet Tile Widget
class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _BottomSheetOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 26, color: const Color(0xFF555555)),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}