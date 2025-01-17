import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultaEquipamento extends StatefulWidget {
  @override
  _ConsultaEquipamentoState createState() => _ConsultaEquipamentoState();
}

class _ConsultaEquipamentoState extends State<ConsultaEquipamento> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Consulta de Equipamento')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Pesquisar por Nome ou Número de Série',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase(); // Ignora maiúsculas/minúsculas
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('equipamentos')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Nenhum equipamento encontrado!'));
                }

                final equipamentos = snapshot.data!.docs.where((equipamento) {
                  final data = equipamento.data() as Map<String, dynamic>;
                  final nome = (data['nome'] ?? '').toString().toLowerCase();
                  final numeroSerie =
                      (data['numeroSerie'] ?? '').toString().toLowerCase();
                  return nome.contains(searchQuery) ||
                      numeroSerie.contains(searchQuery);
                }).toList();

                if (equipamentos.isEmpty) {
                  return Center(child: Text('Nenhum equipamento encontrado!'));
                }

                return ListView.builder(
                  itemCount: equipamentos.length,
                  itemBuilder: (context, index) {
                    final equipamento = equipamentos[index];
                    final data = equipamento.data() as Map<String, dynamic>;

                    final nome = data['nome'] ?? 'Sem Nome';
                    final numeroSerie =
                        data['numeroSerie'] ?? 'Sem Número de Série';
                    final dataRegistro = data.containsKey('data')
                        ? (data['data'] as Timestamp).toDate()
                        : DateTime.now();

                    return ListTile(
                      title: Text(nome),
                      subtitle: Text(
                        'Número de Série: $numeroSerie\nData: ${dataRegistro.toLocal()}',
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VisualizarFotosScreen(
                              equipamentoId: equipamento.id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VisualizarFotosScreen extends StatelessWidget {
  final String equipamentoId;

  VisualizarFotosScreen({required this.equipamentoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fotos do Equipamento')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('equipamentos')
            .doc(equipamentoId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Nenhuma foto encontrada!'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> imagensUrl =
              data['imagensUrl'] ?? []; // Lista de URLs das imagens

          if (imagensUrl.isEmpty) {
            return Center(child: Text('Nenhuma foto encontrada!'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: imagensUrl.length,
            itemBuilder: (context, index) {
              final imageUrl = imagensUrl[index];
              return Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Icon(Icons.error));
                },
              );
            },
          );
        },
      ),
    );
  }
}
