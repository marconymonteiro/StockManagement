import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ConsultaEquipamento extends StatefulWidget {
  @override
  _ConsultaEquipamentoState createState() => _ConsultaEquipamentoState();
}

class _ConsultaEquipamentoState extends State<ConsultaEquipamento> {
  String searchQuery = '';

  Future<void> _removerEquipamento(String equipamentoId, List<String> imagensUrl) async {
    try {
      // Excluir imagens do Firebase Storage
      for (var imageUrl in imagensUrl) {
        final path = _getStoragePath(imageUrl);
        await FirebaseStorage.instance.ref(path).delete();
      }

      // Remover equipamento do Firestore
      await FirebaseFirestore.instance.collection('equipamentos').doc(equipamentoId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Equipamento removido com sucesso!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover equipamento: $error')),
      );
    }
  }

  String _getStoragePath(String url) {
    final uri = Uri.parse(url);
    return uri.pathSegments.skipWhile((segment) => segment != 'o').skip(1).join('/').replaceAll('%2F', '/');
  }

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
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('equipamentos').snapshots(),
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
                  final numeroSerie = (data['numeroSerie'] ?? '').toString().toLowerCase();
                  return nome.contains(searchQuery) || numeroSerie.contains(searchQuery);
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
                    final numeroSerie = data['numeroSerie'] ?? 'Sem Número de Série';
                    final imagensUrl = List<String>.from(data['imagensUrl'] ?? []);
                    final miniaturaUrl = imagensUrl.isNotEmpty ? imagensUrl[0] : null;
                    final dataRegistro = data.containsKey('data')
                        ? (data['data'] as Timestamp).toDate()
                        : DateTime.now();

                    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(dataRegistro);

                    return Card(
                    child: ListTile(
                      leading: miniaturaUrl != null && miniaturaUrl.isNotEmpty
                          ? Image.network(
                              miniaturaUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.broken_image, size: 50),
                            )
                          : Icon(Icons.image, size: 50),
                      title: Text(nome),
                      subtitle: Text('Número de Série: $numeroSerie\nData: $dataFormatada'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removerEquipamento(equipamento.id, imagensUrl),
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
                    ),
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
        future: FirebaseFirestore.instance.collection('equipamentos').doc(equipamentoId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Nenhuma foto encontrada!'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> imagensUrl = data['imagensUrl'] ?? [];

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
