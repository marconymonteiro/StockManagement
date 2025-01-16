import 'package:flutter/material.dart';

class SaidaEquipamento extends StatefulWidget {
  @override
  _SaidaScreenState createState() => _SaidaScreenState();
}

class _SaidaScreenState extends State<SaidaEquipamento> {
  final _numeroSerieController = TextEditingController();

  void _removerEquipamento() {
    final numeroSerie = _numeroSerieController.text;

    if (numeroSerie.isNotEmpty) {
      // Lógica para buscar e remover do Firebase
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Equipamento removido com sucesso!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, insira o número de série.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Saída de Equipamento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _numeroSerieController,
              decoration: InputDecoration(labelText: 'Número de Série'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _removerEquipamento,
              child: Text('Remover Equipamento'),
            ),
          ],
        ),
      ),
    );
  }
}
