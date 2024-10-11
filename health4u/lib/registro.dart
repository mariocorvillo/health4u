// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => RegistroState();
}

class RegistroState extends State<Registro> {
  String email = "",
      password = "",
      nombre = "",
      dni = "",
      numtarsan = "",
      gruposang = "",
      genero = "",
      fechanacimiento = "",
      rol = "";

  final GlobalKey<FormState> clave = GlobalKey<FormState>();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController generoController = TextEditingController();
  final TextEditingController dniController = TextEditingController();
  final TextEditingController numtarsanController = TextEditingController();
  final TextEditingController gruposangController = TextEditingController();
  TextEditingController fechaNacimientoController = TextEditingController();
  late DateTime fechaSeleccionada;
  final TextEditingController rolController = TextEditingController();

  List<String> listaGrupoSanguineo = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    '0+',
    '0-',
    'Desconocido'
  ];

  List<String> listaGenero = ['Hombre', 'Mujer', 'Otro'];

  List<String> listaRoles = ['Paciente', 'Medico', 'Enfermero'];

  Future<bool> verificarDniExistente(String dni) async {
    var snapshot = await firestore
        .collection('usuarios')
        .where('dni/nie', isEqualTo: dni)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  bool validarLetraDNI(String dni) {
    const String letrasValidas = 'TRWAGMYFPDXBNJZSQVHLCKE';
    int numeroDNI = int.parse(dni.substring(0, 8));
    String letra = dni.substring(8).toUpperCase();
    int resto = numeroDNI % 23;
    String letraCalculada = letrasValidas[resto];
    return letra == letraCalculada;
  }

  Future<bool> verificarNieExistente(String nie) async {
    var snapshot = await firestore
        .collection('usuarios')
        .where('dni/nie', isEqualTo: nie)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  bool validarLetraNIE(String nie) {
    const String letrasValidas = 'TRWAGMYFPDXBNJZSQVHLCKE';
    String letra = nie.substring(nie.length - 1).toUpperCase();
    String numeroStr = nie.substring(1, nie.length - 1);
    int numeroNIE;

    if (nie.startsWith('X')) {
      numeroNIE = int.parse('0$numeroStr');
    } else if (nie.startsWith('Y')) {
      numeroNIE = int.parse('1$numeroStr');
    } else if (nie.startsWith('Z')) {
      numeroNIE = int.parse('2$numeroStr');
    } else {
      return false;
    }

    int resto = numeroNIE % 23;
    String letraCalculada = letrasValidas[resto];
    return letra == letraCalculada;
  }

  bool esNie(String documento) {
    return documento.startsWith('X') ||
        documento.startsWith('Y') ||
        documento.startsWith('Z');
  }

  Future<void> registro() async {
    try {
      String documento = dniController.text;

      bool esNIE = esNie(documento);

      bool documentoExistente;
      bool letraValida;

      if (esNIE) {
        documentoExistente = await verificarNieExistente(documento);
        letraValida = validarLetraNIE(documento);
      } else {
        documentoExistente = await verificarDniExistente(documento);
        letraValida = validarLetraDNI(documento);
      }

      if (documentoExistente) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('${esNIE ? "NIE" : "DNI"} YA REGISTRADO'),
              content: Text(
                  'El ${esNIE ? "NIE" : "DNI"} ya está asociado a otra cuenta.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        return;
      }

      if (!letraValida) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('${esNIE ? "NIE" : "DNI"} INVÁLIDO'),
              content:
                  Text('La letra del ${esNIE ? "NIE" : "DNI"} no es válida.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        return;
      }

      String hashedPassword =
          sha256.convert(utf8.encode(passwordController.text)).toString();
      UserCredential credenciales = await auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      await firestore.collection('usuarios').doc(credenciales.user!.uid).set({
        'nombre': nombreController.text,
        'email': emailController.text,
        'genero': generoController.text,
        'dni': dniController.text,
        'tarjetaSanitaria': numtarsanController.text,
        'grupoSanguineo': gruposangController.text,
        'fechaNacimiento': fechaNacimientoController.text,
        'password': hashedPassword,
        'rol': rolController.text,
        'id': credenciales.user!.uid
      });

      nombreController.clear();
      emailController.clear();
      passwordController.clear();
      generoController.clear();
      dniController.clear();
      numtarsanController.clear();
      gruposangController.clear();
      fechaNacimientoController.clear();
      rolController.clear;

      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('REGISTRO EXISTOSO'),
              content: const Text('¡Se ha registrado correctamente!'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pushNamed(context, 'login');
                  },
                ),
              ],
            );
          });
    } catch (error) {
      if (error is FirebaseAuthException &&
          error.code == 'email-already-in-use') {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('CORREO INCORRECTO'),
                content: const Text('El correo electrónico ya está en uso'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            });
      } else {
        // ignore: avoid_print
        print('Error al registrar usuario: $error');
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
              Navigator.pushNamed(context, '/login');
            },
          ),
          backgroundColor: Colors.green,
          title: const Center(child: Text('REGISTRO DE USUARIO')),
        ),
        backgroundColor: const Color.fromARGB(255, 128, 235, 165),
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(30),
                child: SingleChildScrollView(
                  child: Form(
                    key: clave,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              validator: (valor) {
                                if (valor == null || valor.isEmpty) {
                                  return 'Introduzca un nombre';
                                }
                                return null;
                              },
                              controller: nombreController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                  labelStyle: TextStyle(color: Colors.black),
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.green))),
                            ),
                            TextFormField(
                              validator: (valor) {
                                String patron =
                                    (r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
                                RegExp expReg = RegExp(patron);
                                if (valor == null || valor.isEmpty) {
                                  return 'Introduzca un correo';
                                } else if (!expReg.hasMatch(valor)) {
                                  return 'Correo incorrecto. El correo debe contener el nombre junto a @dominio.com';
                                }
                                return null;
                              },
                              controller: emailController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                  labelText: 'Correo electrónico',
                                  labelStyle: TextStyle(color: Colors.black),
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.green))),
                            ),
                            TextFormField(
                              validator: (valor) {
                                String patron = r'^.{6,}$';
                                RegExp expReg = RegExp(patron);
                                if (valor == null || valor.isEmpty) {
                                  return 'Introduzca una contraseña';
                                } else if (!expReg.hasMatch(valor)) {
                                  return 'La contraseña debe contener 6 caracteres';
                                }
                                return null;
                              },
                              controller: passwordController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                labelText: 'Contraseña',
                                labelStyle: TextStyle(color: Colors.black),
                                focusedBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.green)),
                              ),
                              obscureText: true,
                            ),
                            TextFormField(
                              validator: (valor) {
                                RegExp expReg = RegExp(
                                    r'^(?:\d{8}[A-Z])|(?:[XYZ]\d{7}[A-Z])$',
                                    caseSensitive: false);
                                if (valor == null || valor.isEmpty) {
                                  return 'Introduzca un DNI/NIE';
                                } else if (!expReg.hasMatch(valor)) {
                                  return 'DNI/NIE incorrecto. El DNI debe contener el 8 números y una letra. El NIE debe contener una letra (X,Y,Z), 7 números y otra letra';
                                }
                                return null;
                              },
                              controller: dniController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                  labelText: 'DNI/NIE',
                                  labelStyle: TextStyle(color: Colors.black),
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.green))),
                            ),
                            TextFormField(
                              validator: (valor) {
                                String patron = (r'^AN\d{10}$');
                                RegExp expReg = RegExp(patron);
                                if (valor == null || valor.isEmpty) {
                                  return 'Introduzca un número de tarjeta sanitaria';
                                } else if (!expReg.hasMatch(valor)) {
                                  return 'Número de tarjeta sanitaria incorrecto. Debe contener AN y 10 dígitos';
                                }
                                return null;
                              },
                              controller: numtarsanController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                  labelText: 'Número de tarjeta sanitaria',
                                  labelStyle: TextStyle(color: Colors.black),
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.green))),
                            ),
                            TextFormField(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text(
                                          "Seleccione un grupo sanguíneo"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          for (var opcion
                                              in listaGrupoSanguineo)
                                            ListTile(
                                              title: Text(opcion),
                                              onTap: () {
                                                setState(() {
                                                  gruposangController.text =
                                                      opcion;
                                                });
                                                Navigator.pop(context);
                                              },
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              readOnly: true,
                              controller: gruposangController,
                              validator: (valor) {
                                if (valor == null || valor.isEmpty) {
                                  return 'Introduzca un grupo sanguíneo';
                                }
                                return null;
                              },
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                labelText: 'Grupo sanguíneo',
                                labelStyle: TextStyle(color: Colors.black),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.green),
                                ),
                              ),
                            ),
                            TextFormField(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("Seleccione un género"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          for (var opcion in listaGenero)
                                            ListTile(
                                              title: Text(opcion),
                                              onTap: () {
                                                setState(() {
                                                  generoController.text =
                                                      opcion;
                                                });
                                                Navigator.pop(context);
                                              },
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              readOnly: true,
                              controller: generoController,
                              validator: (valor) {
                                if (valor == null || valor.isEmpty) {
                                  return 'Introduzca un género';
                                }
                                return null;
                              },
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                labelText: 'Género',
                                labelStyle: TextStyle(color: Colors.black),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.green),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate:
                                      DateTime(DateTime.now().year - 100),
                                  lastDate: DateTime(DateTime.now().year + 1),
                                  selectableDayPredicate: (DateTime day) {
                                    return !day.isAfter(DateTime.now());
                                  },
                                ).then((valor) {
                                  if (valor != null) {
                                    fechaNacimientoController.text =
                                        '${valor.day.toString()}/${valor.month.toString()}/${valor.year.toString()}';
                                  }
                                });
                              },
                              child: TextFormField(
                                validator: (valor) {
                                  if (valor == null || valor.isEmpty) {
                                    return 'Introduzca una fecha de nacimiento';
                                  }
                                  return null;
                                },
                                controller: fechaNacimientoController,
                                style: const TextStyle(color: Colors.black),
                                enabled: false,
                                decoration: const InputDecoration(
                                    labelText: 'Fecha de nacimiento',
                                    labelStyle: TextStyle(color: Colors.black),
                                    focusedBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.green))),
                              ),
                            ),
                            TextFormField(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("Seleccione un rol"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          for (var opcion in listaRoles)
                                            ListTile(
                                              title: Text(opcion),
                                              onTap: () {
                                                setState(() {
                                                  rolController.text = opcion;
                                                });
                                                Navigator.pop(context);
                                              },
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              readOnly: true,
                              controller: rolController,
                              validator: (valor) {
                                if (valor == null || valor.isEmpty) {
                                  return 'Introduzca un rol';
                                }
                                return null;
                              },
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                labelText: 'Rol',
                                labelStyle: TextStyle(color: Colors.black),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.green),
                                ),
                              ),
                            ),
                            const SizedBox(height: 100),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (clave.currentState!.validate()) {
                                        setState(() {
                                          email = emailController.text;
                                          password = passwordController.text;
                                          nombre = nombreController.text;
                                          dni = dniController.text;
                                          numtarsan = numtarsanController.text;
                                          gruposang = gruposangController.text;
                                          genero = generoController.text;
                                          fechanacimiento =
                                              fechaNacimientoController.text;
                                          rol = rolController.text;
                                        });
                                        registro();
                                      }
                                    },
                                    child: Container(
                                      constraints:
                                          const BoxConstraints(maxWidth: 200),
                                      margin: const EdgeInsets.only(bottom: 20),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 42, 124, 53),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "REGÍSTRATE",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
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
                ))));
  }
}
