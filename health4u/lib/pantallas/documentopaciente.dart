// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class DocumentoPaciente extends StatefulWidget {
  const DocumentoPaciente({super.key});

  @override
  DocumentoPacienteState createState() => DocumentoPacienteState();
}

class DocumentoPacienteState extends State<DocumentoPaciente> {
  final FirebaseStorage almacenamiento = FirebaseStorage.instance;
  List<Map<String, dynamic>> listaDocumentos = [];

  @override
  void initState() {
    super.initState();
    cargaDocumentos();
  }

  Future<void> cargaDocumentos() async {
    User? usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      throw Exception('Usuario no autenticado');
    }

    final uid = usuario.uid;
    final ref = almacenamiento.ref().child('documentos_medicos/$uid');

    try {
      final ListResult resultado = await ref.listAll();
      final List<Map<String, dynamic>> documentos = [];

      for (final item in resultado.items) {
        final String url = await item.getDownloadURL();
        final String nombreFichero = item.name;

        final FullMetadata metadata = await item.getMetadata();
        final DateTime? fechaActualizada = metadata.updated;

        final String fechaCompleta =
            fechaActualizada != null ? fecha(fechaActualizada) : 'Desconocida';

        documentos.add({
          'url': url,
          'name': nombreFichero,
          'date': fechaCompleta,
        });
      }

      setState(() {
        listaDocumentos = documentos;
      });
    } catch (e) {
      print('Error al cargar documentos: $e');
    }
  }

  String fecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MIS DOCUMENTOS'),
        backgroundColor: Colors.green,
      ),
      backgroundColor: const Color.fromARGB(255, 128, 235, 165),
      body: listaDocumentos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: listaDocumentos.length,
              itemBuilder: (context, index) {
                final documento = listaDocumentos[index];
                final url = documento['url'];
                final nombreFichero = documento['name'];
                final fecha = documento['date'];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  elevation: 4,
                  child: ListTile(
                    leading:
                        const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(nombreFichero),
                    subtitle: Text('Fecha: $fecha'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VerPDF(pdfUrl: url),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class VerPDF extends StatefulWidget {
  final String pdfUrl;

  const VerPDF({required this.pdfUrl, super.key});

  @override
  VerPDFState createState() => VerPDFState();
}

class VerPDFState extends State<VerPDF> {
  String? rutaFichero;

  @override
  void initState() {
    super.initState();
    guardaPDF();
  }

  Future<void> guardaPDF() async {
    try {
      final respuesta = await http.get(Uri.parse(widget.pdfUrl));
      final bytes = respuesta.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final fichero = File(
          '${dir.path}/documento_${DateTime.now().millisecondsSinceEpoch}.pdf');

      await fichero.writeAsBytes(bytes, flush: true);

      setState(() {
        rutaFichero = fichero.path;
      });
    } catch (e) {
      print('Error al descargar el PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VER DOCUMENTO'),
        backgroundColor: Colors.green,
      ),
      body: rutaFichero == null
          ? const Center(child: CircularProgressIndicator())
          : PDFView(
              filePath: rutaFichero,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              swipeHorizontal: true,
              onError: (error) {
                print('Error al cargar el PDF: $error');
              },
              onPageError: (pagina, error) {
                print('Error en la página $pagina: $error');
              },
            ),
    );
  }
}
