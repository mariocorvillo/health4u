import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PacientesEnfermero extends StatefulWidget {
  const PacientesEnfermero({super.key});

  @override
  PacientesEnfermeroState createState() => PacientesEnfermeroState();
}

class PacientesEnfermeroState extends State<PacientesEnfermero> {
  String? usuarioLogeado;

  @override
  void initState() {
    super.initState();
    cargaUsuario();
  }

  Future<void> cargaUsuario() async {
    User? usuario = FirebaseAuth.instance.currentUser;

    if (usuario != null) {
      DocumentSnapshot docUsuario = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();
      setState(() {
        usuarioLogeado = docUsuario['nombre'];
      });
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
        title:
            Text('PACIENTES DE \n$usuarioLogeado', textAlign: TextAlign.center),
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 128, 235, 165),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vacunas')
              .where('enfermero', isEqualTo: usuarioLogeado)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text('No hay pacientes asignados a este enfermero.'));
            } else {
              final citas = snapshot.data!.docs;
              final pacientes = citas.map((cita) => cita['paciente']).toList();
              return ListView.builder(
                itemCount: pacientes.length,
                itemBuilder: (context, index) {
                  final nombre = pacientes[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
