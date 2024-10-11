import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfService {
  Future<void> generarPDF({
    required String paciente,
    required String pacienteUid,
    required String fechaCita,
    required String diagnostico,
    required String tratamiento,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Documento Médico',
                style: const pw.TextStyle(fontSize: 32)),
            pw.SizedBox(height: 20),
            pw.Text('Paciente: $paciente',
                style: const pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 10),
            pw.Text('Fecha de Cita: $fechaCita',
                style: const pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 10),
            pw.Text('Diagnóstico:', style: const pw.TextStyle(fontSize: 24)),
            pw.Text(diagnostico, style: const pw.TextStyle(fontSize: 20)),
            pw.SizedBox(height: 10),
            pw.Text('Tratamiento:', style: const pw.TextStyle(fontSize: 24)),
            pw.Text(tratamiento, style: const pw.TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );

    final direccion = await getTemporaryDirectory();
    final nombreFichero =
        'documento_${paciente}_${fechaCita.replaceAll('/', '-')}.pdf';
    final ruta = '${direccion.path}/$nombreFichero';
    final fichero = File(ruta);
    await fichero.writeAsBytes(await pdf.save());

    final refAlmacenamiento = FirebaseStorage.instance
        .ref()
        .child('documentos_medicos/$pacienteUid/$nombreFichero');
    final tarea = refAlmacenamiento.putFile(fichero);

    final TaskSnapshot snapshot = await tarea;
    final String url = await snapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('documentos_medicos').add({
      'pacienteUid': pacienteUid,
      'paciente': paciente,
      'fechaCita': fechaCita,
      'diagnostico': diagnostico,
      'tratamiento': tratamiento,
      'url': url,
      'fechaCreacion': Timestamp.now(),
    });
  }
}
