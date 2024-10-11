// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api, unused_local_variable, prefer_const_declarations, dead_code

import 'package:health4u/olvidastecontrasena.dart';
import 'package:health4u/home.dart';
import 'package:health4u/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:health4u/pantallas/citapreviamedico.dart';
import 'package:health4u/pantallas/citapreviapaciente.dart';
import 'package:health4u/pantallas/documentopaciente.dart';
import 'package:health4u/pantallas/pacientesEnfermero.dart';
import 'package:health4u/pantallas/pacientesmedico.dart';
import 'package:health4u/pantallas/perfil.dart';
import 'package:health4u/pantallas/salavirtual.dart';
import 'package:health4u/pantallas/usuarioschat.dart';
import 'package:health4u/pantallas/vacunasenfermero.dart';
import 'package:health4u/pantallas/vacunaspaciente.dart';
import 'package:health4u/registro.dart';
import 'package:health4u/service/auth.dart';
import 'package:health4u/service/firebase.dart';
import 'package:url_strategy/url_strategy.dart';

void main() async {
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "",
          appId: "",
          messagingSenderId: "",
          projectId: "health4u-10ae1",
          storageBucket: "health4u-10ae1.appspot.com"));

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SALUD_APP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => Login(),
        '/registro': (context) => Registro(),
        '/olvidasteContrasena': (context) => OlvidasteContrasena(),
        '/home': (context) {
          return FutureBuilder<String?>(
            future: FirebaseService.obtenerRol(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final String? rol = snapshot.data;
              if (rol != null) {
                return Home(
                  rol: rol,
                );
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushNamed(context, '/login');
                });
                return Container();
              }
            },
          );
        },
        '/vacuna': (context) {
          return FutureBuilder<bool>(
            future: AuthService.logeado(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final estaLogeado = snapshot.data ?? false;
              if (estaLogeado) {
                return VacunaPaciente();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushNamed(context, '/login');
                });
                return Container();
              }
            },
          );
        },
        '/vacunaEnfermero': (context) {
          return FutureBuilder<bool>(
            future: AuthService.logeado(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final estaLogeado = snapshot.data ?? false;
              if (estaLogeado) {
                return VacunaEnfermero();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushNamed(context, '/login');
                });
                return Container();
              }
            },
          );
        },
        '/citaPrevia': (context) {
          return FutureBuilder<bool>(
            future: AuthService.logeado(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final estaLogeado = snapshot.data ?? false;
              if (estaLogeado) {
                return CitaPreviaPaciente();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushNamed(context, '/login');
                });
                return Container();
              }
            },
          );
        },
        '/citaPreviaMedico': (context) {
          return FutureBuilder<bool>(
            future: AuthService.logeado(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final estaLogeado = snapshot.data ?? false;
              if (estaLogeado) {
                return CitaPreviaMedico();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushNamed(context, '/login');
                });
                return Container();
              }
            },
          );
        },
        '/documento': (context) {
          return FutureBuilder<bool>(
            future: AuthService.logeado(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final estaLogeado = snapshot.data ?? false;
              if (estaLogeado) {
                return DocumentoPaciente();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushNamed(context, '/login');
                });
                return Container();
              }
            },
          );
        },
        '/perfil': (context) {
          return FutureBuilder<bool>(
            future: AuthService.logeado(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final estaLogeado = snapshot.data ?? false;
              if (estaLogeado) {
                return Perfil();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushNamed(context, '/login');
                });
                return Container();
              }
            },
          );
        },
        '/salaVirtual': (context) {
          final Map<String, String>? arguments = ModalRoute.of(context)
              ?.settings
              .arguments as Map<String, String>?;
          final String idSala = arguments?['idSala'] ?? '';

          return FutureBuilder<bool>(
            future: AuthService.logeado(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final estaLogeado = snapshot.data ?? false;

              if (estaLogeado) {
                return SalaVirtual();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushNamed(context, '/login');
                });
                return Container();
              }
            },
          );
        },
        '/pacientesMedico': (context) {
          return FutureBuilder<bool>(
            future: AuthService.logeado(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final estaLogeado = snapshot.data ?? false;
              if (estaLogeado) {
                return PacientesMedico();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushNamed(context, '/login');
                });
                return Container();
              }
            },
          );
        },
        '/pacientesEnfermero': (context) {
          return FutureBuilder<bool>(
            future: AuthService.logeado(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final estaLogeado = snapshot.data ?? false;
              if (estaLogeado) {
                return PacientesEnfermero();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushNamed(context, '/login');
                });
                return Container();
              }
            },
          );
        },
        '/chat': (context) {
          return FutureBuilder<bool>(
            future: AuthService.logeado(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final estaLogeado = snapshot.data ?? false;
              if (estaLogeado) {
                return ChatUsuarios();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushNamed(context, '/login');
                });
                return Container();
              }
            },
          );
        },
        '/chatMedico': (context) {
          return FutureBuilder<bool>(
            future: AuthService.logeado(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final estaLogeado = snapshot.data ?? false;
              if (estaLogeado) {
                return ChatUsuarios();
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushNamed(context, '/login');
                });
                return Container();
              }
            },
          );
        },
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) {
            return FutureBuilder<bool>(
              future: AuthService.logeado(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                final estaLogeado = snapshot.data ?? false;
                if (estaLogeado) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushNamed(context, '/home');
                  });
                } else {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushNamed(context, '/login');
                  });
                }
                return Container();
              },
            );
          },
        );
      },
    );
  }
}
