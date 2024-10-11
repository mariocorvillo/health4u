import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Perfil extends StatefulWidget {
  const Perfil({super.key});

  @override
  State<Perfil> createState() => PerfilState();
}

class PerfilState extends State<Perfil> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String nombre = "";
  String email = "";
  String dni = "";
  String genero = "";
  String fechaNacimiento = "";
  String grupoSanguineo = "";
  String tarjetaSanitaria = "";

  @override
  void initState() {
    super.initState();
    obtenerDatosUsuario();
  }

  void obtenerDatosUsuario() async {
    User? usuario = auth.currentUser;
    if (usuario != null) {
      DocumentSnapshot snapshot =
          await firestore.collection('usuarios').doc(usuario.uid).get();
      if (snapshot.exists) {
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

        if (data != null) {
          setState(() {
            nombre = data['nombre'] ?? '';
            email = data['email'] ?? '';
            dni = data['dni'] ?? '';
            genero = data['genero'] ?? '';
            fechaNacimiento = data['fechaNacimiento'] ?? '';
            grupoSanguineo = data['grupoSanguineo'] ?? '';
            tarjetaSanitaria = data['tarjetaSanitaria'] ?? '';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/home');
          },
        ),
        backgroundColor: Colors.green,
        title: const Center(child: Text('PERFIL')),
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
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Nombre:',
                              textAlign: TextAlign.justify,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              nombre,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 42, 124, 53)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10, height: 5),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Correo electrónico:',
                              textAlign: TextAlign.justify,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              email,
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 42, 124, 53)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10, height: 5),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'DNI/NIE:',
                              textAlign: TextAlign.justify,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              dni,
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 42, 124, 53)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10, height: 5),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Género:',
                              textAlign: TextAlign.justify,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              genero,
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 42, 124, 53)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10, height: 5),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Fecha de \nnacimiento:',
                              textAlign: TextAlign.justify,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              fechaNacimiento,
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 42, 124, 53)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10, height: 5),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Grupo sanguíneo:',
                              textAlign: TextAlign.justify,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              grupoSanguineo,
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 42, 124, 53)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10, height: 5),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Tarjeta sanitaria:',
                              textAlign: TextAlign.justify,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              tarjetaSanitaria,
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 42, 124, 53)),
                            ),
                          ),
                        ],
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
