import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health4u/service/signaling.dart';

class SalaVirtual extends StatefulWidget {
  const SalaVirtual({super.key});

  @override
  SalaVirtualState createState() => SalaVirtualState();
}

class SalaVirtualState extends State<SalaVirtual> {
  final Signaling signaling = Signaling();
  final RTCVideoRenderer local = RTCVideoRenderer();
  final RTCVideoRenderer remoto = RTCVideoRenderer();
  final TextEditingController textoController = TextEditingController();
  final TextEditingController idSalaController = TextEditingController();

  String? rol;
  bool muestraBotones = true;
  bool muestraIdSala = true;
  bool conectado = false;

  @override
  void initState() {
    super.initState();
    inicializarRenderizadores();
    buscarRoles();
    signaling.anadirRemoto = streamRemoto;
  }

  Future<void> inicializarRenderizadores() async {
    try {
      await local.initialize();
      await remoto.initialize();
    } catch (e) {
      muestraAlerta("Error al iniciar los renderizadores: $e");
    }
  }

  Future<void> buscarRoles() async {
    final idUsuario = FirebaseAuth.instance.currentUser?.uid;
    if (idUsuario == null) {
      muestraAlerta("Usuario no identificado");
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(idUsuario)
          .get();

      if (userDoc.exists) {
        setState(() {
          rol = userDoc['rol'];
        });
      } else {
        muestraAlerta("Rol no encontrado");
      }
    } catch (e) {
      muestraAlerta("Error al buscar el rol: $e");
    }
  }

  void streamRemoto(MediaStream stream) {
    remoto.srcObject = stream;
    setState(() {
      muestraBotones = false;
      muestraIdSala = false;
      conectado = true;
    });
  }

  @override
  void dispose() {
    local.dispose();
    remoto.dispose();
    super.dispose();
  }

  Future<bool> estaCamaraActivada() async {
    return local.srcObject != null;
  }

  void muestraAlerta(String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("¡ALERTA!"),
          content: Text(mensaje),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: conectado
              ? null
              : () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (route) => false);
                },
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.green,
        title: const Center(
          child: Text('SALA VIRTUAL', textAlign: TextAlign.center),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          if (muestraBotones)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await signaling.accederMicrofonoyCamara(local, remoto);
                    } catch (e) {
                      muestraAlerta("Error al activar la cámara camera: $e");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                  ),
                  child: const Text("Activar cámara"),
                ),
                const SizedBox(width: 8),
                if (rol == 'Medico')
                  ElevatedButton(
                    onPressed: () async {
                      if (await estaCamaraActivada()) {
                        final idSala = idSalaController.text.trim();
                        if (idSala.isEmpty) {
                          muestraAlerta("Por favor, ingresa un ID de sala.");
                          return;
                        }
                        try {
                          await signaling.crearSala(remoto, idSala: idSala);
                          setState(() {});
                        } catch (e) {
                          muestraAlerta("Error al crear la sala: $e");
                        }
                      } else {
                        muestraAlerta("Por favor, activa la cámara primero.");
                      }
                    },
                    child: const Text("Crear sala"),
                  )
                else
                  ElevatedButton(
                    onPressed: () async {
                      if (await estaCamaraActivada()) {
                        final idSala = idSalaController.text.trim();
                        if (idSala.isEmpty) {
                          muestraAlerta("Por favor, ingresa un ID de sala.");
                          return;
                        }

                        try {
                          final salaSnapshot = await FirebaseFirestore.instance
                              .collection('salas')
                              .doc(idSala)
                              .get();

                          if (!salaSnapshot.exists) {
                            muestraAlerta(
                                "La sala con el ID $idSala no existe. Verifica el código.");
                            return;
                          }

                          await signaling.unirseSala(idSala, remoto);
                        } catch (e) {
                          muestraAlerta("Error al unirse a la sala: $e");
                        }
                      } else {
                        muestraAlerta("Por favor, activa la cámara primero.");
                      }
                    },
                    child: const Text("Unirse a la sala"),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    height: 50,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('salas')
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else {
                          final salas = snapshot.data?.docs ?? [];
                          return ListView.builder(
                            itemCount: salas.length,
                            itemBuilder: (BuildContext context, int index) {
                              if (idSalaController.text.trim() ==
                                      salas[index].id &&
                                  rol == 'Medico') {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  width: 200,
                                  height: 50,
                                );
                              }
                              return Container();
                            },
                          );
                        }
                      },
                    ),
                  ),
                  Expanded(child: RTCVideoView(remoto)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Visibility(
                  visible: muestraIdSala && muestraBotones,
                  child: const Text("ID de la sala: "),
                ),
                Visibility(
                  visible: muestraIdSala && muestraBotones,
                  child: Flexible(
                    child: TextFormField(
                      controller: idSalaController,
                      decoration: const InputDecoration(
                        hintText: 'Ingresar ID de la sala',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          IconButton(
            onPressed: conectado
                ? () {
                    signaling.colgarLlamada(local);
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/home', (route) => false);
                  }
                : null,
            icon: const Icon(Icons.call_end),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
