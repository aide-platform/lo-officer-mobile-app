import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
      mimeType: 'application/pdf',
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
    return PickedFileBytes(bytes: bytes, filename: name, mimeType: 'image/jpeg');
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
    return pickImage(source: source);
  }
}
