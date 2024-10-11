import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VacunaEnfermero extends StatefulWidget {
  const VacunaEnfermero({super.key});

  @override
  VacunaEnfermeroState createState() => VacunaEnfermeroState();
}

class VacunaEnfermeroState extends State<VacunaEnfermero> {
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

  Future<List<DocumentSnapshot>> citasEnfermero() async {
    List<DocumentSnapshot> citas = [];

    if (usuarioLogeado != null) {
      final QuerySnapshot resultado = await FirebaseFirestore.instance
          .collection('vacunas')
          .where('enfermero', isEqualTo: usuarioLogeado)
          .orderBy('fecha', descending: false)
          .get();

      citas = resultado.docs;
    }

    return citas;
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
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
        backgroundColor: Colors.green,
        title: const Center(
          child: Text('CITAS DE \nVACUNACIÓN', textAlign: TextAlign.center),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 128, 235, 165),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Center(
                    child: Text('CITAS DE VACUNACIÓN PROGRAMADAS',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: FutureBuilder(
                      future: citasEnfermero(),
                      builder: (context,
                          AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                          return const Text(
                              'No hay citas de vacunación programadas.');
                        } else {
                          return ListView(
                            children: snapshot.data!.map((cita) {
                              final data = cita.data() as Map<String, dynamic>;
                              final DateTime fecha = data['fecha'].toDate();
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Expanded(
                                              child: Text(
                                                'Paciente:',
                                                textAlign: TextAlign.justify,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                '${data['paciente']}',
                                                textAlign: TextAlign.justify,
                                                style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 42, 124, 53),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            const Expanded(
                                              child: Text(
                                                'Fecha:',
                                                textAlign: TextAlign.justify,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                fecha
                                                    .toString()
                                                    .substring(0, 10),
                                                textAlign: TextAlign.justify,
                                                style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 42, 124, 53),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            const Expanded(
                                              child: Text(
                                                'Hora:',
                                                textAlign: TextAlign.justify,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                fecha
                                                    .toString()
                                                    .substring(11, 16),
                                                textAlign: TextAlign.justify,
                                                style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 42, 124, 53),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
