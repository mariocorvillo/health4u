import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'documento.dart';

class CitaPreviaMedico extends StatefulWidget {
  const CitaPreviaMedico({super.key});

  @override
  CitaPreviaMedicoState createState() => CitaPreviaMedicoState();
}

class CitaPreviaMedicoState extends State<CitaPreviaMedico> {
  String? usuarioLogeado;

  @override
  void initState() {
    super.initState();
    cargaUsuario();
  }

  Future<void> cargaUsuario() async {
    User? usuario = FirebaseAuth.instance.currentUser;

    if (usuario != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();
      setState(() {
        usuarioLogeado = userDoc['nombre'];
      });
    }
  }

  Future<String?> obtenerPacienteUid(String pacienteNombre) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('nombre', isEqualTo: pacienteNombre)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> citasMedico() async {
    List<Map<String, dynamic>> citas = [];

    if (usuarioLogeado != null) {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('citas')
          .where('medico', isEqualTo: usuarioLogeado)
          .get();

      for (var cita in result.docs) {
        final data = cita.data() as Map<String, dynamic>;
        final String pacienteNombre = data['paciente'] ?? 'Desconocido';
        final String? pacienteUid = await obtenerPacienteUid(pacienteNombre);
        data['pacienteUid'] = pacienteUid;
        citas.add(data);
      }
      citas.sort((a, b) {
        var fechaAntigua = a['fecha'] as Timestamp;
        var fechaNueva = b['fecha'] as Timestamp;
        return fechaAntigua.compareTo(fechaNueva);
      });
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
          child: Text('CITAS PREVIAS', textAlign: TextAlign.center),
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
                    child: Text(
                      'CITAS PROGRAMADAS',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: citasMedico(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                              child: Text('No hay citas programadas.'));
                        } else {
                          return ListView(
                            children: snapshot.data!.map((data) {
                              final DateTime fecha = data['fecha'].toDate();
                              final String pacienteUid =
                                  data['pacienteUid'] ?? '';
                              final String pacienteNombre =
                                  data['paciente'] ?? 'Desconocido';

                              return GestureDetector(
                                onTap: () {
                                  String fechaCitaStr = fecha.toString();

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DocumentoMedico(
                                        paciente: pacienteNombre,
                                        pacienteUid: pacienteUid,
                                        fechaCita: fechaCitaStr,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
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
                                                  pacienteNombre,
                                                  textAlign: TextAlign.left,
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
