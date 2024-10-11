// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => LoginState();
}

class LoginState extends State<Login> {
  String email = "", password = "";
  bool logeado = false;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final GlobalKey<FormState> clave = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void muestraError(String mensajeError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensajeError),
        backgroundColor: Colors.red,
      ),
    );
  }

  void usuarioLogin() async {
    try {
      UserCredential credenciales =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      User? usuarioLogeado = FirebaseAuth.instance.currentUser;

      if (usuarioLogeado != null) {
        await firestore.collection('usuarios').doc(usuarioLogeado.uid).update({
          'password':
              sha256.convert(utf8.encode(passwordController.text)).toString(),
        });
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      DocumentSnapshot snapshotUsuarios = await firestore
          .collection('usuarios')
          .doc(credenciales.user!.uid)
          .get();

      if (snapshotUsuarios.exists) {
        Map<String, dynamic>? data =
            snapshotUsuarios.data() as Map<String, dynamic>?;

        if (data != null &&
            data.containsKey('password') &&
            data['password'] != null) {
          String contrasena = data['password'];
          String contrasenaCifrada =
              sha256.convert(utf8.encode(passwordController.text)).toString();
          if (contrasenaCifrada == contrasena) {
            prefs.setString('userId', credenciales.user!.uid);
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            muestraError('La contraseña es incorrecta.');
          }
        } else {
          muestraError('No se encontró la contraseña para este usuario.');
        }
      } else {
        muestraError('No se encontró ningún usuario con este correo.');
      }
    } catch (error) {
      if (error is FirebaseAuthException) {
        if (error.code == 'user-not-found') {
          muestraError('No se encontró ningún usuario con este correo.');
        } else if (error.code == 'wrong-password') {
          muestraError('La contraseña es incorrecta.');
        } else {
          muestraError(
              'Ocurrió un error durante el inicio de sesión. Por favor, inténtalo de nuevo.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final altura = MediaQuery.of(context).size.height;
    final anchura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Text(
                  'HEALTH4U',
                  style: TextStyle(
                      fontSize: altura * 0.08,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Form(
                  key: clave,
                  child: Column(
                    children: [
                      Container(
                        height: altura * 0.25,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        child:
                            Image.asset('img/Logo.jpeg', fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        color: const Color.fromARGB(255, 128, 235, 165),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                        elevation: 5,
                        child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'LOGIN',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: altura * 0.04,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2.0, horizontal: 30.0),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFedf0f8),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: TextFormField(
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
                                      decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "Correo",
                                          hintStyle: TextStyle(
                                              color: const Color(0xFFb2b7bf),
                                              fontSize: altura * 0.02)),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2.0, horizontal: 30.0),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFedf0f8),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: TextFormField(
                                      controller: passwordController,
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
                                      decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "Contraseña",
                                          hintStyle: TextStyle(
                                              color: const Color(0xFFb2b7bf),
                                              fontSize: altura * 0.02)),
                                      obscureText: true,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (clave.currentState!.validate()) {
                                        setState(() {
                                          email = emailController.text;
                                          password = passwordController.text;
                                        });
                                        usuarioLogin();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 42, 124, 53),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      minimumSize: Size(anchura * 0.5, 40),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Text(
                                        "INICIAR SESIÓN",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: altura * 0.02,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ])),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/olvidasteContrasena');
                        },
                        child: Text(
                          "¿Olvidaste contraseña?",
                          style: TextStyle(
                              color: const Color.fromARGB(255, 42, 124, 53),
                              fontSize: altura * 0.02,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("¿No tienes una cuenta?",
                              style: TextStyle(
                                  color: const Color(0xFF8c8e98),
                                  fontSize: altura * 0.02,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/registro');
                            },
                            child: Text(
                              "Regístrate",
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 42, 124, 53),
                                  fontSize: altura * 0.02,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
