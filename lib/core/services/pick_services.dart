import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class PickedFileBytes {
  const PickedFileBytes({
    required this.bytes,
    required this.filename,
    this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String? mimeType;
}

class FilePickService {
  FilePickService._();

  static Future<PickedFileBytes?> pickPdfOrDoc() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.first;
    if (f.bytes == null) return null;
    return PickedFileBytes(
      bytes: f.bytes!,
      filename: f.name,
      mimeType: f.name.toLowerCase().endsWith('.pdf')
          ? 'application/pdf'
          : f.name.toLowerCase().endsWith('.docx')
          ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          : 'application/msword',
    );
  }

  static Future<PickedFileBytes?> pickSpreadsheet() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.first;
    if (f.bytes == null) return null;
    return PickedFileBytes(bytes: f.bytes!, filename: f.name);
  }

  static Future<PickedFileBytes?> pickAnyAttachment() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.first;
    if (f.bytes == null) return null;
    return PickedFileBytes(bytes: f.bytes!, filename: f.name);
  }
}

class ImagePickService {
  ImagePickService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<PickedFileBytes?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    final x = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    final name = x.name.isNotEmpty ? x.name : 'image.jpg';
    return PickedFileBytes(bytes: bytes, filename: name, mimeType: _mimeFor(name));
  }

  /// Shows a chooser for camera vs gallery, then picks.
  static Future<PickedFileBytes?> pickImageWithChooser(
    BuildContext context,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    try {
      return await pickImage(source: source);
    } on PlatformException catch (e) {
      // Camera / photos permission denied, or no camera on the device.
      if (context.mounted) {
        final denied = e.code.contains('access_denied');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              denied
                  ? 'Permission denied. Allow camera / photos access in Settings.'
                  : 'Could not open the ${source == ImageSource.camera ? 'camera' : 'gallery'}.',
            ),
          ),
        );
      }
      return null;
    }
  }

  /// Mime type from the file name, so a WebP / GIF is not sent as JPEG.
  static String _mimeFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }
}
