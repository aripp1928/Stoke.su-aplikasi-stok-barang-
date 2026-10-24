import 'dart:typed_data';
import 'package:printing/printing.dart';

Future<void> downloadFile({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  final uint8 = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  await Printing.sharePdf(bytes: uint8, filename: filename);
}
