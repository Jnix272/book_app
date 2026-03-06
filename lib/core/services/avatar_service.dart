import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles picking an image from the gallery/camera and uploading it to
/// Supabase Storage. Returns the public URL on success, or null on failure.
class AvatarService {
  static final AvatarService instance = AvatarService._();
  AvatarService._();

  final _picker = ImagePicker();

  /// Shows a bottom sheet to let the user choose camera or gallery, then
  /// uploads the selected image to [bucketFolder]/[userId] with the correct extension in Supabase
  /// Storage and returns the public URL.
  Future<String?> pickAndUpload({
    required BuildContext context,
    required String bucketFolder,
    required String userId,
  }) async {
    // Let user pick source
    final source = await _pickSource(context);
    if (source == null) return null;

    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return null;

    try {
      final bytes = await File(picked.path).readAsBytes();
      final ext = picked.path.split('.').last.toLowerCase();
      final path = '$bucketFolder/$userId.$ext';

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );

      final url = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);

      // Bust CDN cache by appending a timestamp query param
      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('AvatarService upload error: $e');
      return null;
    }
  }

  Future<ImageSource?> _pickSource(BuildContext context) async {
    if (!context.mounted) return null;
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
