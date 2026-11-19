/// A training video or document published by the LO Committee
/// (aide-service `LoTrainingMaterialDto`).
class TrainingMaterial {
  const TrainingMaterial({
    required this.id,
    required this.title,
    required this.type,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.sha256,
    this.description,
    this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final TrainingMaterialType type;
  final String fileName;
  final String mimeType;
  final int sizeBytes;

  /// Hex SHA-256 of the file on the server; downloads are checked against it.
  final String sha256;
  final DateTime? createdAt;

  bool get isVideo => type == TrainingMaterialType.video;

  /// File extension taken from the server's MIME type, never from user input.
  String get extension {
    switch (mimeType) {
      case 'video/mp4':
        return 'mp4';
      case 'video/quicktime':
        return 'mov';
      case 'application/pdf':
        return 'pdf';
      case 'application/msword':
        return 'doc';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return 'docx';
      case 'application/vnd.ms-powerpoint':
        return 'ppt';
      case 'application/vnd.openxmlformats-officedocument.presentationml.presentation':
        return 'pptx';
      case 'application/vnd.ms-excel':
        return 'xls';
      case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        return 'xlsx';
      default:
        return 'bin';
    }
  }

  factory TrainingMaterial.fromJson(Map<String, dynamic> json) {
    return TrainingMaterial(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      description: _trimOrNull(json['description']),
      type: TrainingMaterialType.fromApi(json['materialType']?.toString()),
      fileName: json['fileName']?.toString() ?? 'file',
      mimeType: json['mimeType']?.toString() ?? 'application/octet-stream',
      sizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      sha256: json['sha256']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'materialType': type.api,
    'fileName': fileName,
    'mimeType': mimeType,
    'fileSizeBytes': sizeBytes,
    'sha256': sha256,
    'createdAt': createdAt?.toIso8601String(),
  };

  static String? _trimOrNull(Object? v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }
}

enum TrainingMaterialType {
  video('VIDEO'),
  document('DOCUMENT');

  const TrainingMaterialType(this.api);

  final String api;

  static TrainingMaterialType fromApi(String? raw) =>
      raw?.toUpperCase() == 'VIDEO' ? video : document;
}

/// "1.4 GB", "820 MB", "96 KB".
String formatFileSize(int bytes) {
  if (bytes <= 0) return '0 KB';
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
  if (bytes >= mb) {
    return '${(bytes / mb).toStringAsFixed(bytes >= 100 * mb ? 0 : 1)} MB';
  }
  return '${(bytes / kb).ceil()} KB';
}
