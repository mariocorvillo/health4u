// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OlvidasteContrasena extends StatefulWidget {
  const OlvidasteContrasena({super.key});

  @override
  OlvidasteContrasenaState createState() => OlvidasteContrasenaState();
}

class OlvidasteContrasenaState extends State<OlvidasteContrasena> {
  final TextEditingController correoController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;

  void resetearContrasena() async {
    {
      await auth.sendPasswordResetEmail(email: correoController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Correo enviado para restablecer contraseña')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.green,
        title: const Center(
          child: Text(
            'RECUPERACIÓN DE \nCONTRASEÑA',
            textAlign: TextAlign.center,
          ),
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
                    TextField(
                      controller: correoController,
                      decoration: const InputDecoration(
                          labelText: 'Correo Electrónico'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: resetearContrasena,
                      child: const Text('Enviar Correo'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      )),
    );
  }
}
