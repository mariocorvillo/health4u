import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PacientesMedico extends StatefulWidget {
  const PacientesMedico({super.key});

  @override
  PacientesMedicoState createState() => PacientesMedicoState();
}

class PacientesMedicoState extends State<PacientesMedico> {
  String? usuarioLogeado;

  @override
  void initState() {
    super.initState();
    getUsuarioLogeado();
  }

  Future<void> getUsuarioLogeado() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario != null) {
      final docUsuario = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();
      final data = docUsuario.data();
      if (data != null) {
        setState(() {
          usuarioLogeado = data['nombre'];
        });
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
        title:
            Text('PACIENTES DE \n$usuarioLogeado', textAlign: TextAlign.center),
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 128, 235, 165),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('citas')
              .where('medico', isEqualTo: usuarioLogeado)
              .orderBy('fecha', descending: true)
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
                  child: Text('No hay pacientes asignados a este médico.'));
            } else {
              final citas = snapshot.data!.docs;

              citas.sort((a, b) {
                var fechaAntigua = a['fecha'] as Timestamp;
                var fechaNueva = b['fecha'] as Timestamp;
                return fechaAntigua.compareTo(fechaNueva);
              });
              return ListView.builder(
                itemCount: citas.length,
                itemBuilder: (context, index) {
                  final cita = citas[index];
                  final pacienteId = cita['paciente'];
                  final tipoCita = cita['tipo'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ListTile(
                        title: Text(
                          pacienteId,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        trailing: tipoCita == 'Telemática'
                            ? IconButton(
                                icon: const Icon(Icons.call),
                                onPressed: () => Navigator.of(context)
                                    .pushNamedAndRemoveUntil(
                                        '/salaVirtual', (route) => false),
                              )
                            : null,
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
