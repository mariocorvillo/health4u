import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health4u/pantallas/mensaje.dart';

class ChatUsuarios extends StatefulWidget {
  const ChatUsuarios({super.key});

  @override
  State<ChatUsuarios> createState() => ChatUsuariosState();
}

class ChatUsuariosState extends State<ChatUsuarios> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  late TextEditingController busquedaController;
  String buscarText = '';

  @override
  void initState() {
    super.initState();
    busquedaController = TextEditingController();
    busquedaController.addListener(() {
      setState(() {
        buscarText = busquedaController.text;
      });
    });
  }

  @override
  void dispose() {
    busquedaController.dispose();
    super.dispose();
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
          child: Text('CHATS', textAlign: TextAlign.center),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: busquedaController,
              onChanged: (value) {
                setState(() {
                  buscarText = value;
                });
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                hintText: 'Buscar',
              ),
            ),
          ),
          Expanded(child: listaUsuarios()),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 128, 235, 165),
    );
  }

  Widget listaUsuarios() {
    final User? usuario = auth.currentUser;

    if (usuario == null) {
      return const Center(child: Text('No está autenticado'));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error al cargar el usuario');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Cargando...');
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Usuario no encontrado');
        }

        Map<String, dynamic> data =
            snapshot.data!.data() as Map<String, dynamic>;
        String userType = data['rol'] == 'Paciente' ? 'Medico' : 'Paciente';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .where('rol', isEqualTo: userType)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Error al cargar la lista de usuarios');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Cargando...');
            }

            var documentos = snapshot.data!.docs;

            if (buscarText.isNotEmpty) {
              documentos = documentos.where((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                return data['nombre']
                    .toString()
                    .toLowerCase()
                    .contains(buscarText.toLowerCase());
              }).toList();
            }

            return ListView(
              children: documentos
                  .map<Widget>((doc) => listaElementosUsuario(doc))
                  .toList(),
            );
          },
        );
      },
    );
  }

  Widget listaElementosUsuario(DocumentSnapshot documento) {
    Map<String, dynamic> data = documento.data()! as Map<String, dynamic>;

    return ListTile(
      title: Text(data['nombre']),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Chats(
              receptorNombre: data['nombre'],
              receptorId: data['id'],
            ),
          ),
        );
      },
    );
  }
}
