import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EntradaEquipamento extends StatelessWidget {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _numeroSerieController = TextEditingController();

  void _adicionarEquipamento() {
    String nome = _nomeController.text;
    String numeroSerie = _numeroSerieController.text;

    if (nome.isNotEmpty && numeroSerie.isNotEmpty) {
      FirebaseFirestore.instance.collection('equipamentos').add({
        'nome': nome,
        'numeroSerie': numeroSerie,
        'data': DateTime.now(),
      }).then((value) {
        print('Equipamento adicionado com sucesso!');
      }).catchError((error) {
        print('Erro ao adicionar equipamento: $error');
      });
    } else {
      print('Nome ou número de série vazio!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Entrada de Equipamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(
                labelText: 'Nome do Equipamento',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _numeroSerieController,
              decoration: InputDecoration(
                labelText: 'Número de Série',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _adicionarEquipamento,
              child: Text('Adicionar Equipamento'),
            ),
          ],
        ),
      ),
    );
  }
}
