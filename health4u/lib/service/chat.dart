import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health4u/pantallas/mensaje.dart';

class Chat extends ChangeNotifier {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> enviarMensaje(String receptorId, String mensaje) async {
    final String actualId = auth.currentUser!.uid;
    final String emisor = await obtenerNombreEmisor();
    final Timestamp timestamp = Timestamp.now();
    Mensaje nuevoMensaje = Mensaje(
      emisorId: actualId,
      emisorNombre: emisor,
      receptorId: receptorId,
      mensaje: mensaje,
      timestamp: timestamp,
    );

    List<String> ids = [actualId, receptorId];
    ids.sort();
    String chatId = ids.join("_");

    await firestore
        .collection('chat')
        .doc(chatId)
        .collection('mensajes')
        .add(nuevoMensaje.toMap());
  }

  Stream<QuerySnapshot> recibirMensajes(String id, String otroUsuarioId) {
    List<String> ids = [id, otroUsuarioId];
    ids.sort();
    String chatId = ids.join("_");

    return firestore
        .collection('chat')
        .doc(chatId)
        .collection('mensajes')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<String> obtenerNombreEmisor() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return '';
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      return data['nombre'] ?? '';
    } else {
      return '';
    }
  }
}

class Bocadillo extends StatelessWidget {
  final String mensaje;
  final Color color;

  const Bocadillo({super.key, required this.mensaje, required this.color});

  void copiarAlPortapapeles(BuildContext context) {
    Clipboard.setData(ClipboardData(text: mensaje));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mensaje copiado al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => copiarAlPortapapeles(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 25),
        child: Text(
          mensaje,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
