import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Controle de Estoque'),
      ),
      body: Center(
        child: SingleChildScrollView( // Permite rolar se necessário
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/entrada');
                },
                child: Text('Entrada de Equipamento'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/saida');
                },
                child: Text('Saída de Equipamento'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/consulta');
                },
                child: Text('Consulta de Pátio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
