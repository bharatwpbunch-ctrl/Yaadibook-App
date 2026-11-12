/// Represents a file attachment (photo or document) associated with a service entry.
class ServiceAttachment {
  final String id;
  final String businessId;
  final String serviceId;
  final String filePath;
  final String fileName;
  final int? fileSize;
  final String? mimeType;
  final DateTime createdAt;

  const ServiceAttachment({
    required this.id,
    required this.businessId,
    required this.serviceId,
    required this.filePath,
    required this.fileName,
    this.fileSize,
    this.mimeType,
    required this.createdAt,
  });

  bool get isImage {
    if (mimeType != null && mimeType!.startsWith('image/')) return true;
    final lower = fileName.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  bool get isPdf {
    if (mimeType == 'application/pdf') return true;
    return fileName.toLowerCase().endsWith('.pdf');
  }

  String get formattedFileSize {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory ServiceAttachment.fromJson(Map<String, dynamic> json) {
    return ServiceAttachment(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      serviceId: json['service_id'] as String,
      filePath: json['file_path'] as String,
      fileName: json['file_name'] as String,
      fileSize: json['file_size'] as int?,
      mimeType: json['mime_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'service_id': serviceId,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
