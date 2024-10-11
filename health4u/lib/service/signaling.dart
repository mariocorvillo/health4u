import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

class Signaling {
  Map<String, dynamic> configuracion = {
    'Servidores': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ]
      }
    ]
  };

  RTCPeerConnection? conexion;
  MediaStream? local;
  MediaStream? remoto;
  String? idText;
  StreamStateCallback? anadirRemoto;

  Future<String?> crearSala(
    RTCVideoRenderer remotoRenderer, {
    required String idSala,
  }) async {
    FirebaseFirestore baseDatos = FirebaseFirestore.instance;
    DocumentReference refSala = baseDatos.collection('salas').doc(idSala);

    conexion = await createPeerConnection(configuracion);

    registrarConexion();

    local?.getTracks().forEach((pista) {
      conexion?.addTrack(pista, local!);
    });

    var coleccionCliente = refSala.collection('Cliente');

    conexion?.onIceCandidate = (RTCIceCandidate candidato) {
      coleccionCliente.add(candidato.toMap());
    };

    RTCSessionDescription solicitud = await conexion!.createOffer();
    await conexion!.setLocalDescription(solicitud);

    Map<String, dynamic> salaSolicitud = {'offer': solicitud.toMap()};

    await refSala.set(salaSolicitud);
    idText = 'ID actual es: $idSala';

    conexion?.onTrack = (RTCTrackEvent evento) {
      evento.streams[0].getTracks().forEach((pista) {
        remoto?.addTrack(pista);
      });
    };

    refSala.snapshots().listen((snapshot) async {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      if (conexion?.getRemoteDescription() != null && data['answer'] != null) {
        var respuesta = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );

        await conexion?.setRemoteDescription(respuesta);
      }
    });

    refSala.collection('Servidor').snapshots().listen((snapshot) {
      for (var cambiar in snapshot.docChanges) {
        if (cambiar.type == DocumentChangeType.added) {
          Map<String, dynamic> data =
              cambiar.doc.data() as Map<String, dynamic>;
          conexion!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });

    return idSala;
  }

  Future<void> unirseSala(
      String idSala, RTCVideoRenderer remotoRenderer) async {
    FirebaseFirestore baseDatos = FirebaseFirestore.instance;
    DocumentReference refSala = baseDatos.collection('salas').doc(idSala);
    var salaSnapshot = await refSala.get();
    if (salaSnapshot.exists) {
      conexion = await createPeerConnection(configuracion);

      registrarConexion();

      local?.getTracks().forEach((pista) {
        conexion?.addTrack(pista, local!);
      });

      var collectionServidor = refSala.collection('Servidor');
      conexion!.onIceCandidate = (RTCIceCandidate? candidato) {
        if (candidato == null) {
          return;
        }

        collectionServidor.add(candidato.toMap());
      };

      conexion?.onTrack = (RTCTrackEvent evento) {
        evento.streams[0].getTracks().forEach((pista) {
          remoto?.addTrack(pista);
        });
      };

      var data = salaSnapshot.data() as Map<String, dynamic>;

      var solicitud = data['offer'];
      await conexion?.setRemoteDescription(
        RTCSessionDescription(solicitud['sdp'], solicitud['type']),
      );
      var respuesta = await conexion!.createAnswer();

      await conexion!.setLocalDescription(respuesta);

      Map<String, dynamic> salaRespuesta = {
        'answer': {'type': respuesta.type, 'sdp': respuesta.sdp}
      };

      await refSala.update(salaRespuesta);

      refSala.collection('Cliente').snapshots().listen((snapshot) {
        for (var documento in snapshot.docChanges) {
          var data = documento.doc.data() as Map<String, dynamic>;
          conexion!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      });
    }
  }

  Future<void> accederMicrofonoyCamara(
    RTCVideoRenderer localVideo,
    RTCVideoRenderer remotoVideo,
  ) async {
    var stream = await navigator.mediaDevices
        .getUserMedia({'video': true, 'audio': true});

    localVideo.srcObject = stream;
    local = stream;

    remotoVideo.srcObject = await createLocalMediaStream('key');
  }

  Future<void> colgarLlamada(RTCVideoRenderer localVideo) async {
    List<MediaStreamTrack> pistas = localVideo.srcObject!.getTracks();
    for (var pista in pistas) {
      pista.stop();
    }

    if (remoto != null) {
      remoto!.getTracks().forEach((pista) => pista.stop());
    }
    if (conexion != null) conexion!.close();

    if (idText != null) {
      var baseDatos = FirebaseFirestore.instance;
      var refSala = baseDatos.collection('salas').doc(idText);
      var servidor = await refSala.collection('Servidor').get();
      for (var documento in servidor.docs) {
        documento.reference.delete();
      }

      var cliente = await refSala.collection('Cliente').get();
      for (var documento in cliente.docs) {
        documento.reference.delete();
      }

      await refSala.delete();
    }

    local!.dispose();
    remoto?.dispose();
  }

  void registrarConexion() {
    conexion?.onIceGatheringState = (RTCIceGatheringState estado) {};

    conexion?.onConnectionState = (RTCPeerConnectionState estado) {};

    conexion?.onSignalingState = (RTCSignalingState estado) {};

    conexion?.onIceGatheringState = (RTCIceGatheringState estado) {};

    conexion?.onAddStream = (MediaStream stream) {
      anadirRemoto?.call(stream);
      remoto = stream;
    };
  }
}
