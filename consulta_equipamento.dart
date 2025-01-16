import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultaEquipamento extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Consulta de Equipamento')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('equipamentos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Nenhum equipamento encontrado!'));
          }

          final equipamentos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: equipamentos.length,
            itemBuilder: (context, index) {
              final equipamento = equipamentos[index];
              final data = equipamento.data() as Map<String, dynamic>?;

              final nome = data?['nome'] ?? 'Sem Nome';
              final numeroSerie = data?.containsKey('numeroSerie') == true
                  ? data!['numeroSerie']
                  : 'Sem Número de Série';
              final dataRegistro = data?.containsKey('data') == true
                  ? (data!['data'] as Timestamp).toDate()
                  : DateTime.now();

              return ListTile(
                title: Text(nome),
                subtitle: Text(
                  'Número de Série: $numeroSerie\nData: ${dataRegistro.toLocal()}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
