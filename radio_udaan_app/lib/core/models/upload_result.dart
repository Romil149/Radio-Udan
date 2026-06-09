/// Staged upload reference from `POST /uploads` (used in registration payload).
class UploadResult {
  const UploadResult({required this.uploadId, required this.fileName});

  final String uploadId;
  final String fileName;
}
