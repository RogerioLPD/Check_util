import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

Future<void> savePdfWeb(Uint8List pdfBytes, String fileName) async {
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..target = '_blank'
    ..download = '$fileName.pdf'
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> printQrCodeWeb(Uint8List pdfBytes) async {
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..target = '_blank'
    ..click();
  html.Url.revokeObjectUrl(url);
}
