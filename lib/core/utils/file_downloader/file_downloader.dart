import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart'
    if (dart.library.io) 'file_downloader_io.dart';

class FileDownloader {
  FileDownloader._();

  static Future<void> download({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) {
    return downloadFile(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );
  }
}
