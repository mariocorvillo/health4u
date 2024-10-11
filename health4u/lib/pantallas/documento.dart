// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:health4u/service/pdf.dart';

class DocumentoMedico extends StatelessWidget {
  final String paciente;
  final String pacienteUid;
  final String fechaCita;

  const DocumentoMedico({
    super.key,
    required this.paciente,
    required this.pacienteUid,
    required this.fechaCita,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController diagnosticoController = TextEditingController();
    final TextEditingController tratamientoController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'GENERAR PDF',
          textAlign: TextAlign.center,
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 128, 235, 165),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 400,
                minWidth: 300,
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'PACIENTE: \n$paciente',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: diagnosticoController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Diagnóstico',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: tratamientoController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Tratamiento',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          final String diagnostico = diagnosticoController.text;
                          final String tratamiento = tratamientoController.text;

                          await PdfService().generarPDF(
                            paciente: paciente,
                            pacienteUid: pacienteUid,
                            fechaCita: fechaCita,
                            diagnostico: diagnostico,
                            tratamiento: tratamiento,
                          );

                          Navigator.pop(context);
                        },
                        child: const Text('Generar PDF'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
