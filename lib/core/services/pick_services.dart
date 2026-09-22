import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
}
