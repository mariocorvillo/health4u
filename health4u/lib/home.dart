// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health4u/pantallas/citapreviamedico.dart';
import 'package:health4u/pantallas/documentopaciente.dart';
import 'package:health4u/pantallas/salavirtual.dart';
import 'package:health4u/pantallas/usuarioschat.dart';
import 'package:health4u/pantallas/vacunasenfermero.dart';
import 'package:health4u/pantallas/vacunaspaciente.dart';
import 'pantallas/citapreviapaciente.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.rol});

  final String rol;

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> clave = GlobalKey();
  late TextEditingController busquedaController;
  String buscarText = '';

  @override
  void initState() {
    super.initState();
    busquedaController = TextEditingController();
  }

  @override
  void dispose() {
    busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Event> eventos = obtenerEventos();
    eventos = eventos.where((evento) => evento.rol == widget.rol).toList();

    final List<Event> filtraEventos = buscarText.isEmpty
        ? eventos
        : eventos
            .where((evento) =>
                evento.titulo.toLowerCase().contains(buscarText.toLowerCase()))
            .toList();

    return Scaffold(
      key: clave,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            clave.currentState!.openDrawer();
          },
        ),
        actions: const <Widget>[
          MuestraNombre(),
        ],
        backgroundColor: Colors.green,
      ),
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 128, 235, 165),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.green),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'HEALTH4U',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.1,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/perfil');
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 128, 235, 165),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(right: 30, left: 30, top: 30),
              child: Column(
                children: [
                  TextField(
                    controller: busquedaController,
                    onChanged: (valor) {
                      setState(() {
                        buscarText = valor;
                      });
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Buscar',
                    ),
                  ),
                ],
              ),
            ),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
              ),
              itemCount: filtraEventos.length,
              itemBuilder: (context, index) {
                final evento = filtraEventos[index];
                final indicePantalla = eventos.indexOf(evento);

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                          context, '/${eventos[indicePantalla].id}');
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        evento.imagen,
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.white.withOpacity(0.8),
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              evento.titulo,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MuestraNombre extends StatelessWidget {
  const MuestraNombre({super.key});

  @override
  Widget build(BuildContext context) {
    final User? usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      return const SizedBox();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }
        var userData = snapshot.data?.data() as Map<String, dynamic>;
        final nombre = userData['nombre'];
        if (userData['genero'] == 'Mujer') {
          return Padding(
            padding: const EdgeInsets.only(right: 40),
            child: Text(
              'Bienvenida\n $nombre',
              textAlign: TextAlign.center,
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(right: 40),
            child: Text(
              'Bienvenido\n $nombre',
              textAlign: TextAlign.center,
            ),
          );
        }
      },
    );
  }
}

List<Event> obtenerEventos() {
  return [
    Event(
        titulo: "Vacuna",
        imagen: Image.asset("img/vacuna.png", width: 40, height: 100),
        id: "vacuna",
        ruta: const VacunaPaciente(),
        rol: 'Paciente'),
    Event(
        titulo: "Cita previa",
        imagen: Image.asset("img/cita_previa.png", width: 40, height: 100),
        id: "citaPrevia",
        ruta: const CitaPreviaPaciente(),
        rol: 'Paciente'),
    Event(
      titulo: "Chat",
      imagen: Image.asset("img/chat.png", width: 40, height: 100),
      id: "chat",
      ruta: const ChatUsuarios(),
      rol: 'Paciente',
    ),
    Event(
      titulo: "Chat",
      imagen: Image.asset("img/chat.png", width: 40, height: 100),
      id: "chatMedico",
      ruta: const ChatUsuarios(),
      rol: 'Medico',
    ),
    Event(
        titulo: "Cita previa",
        imagen: Image.asset("img/cita_previa.png", width: 40, height: 100),
        id: "citaPreviaMedico",
        ruta: const CitaPreviaMedico(),
        rol: 'Medico'),
    Event(
        titulo: "Vacuna",
        imagen: Image.asset("img/vacuna.png", width: 40, height: 100),
        id: "vacunaEnfermero",
        ruta: const VacunaEnfermero(),
        rol: 'Enfermero'),
    Event(
        titulo: "Lista de Pacientes",
        imagen: Image.asset("img/pacientes.png", width: 40, height: 100),
        id: "pacientesMedico",
        ruta: const CitaPreviaMedico(),
        rol: 'Medico'),
    Event(
        titulo: "Lista de Pacientes",
        imagen: Image.asset("img/pacientes.png", width: 40, height: 100),
        id: "pacientesEnfermero",
        ruta: const VacunaEnfermero(),
        rol: 'Enfermero'),
    Event(
        titulo: "Documentos",
        imagen: Image.asset("img/documentacion.png", width: 40, height: 100),
        id: "documento",
        ruta: const DocumentoPaciente(),
        rol: 'Paciente'),
    Event(
        titulo: "Sala Virtual",
        imagen: Image.asset("img/sala_virtual.png", width: 40, height: 100),
        id: "salaVirtual",
        ruta: const SalaVirtual(),
        rol: 'Paciente'),
  ];
}

class Event {
  String titulo;
  Image imagen;
  String id;
  Widget ruta;
  String rol;

  Event({
    required this.titulo,
    required this.imagen,
    required this.id,
    required this.ruta,
    required this.rol,
  });
}
