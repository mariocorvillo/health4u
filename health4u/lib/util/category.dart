import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class Category extends pw.StatelessWidget {
  final String title;
  final pw.Font font;

  Category(this.title, this.font);

  @override
  pw.Widget build(pw.Context context) => pw.Container(
      decoration: const pw.BoxDecoration(
          color: PdfColor.fromInt(0xFF80EBA5),
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(6))),
      margin: const pw.EdgeInsets.only(bottom: 10, top: 20),
      padding: const pw.EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: pw.Text(title,
          textScaleFactor: 1.5, style: pw.TextStyle(font: font)));
}
