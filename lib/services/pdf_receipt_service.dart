import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/receipt.dart';
import '../widgets/station_card.dart' show fmtDuration, fmtMoney;

final _dateFmt = DateFormat('dd.MM.yyyy HH:mm');
final _timeFmt = DateFormat('HH:mm');

class PdfReceiptService {
  /// Chekni PDF ko'rinishida tizimning standart print dialogiga yuboradi —
  /// shu orqali ulangan har qanday printerga (shu jumladan Bluetooth/Wi-Fi
  /// chek-printerga, agar u tizim drayveri orqali ko'rinsa) chiqarish mumkin.
  static Future<void> printReceipt(
      Receipt r, {
        String clubName = 'Game Club Timer',
        String clubAddr = '',
        String? qrLogoBase64,
      }) async {
    final doc = pw.Document();

    Uint8List? logoBytes;
    if (qrLogoBase64 != null && qrLogoBase64.isNotEmpty) {
      try {
        logoBytes = base64Decode(qrLogoBase64);
      } catch (_) {}
    }
    Uint8List? qrBytes;
    if (r.qrData != null && r.qrData!.isNotEmpty) {
      qrBytes = await _qrToPngBytes(r.qrData!, highErrorCorrection: logoBytes != null);
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 10),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(clubName.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              if (clubAddr.isNotEmpty) pw.Text(clubAddr, style: const pw.TextStyle(fontSize: 8)),
              pw.Divider(),
              _row('Chek', '#${r.receiptNumber.toString().padLeft(4, '0')}'),
              _row('Sana', _dateFmt.format(r.endTime)),
              _row('Stansiya', '${r.stationName} (${r.stationType})'),
              _row('Boshlanish', _timeFmt.format(r.startTime)),
              _row('Tugash', _timeFmt.format(r.endTime)),
              _row('Davomiyligi', fmtDuration(r.durationSeconds)),
              _row('Tarif', "${fmtMoney(r.tariffPerHour.toDouble())} so'm/soat"),
              if (r.barAmount > 0) _row('Bar / Xizmat', "${fmtMoney(r.barAmount)} so'm"),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('JAMI', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text("${fmtMoney(r.total)} so'm",
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 10),
              if (qrBytes != null)
                pw.Stack(
                  alignment: pw.Alignment.center,
                  children: [
                    pw.Image(pw.MemoryImage(qrBytes), width: 90, height: 90),
                    if (logoBytes != null)
                      pw.Container(
                        width: 22,
                        height: 22,
                        decoration: const pw.BoxDecoration(color: PdfColors.white),
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Image(pw.MemoryImage(logoBytes)),
                      ),
                  ],
                ),
              pw.SizedBox(height: 8),
              pw.Text('Xaridingiz uchun rahmat!', style: const pw.TextStyle(fontSize: 8)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static Future<Uint8List> _qrToPngBytes(String data, {bool highErrorCorrection = false}) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      errorCorrectionLevel: highErrorCorrection ? QrErrorCorrectLevel.H : QrErrorCorrectLevel.M,
    );
    final ui.Image img = await painter.toImage(300);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
