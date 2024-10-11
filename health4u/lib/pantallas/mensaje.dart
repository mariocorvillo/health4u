import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health4u/service/chat.dart';

class Chats extends StatefulWidget {
  final String receptorNombre;
  final String receptorId;
  const Chats(
      {super.key, required this.receptorNombre, required this.receptorId});

  @override
  State<Chats> createState() => ChatState();
}

class ChatState extends State<Chats> {
  final TextEditingController mensajeController = TextEditingController();
  final Chat chat = Chat();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final ScrollController scrollController = ScrollController();

  void enviarMensaje() async {
    if (mensajeController.text.isNotEmpty) {
      await chat.enviarMensaje(widget.receptorId, mensajeController.text);
      mensajeController.clear();
      scroll();
    }
  }

  void scroll() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget mensajeEntrada() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: mensajeController,
              decoration: InputDecoration(
                hintText: 'Enviar mensaje',
                fillColor: Colors.lightGreen[100],
                filled: true,
                contentPadding:
                    const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
              ),
            ),
          ),
          IconButton(onPressed: enviarMensaje, icon: const Icon(Icons.send)),
        ],
      ),
    );
  }

  Widget listaMensajes() {
    String emisor = auth.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: chat.recibirMensajes(emisor, widget.receptorId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Cargando...');
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scroll();
        });
        return ListView(
          controller: scrollController,
          children: snapshot.data!.docs
              .map<Widget>((doc) => elementoMensaje(doc))
              .toList(),
        );
      },
    );
  }

  Widget elementoMensaje(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
    var alinear = (data['emisorId'] == auth.currentUser!.uid
        ? Alignment.centerRight
        : Alignment.centerLeft);

    var color = (data['emisorId'] == auth.currentUser!.uid
        ? Colors.green
        : const Color.fromARGB(255, 101, 112, 112));

    return Container(
      alignment: alinear,
      child: Column(
        crossAxisAlignment: (data['emisorId'] == auth.currentUser!.uid)
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisAlignment: (data['emisorId'] == auth.currentUser!.uid)
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Bocadillo(
            mensaje: data['mensaje'],
            color: color,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receptorNombre),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(child: listaMensajes()),
          mensajeEntrada(),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 128, 235, 165),
    );
  }
}

class Mensaje {
  final String emisorId;
  final String emisorNombre;
  final String receptorId;
  final String mensaje;
  final Timestamp timestamp;

  Mensaje(
      {required this.emisorId,
      required this.emisorNombre,
      required this.receptorId,
      required this.mensaje,
      required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'emisorId': emisorId,
      'emisorNombre': emisorNombre,
      'receptorId': receptorId,
      'mensaje': mensaje,
      'timestamp': timestamp
    };
  }
}
