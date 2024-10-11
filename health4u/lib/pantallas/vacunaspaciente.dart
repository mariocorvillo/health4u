// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VacunaPaciente extends StatefulWidget {
  const VacunaPaciente({super.key});

  @override
  VacunaPacienteState createState() => VacunaPacienteState();
}

class VacunaPacienteState extends State<VacunaPaciente> {
  String seleccionarEnfermero = '';
  DateTime seleccionarFecha = DateTime.now();
  String seleccionarHora = '${DateTime.now().hour + 1}:00';
  List<String> vacunas = [
    'COVID-19',
    'Influenza',
    'Hepatitis B',
    'Tétanos',
    'IPV',
    'VPH',
    'Varicela',
    'Otra'
  ];
  String tipoVacuna = 'COVID-19';

  List<DateTime> tiempoReservado = [];

  TextEditingController fechaController = TextEditingController();
  TextEditingController horaController = TextEditingController();
  bool citaDisponible = false;
  List<String> enfermeros = [];
  String? usuarioLogeado;

  @override
  void initState() {
    super.initState();
    fechaController.text = seleccionarFecha.toString().substring(0, 10);
    horaController.text = seleccionarHora;
    buscaCitasReservadas();
    buscaEnfermero();
    cargaUsuario();
    borrarCitasExpiradas();
  }

  Future<void> cargaUsuario() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      setState(() {
        usuarioLogeado = userDoc['nombre'];
      });
    }
  }

  Future<void> seleccionaDia(BuildContext context) async {
    final DateTime? seleccionado = await showDatePicker(
      context: context,
      initialDate: seleccionarFecha,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      selectableDayPredicate: (DateTime fecha) {
        return fecha.weekday != DateTime.saturday &&
            fecha.weekday != DateTime.sunday;
      },
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
            ),
          ),
          child: child!,
        );
      },
    );
    if (seleccionado != null && seleccionado != seleccionarFecha) {
      setState(() {
        seleccionarFecha = seleccionado;
        fechaController.text = seleccionado.toString().substring(0, 10);
        buscaCitasReservadas();
      });
    }
  }

  Future<void> buscaEnfermero() async {
    final QuerySnapshot resultado =
        await FirebaseFirestore.instance.collection('usuarios').get();

    final List<DocumentSnapshot> documentos = resultado.docs;

    List<String> listaEnfermeros = [];

    for (DocumentSnapshot doc in documentos) {
      final dynamic data = doc.data();
      if (data != null && data['rol'] == 'Enfermero') {
        listaEnfermeros.add(data['nombre']);
      }
    }
    setState(() {
      enfermeros = listaEnfermeros;
      seleccionarEnfermero = enfermeros.isNotEmpty ? enfermeros.first : '';
    });
    buscaCitasReservadas();
  }

  Future<void> buscaCitasReservadas() async {
    final QuerySnapshot resultado = await FirebaseFirestore.instance
        .collection('vacunas')
        .where('enfermero', isEqualTo: seleccionarEnfermero)
        .get();

    final List<DocumentSnapshot> documentos = resultado.docs;

    List<DateTime> horas = [];
    Set<String> citasPaciente = {};

    for (DocumentSnapshot doc in documentos) {
      final dynamic data = doc.data();
      if (data != null && data['fecha'] != null) {
        Timestamp timestamp = data['fecha'];
        DateTime fecha = timestamp.toDate();
        if (fecha.year == seleccionarFecha.year &&
            fecha.month == seleccionarFecha.month &&
            fecha.day == seleccionarFecha.day) {
          horas.add(fecha);
          citasPaciente.add(data['paciente']);
        }
      }
    }

    setState(() {
      tiempoReservado = horas;
      if (citasPaciente.contains(usuarioLogeado)) {
        citaDisponible = false;
      } else {
        if (tiempoReservado.any((hora) =>
            hora.hour == seleccionarFecha.hour &&
            hora.minute == seleccionarFecha.minute)) {
          citaDisponible = false;
        } else {
          citaDisponible = true;
        }
      }
    });
  }

  Future<void> guardaCita() async {
    if (citaDisponible) {
      if (seleccionarFecha.weekday == DateTime.saturday ||
          seleccionarFecha.weekday == DateTime.sunday) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No se pueden programar citas para los fines de semana')),
        );
        return;
      }

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final pacienteNombre = usuarioLogeado;

        final seleccionarDateTime = DateTime(
          seleccionarFecha.year,
          seleccionarFecha.month,
          seleccionarFecha.day,
          int.parse(seleccionarHora.split(':')[0]),
          int.parse(seleccionarHora.split(':')[1]),
        );
        final QuerySnapshot pacienteCitas = await FirebaseFirestore.instance
            .collection('vacunas')
            .where('paciente', isEqualTo: pacienteNombre)
            .get();

        if (pacienteCitas.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El paciente ya tiene una cita programada'),
            ),
          );
          return;
        }

        final QuerySnapshot resultadoDuplicado = await FirebaseFirestore
            .instance
            .collection('vacunas')
            .where('enfermero', isEqualTo: seleccionarEnfermero)
            .where('fecha', isEqualTo: Timestamp.fromDate(seleccionarDateTime))
            .get();

        if (resultadoDuplicado.docs.isEmpty) {
          await FirebaseFirestore.instance.collection('vacunas').add({
            'enfermero': seleccionarEnfermero,
            'paciente': pacienteNombre,
            'fecha': Timestamp.fromDate(seleccionarDateTime),
            'tipo': tipoVacuna,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Cita de vacunación agendada correctamente')),
          );
          buscaCitasReservadas();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Ya existe una cita en esta hora con este enfermero'),
            ),
          );
        }
      }
    }
  }

  List<String> horasDisponibles() {
    List<String> tiempoDisponible = [];
    List<String> horario = [];

    final tiempoAhora = DateTime.now();
    final horaAhora = tiempoAhora.hour;
    final minutoAhora = tiempoAhora.minute;

    if (seleccionarFecha.year == tiempoAhora.year &&
        seleccionarFecha.month == tiempoAhora.month &&
        seleccionarFecha.day == tiempoAhora.day) {
      for (int i = horaAhora; i > 8 && i <= 21; i++) {
        final horas = '$i:00';
        horario.add(horas);
        if (i == horaAhora) {
          for (int j = 20; j <= 40; j += 20) {
            final tiempo = '$i:${j.toString().padLeft(2, '0')}';
            if (minutoAhora < j) {
              horario.add(tiempo);
            }
          }
        } else {
          for (int j = 20; j <= 40; j += 20) {
            final tiempo = '$i:${j.toString().padLeft(2, '0')}';
            horario.add(tiempo);
          }
        }
      }
    } else {
      for (int i = 9; i <= 21; i++) {
        final horas = '$i:00';
        horario.add(horas);
        for (int j = 20; j <= 40; j += 20) {
          final tiempo = '$i:${j.toString().padLeft(2, '0')}';
          horario.add(tiempo);
        }
      }
    }

    if (seleccionarFecha.year == tiempoAhora.year &&
        seleccionarFecha.month == tiempoAhora.month &&
        seleccionarFecha.day == tiempoAhora.day) {
      horario.removeWhere((tiempo) {
        final hora = int.parse(tiempo.split(':')[0]);
        return hora < horaAhora ||
            (hora == horaAhora &&
                int.parse(tiempo.split(':')[1]) <= minutoAhora);
      });
    }

    tiempoDisponible = horario
        .where((time) => !tiempoReservado.any((horarioReservado) =>
            horarioReservado.hour == int.parse(time.split(':')[0]) &&
            horarioReservado.minute == int.parse(time.split(':')[1])))
        .toList();

    return tiempoDisponible;
  }

  Future<void> borrarCitasExpiradas() async {
    final QuerySnapshot resultado = await FirebaseFirestore.instance
        .collection('vacunas')
        .where('fecha', isLessThan: Timestamp.now())
        .get();

    for (DocumentSnapshot doc in resultado.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> cancelaCita(DocumentReference citaReservada) async {
    await citaReservada.delete();

    setState(() {
      tiempoReservado.removeWhere((tiempo) => tiempo == citaReservada);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cita cancelada correctamente')),
    );
  }

  Future<List<DocumentSnapshot>> citasPacientes() async {
    List<DocumentSnapshot> citas = [];

    if (usuarioLogeado != null) {
      final QuerySnapshot resultado = await FirebaseFirestore.instance
          .collection('vacunas')
          .where('paciente', isEqualTo: usuarioLogeado)
          .get();

      citas = resultado.docs;
    }

    return citas;
  }

  @override
  Widget build(BuildContext context) {
    List<String> tiempoDisponible = horasDisponibles();
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
          child: Text('CITA DE \nVACUNACIÓN', textAlign: TextAlign.center),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 128, 235, 165),
      body: SingleChildScrollView(
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
                  const Text(
                    'Seleccionar Enfermero:',
                    style: TextStyle(fontSize: 16),
                  ),
                  DropdownButton<String>(
                    value: seleccionarEnfermero,
                    hint: const Text("Selecciona una enfermera"),
                    onChanged: (valor) {
                      setState(() {
                        seleccionarEnfermero = valor!;
                      });
                      buscaCitasReservadas();
                    },
                    items: enfermeros
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            value,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(height: 1.2),
                          ),
                        ),
                      );
                    }).toList(),
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 30),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Seleccionar Tipo de Vacuna:',
                    style: TextStyle(fontSize: 16),
                  ),
                  DropdownButton<String>(
                    value: tipoVacuna,
                    onChanged: (valor) {
                      setState(() {
                        tipoVacuna = valor!;
                      });
                    },
                    items:
                        vacunas.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Seleccionar Fecha de Vacunación:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: fechaController,
                          readOnly: true,
                          onTap: () => seleccionaDia(context),
                          decoration: const InputDecoration(
                            labelText: 'Fecha',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => seleccionaDia(context),
                        icon: const Icon(Icons.calendar_today),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Seleccionar Hora de Vacunación:',
                    style: TextStyle(fontSize: 16),
                  ),
                  DropdownButton<String>(
                    value: tiempoDisponible.contains(seleccionarHora)
                        ? seleccionarHora
                        : null,
                    onChanged: (valor) {
                      setState(() {
                        seleccionarHora = valor!;
                      });
                    },
                    items: tiempoDisponible
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: citaDisponible ? guardaCita : null,
                      child: const Text('Agendar Vacunación'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'MI CITA DE VACUNACIÓN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  FutureBuilder<List<DocumentSnapshot>>(
                    future: citasPacientes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Center(
                            child: Text('Error al cargar citas'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('No tienes citas programadas'));
                      } else {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final cita = snapshot.data![index];
                            final dynamic data = cita.data();
                            if (data == null) {
                              return const SizedBox.shrink();
                            }
                            final Timestamp fechaTimestamp = data['fecha'];
                            final DateTime fecha = fechaTimestamp.toDate();
                            final String enfermero = data['enfermero'];
                            final String tipoVacuna = data['tipo'];

                            return Card(
                              child: ListTile(
                                title: Text('ENFERMERO: $enfermero '),
                                subtitle: Text(
                                    'FECHA: ${fecha.toString().substring(0, 16)} \nTIPO: $tipoVacuna'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.cancel),
                                  color: Colors.red,
                                  onPressed: () {
                                    cancelaCita(cita.reference);
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
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
