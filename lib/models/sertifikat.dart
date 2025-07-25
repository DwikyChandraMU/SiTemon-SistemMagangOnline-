import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/services.dart';

class CertificateScreen extends StatelessWidget {
  final String userName;

  CertificateScreen({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Certificate"),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Your Certificate",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _generateCertificate(userName);
              },
              child: Text("Download Certificate"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateCertificate(String userName) async {
    PdfDocument document = PdfDocument();
    document.pageSettings.orientation = PdfPageOrientation.landscape;
    document.pageSettings.size = PdfPageSize.a4;
    final PdfPage page = document.pages.add();
    final double pageWidth = page.getClientSize().width;
    final double pageHeight = page.getClientSize().height;

    final PdfBrush blueBrush = PdfSolidBrush(PdfColor(0, 70, 130));
    final PdfBrush whiteBrush = PdfSolidBrush(PdfColor(255, 255, 255));
    final PdfBrush goldBrush = PdfSolidBrush(PdfColor(255, 204, 0));

    page.graphics.drawRectangle(
      brush: blueBrush,
      bounds: Rect.fromLTWH(20, 20, pageWidth - 40, pageHeight - 40),
    );

    page.graphics.drawRectangle(
      brush: goldBrush,
      bounds: Rect.fromLTWH(30, 30, pageWidth - 60, pageHeight - 60),
    );

    page.graphics.drawRectangle(
      brush: whiteBrush,
      bounds: Rect.fromLTWH(40, 40, pageWidth - 80, pageHeight - 80),
    );

    page.graphics.drawString(
      'CERTIFICATE OF INTERNSHIP',
      PdfStandardFont(PdfFontFamily.timesRoman, 30, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(0, 50, pageWidth, 50),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    page.graphics.drawString(
      'THIS CERTIFICATE IS PROUDLY PRESENTED TO',
      PdfStandardFont(PdfFontFamily.helvetica, 14),
      bounds: Rect.fromLTWH(0, 110, pageWidth, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    page.graphics.drawString(
      userName,
      PdfStandardFont(PdfFontFamily.timesRoman, 26, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(0, 140, pageWidth, 50),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    page.graphics.drawString(
      'We are happy to certify that $userName has completed his Home Internship as a "Content Writer" from 17 September to 10 December, 2023.',
      PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.italic),
      bounds: Rect.fromLTWH(100, 200, pageWidth - 200, 100),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    page.graphics.drawEllipse(
      Rect.fromLTWH((pageWidth - 60) / 2, pageHeight - 120, 60, 60),
      pen: PdfPen(PdfColor(255, 204, 0), width: 3),
      brush: goldBrush,
    );

    page.graphics.drawString(
      'Sincerely Yours,\nAaron Loeb\nFounder & CEO',
      PdfStandardFont(PdfFontFamily.helvetica, 14),
      bounds: Rect.fromLTWH(100, pageHeight - 100, 200, 50),
    );

    page.graphics.drawString(
      'Sincerely Yours,\nOlivia Wilson\nGeneral Manager',
      PdfStandardFont(PdfFontFamily.helvetica, 14),
      bounds: Rect.fromLTWH(pageWidth - 300, pageHeight - 100, 200, 50),
    );

    List<int> bytes = await document.save();
    document.dispose();

    final String dir = (await getApplicationDocumentsDirectory()).path;
    final String path = '$dir/certificate.pdf';
    final File file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    await OpenFilex.open(path); // Menggunakan OpenFilex.open
  }
}
