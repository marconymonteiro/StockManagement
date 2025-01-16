import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:warehouse_management/homepage.dart';
import 'package:warehouse_management/entrada_equipamento.dart';
import 'package:warehouse_management/saida_equipamento.dart';
import 'package:warehouse_management/consulta_equipamento.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Estoque',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/entrada': (context) => EntradaEquipamento(),
        '/saida': (context) => SaidaEquipamento(),
        '/consulta': (context) => ConsultaEquipamento(),
      },
    );
  }
}
