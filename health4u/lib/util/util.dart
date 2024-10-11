// ignore_for_file: avoid_print

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health4u/util/category.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

Future<Uint8List> generatePdf(String paciente, String diagnostico,
    String tratamiento, String fechaCita) async {
  final doc = pw.Document(title: 'health4u');
  final logoImage = pw.MemoryImage(
      (await rootBundle.load('img/Logo.jpeg')).buffer.asUint8List());

  final footerImage = pw.MemoryImage(
      (await rootBundle.load('assets/footer.png')).buffer.asUint8List());
  final font = await rootBundle.load('assets/OpenSans-Regular.ttf');
  final ttf = pw.Font.ttf(font);

  final User? currentUser = FirebaseAuth.instance.currentUser;
  String? uid = currentUser?.uid;

  String medico = "Desconocido";

  if (uid != null) {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    medico = userDoc['nombre'];
  }

  final pageTheme = await tema();

  doc.addPage(pw.MultiPage(
      pageTheme: pageTheme,
      header: (context) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    height: 80,
                    child: pw.Image(
                      logoImage,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'MÉDICO: $medico',
                    style: pw.TextStyle(font: ttf, fontSize: 20),
                  ),
                  pw.Text('PACIENTE: $paciente',
                      style: pw.TextStyle(font: ttf, fontSize: 20)),
                  pw.Text('FECHA: $fechaCita',
                      style: pw.TextStyle(font: ttf, fontSize: 20)),
                ],
              ),
            ],
          ),
      footer: (final context) => pw.Image(
            footerImage,
            fit: pw.BoxFit.scaleDown,
          ),
      build: (final context) => [
            pw.SizedBox(height: 80),
            pw.Center(
                child: pw.Text('PRESCRIPCIÓN',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                        font: ttf,
                        fontSize: 40,
                        fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 40),
            pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: Category('DIAGNÓSTICO', ttf)),
            pw.Paragraph(
                margin: const pw.EdgeInsets.only(top: 10),
                text: diagnostico,
                style: pw.TextStyle(
                    font: ttf,
                    lineSpacing: 8,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold)),
            pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: Category('TRATAMIENTO', ttf)),
            pw.Paragraph(
                margin: const pw.EdgeInsets.only(top: 10),
                text: tratamiento,
                style: pw.TextStyle(
                    font: ttf,
                    lineSpacing: 8,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold)),
          ]));
  return doc.save();
}

Future<void> uploadFileToStorage(Uint8List fileBytes, String fileName) async {
  try {
    final firebase_storage.Reference ref =
        firebase_storage.FirebaseStorage.instance.ref().child(fileName);
    await ref.putData(fileBytes);
    print('Archivo subido a Firebase Storage.');
    final String downloadURL = await ref.getDownloadURL();
    print('URL de descarga del archivo: $downloadURL');
  } catch (e) {
    print('Error al subir el archivo a Firebase Storage: $e');
  }
}

Future<pw.PageTheme> tema() async {
  final logoImage = pw.MemoryImage(
      (await rootBundle.load('img/Logo.jpeg')).buffer.asUint8List());

  return pw.PageTheme(
    margin: const pw.EdgeInsets.symmetric(
        horizontal: 1 * PdfPageFormat.cm, vertical: 0.5 * PdfPageFormat.cm),
    textDirection: pw.TextDirection.ltr,
    orientation: pw.PageOrientation.portrait,
    buildBackground: (context) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Transform.rotate(
          angle: 0,
          child: pw.Watermark(
            angle: 0,
            child: pw.Opacity(
              opacity: 0.25,
              child: pw.Container(
                width: 20,
                height: 20,
                child: pw.Image(
                  alignment: pw.Alignment.center,
                  logoImage,
                ),
              ),
            ),
          ),
        )),
  );
}

Future<void> saveAsFile(final BuildContext context, final LayoutCallback build,
    final PdfPageFormat pageFormat) async {
  final bytes = await build(pageFormat);
  final appDocDir = await getApplicationCacheDirectory();
  final appDocPath = appDocDir.path;
  final file = File('$appDocPath/document.pdf');
  print('save as file ${file.path}...');
  await file.writeAsBytes(bytes);
  await OpenFile.open(file.path);
}
