import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

Future<void> savePdfMobile(Uint8List pdfBytes) async {
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdfBytes,
  );
}

Future<void> printQrCodeMobile(Uint8List pdfBytes) async {
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdfBytes,
  );
}
