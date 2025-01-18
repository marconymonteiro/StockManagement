import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ConsultaEquipamento extends StatefulWidget {
  @override
  _ConsultaEquipamentoState createState() => _ConsultaEquipamentoState();
}

class _ConsultaEquipamentoState extends State<ConsultaEquipamento> {
  String searchQuery = '';

  Future<void> _removerEquipamento(String equipamentoId, List<String> imagensUrl) async {
    try {
      for (var imageUrl in imagensUrl) {
        final path = _getStoragePath(imageUrl);
        await FirebaseStorage.instance.ref(path).delete();
      }

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
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.broken_image, size: 50),
                              )
                            : Icon(Icons.image, size: 70),
                        title: Text(nome),
                        subtitle: Text('Número de Série: $numeroSerie\nData: $dataFormatada'),
                        trailing: IconButton(
                          icon: Image.asset('ios/Assets/stock_out.png', width: 65, height: 65),
                          onPressed: () async {
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Confirmar remoção'),
                                content: Text('Deseja remover o item do estoque?'),
                                actions: [
                                  TextButton(
                                    child: Text('Cancelar'),
                                    onPressed: () => Navigator.of(context).pop(false),
                                  ),
                                  TextButton(
                                    child: Text('Remover', style: (TextStyle(color: Colors.red))),
                                    onPressed: () => Navigator.of(context).pop(true),
                                  ),
                                ],
                              ),
                            );

                            if (confirmar == true) {
                              _removerEquipamento(equipamento.id, imagensUrl);
                            }
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalhesEquipamentoScreen(
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

class DetalhesEquipamentoScreen extends StatefulWidget {
  final String equipamentoId;

  DetalhesEquipamentoScreen({required this.equipamentoId});

  @override
  _DetalhesEquipamentoScreenState createState() =>
      _DetalhesEquipamentoScreenState();
}

class _DetalhesEquipamentoScreenState extends State<DetalhesEquipamentoScreen> {
  late Future<DocumentSnapshot> _equipamentoFuture;

  @override
  void initState() {
    super.initState();
    _equipamentoFuture = FirebaseFirestore.instance
        .collection('equipamentos')
        .doc(widget.equipamentoId)
        .get();
  }

  Future<void> _adicionarImagem(String source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery);

    if (image == null) return;

    final file = File(image.path);
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('equipamentos/${widget.equipamentoId}/$fileName');

    await storageRef.putFile(file);
    final imageUrl = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('equipamentos')
        .doc(widget.equipamentoId)
        .update({
      'imagensUrl': FieldValue.arrayUnion([imageUrl]),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imagem adicionada com sucesso!')),
    );

    setState(() {
      _equipamentoFuture = FirebaseFirestore.instance
          .collection('equipamentos')
          .doc(widget.equipamentoId)
          .get();
    });
  }

  Future<void> _removerImagem(String imageUrl) async {
    final path = Uri.parse(imageUrl).pathSegments
        .skipWhile((segment) => segment != 'o')
        .skip(1)
        .join('/');

    await FirebaseStorage.instance.ref(path).delete();

    await FirebaseFirestore.instance
        .collection('equipamentos')
        .doc(widget.equipamentoId)
        .update({
      'imagensUrl': FieldValue.arrayRemove([imageUrl]),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imagem excluída com sucesso!')),
    );

    setState(() {
      _equipamentoFuture = FirebaseFirestore.instance
          .collection('equipamentos')
          .doc(widget.equipamentoId)
          .get();
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Detalhes do Equipamento')),
    body: FutureBuilder<DocumentSnapshot>(
      future: _equipamentoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('Equipamento não encontrado.'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final imagensUrl = List<String>.from(data['imagensUrl'] ?? []);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // GridView com tamanho ajustável
              Padding(
                padding: EdgeInsets.all(8.0),
                child: GridView.builder(
                  shrinkWrap: true, // Faz o GridView ocupar apenas o espaço necessário
                  physics: NeverScrollableScrollPhysics(), // Desativa o scroll interno do GridView
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: imagensUrl.length,
                  itemBuilder: (context, index) {
                    final imageUrl = imagensUrl[index];

                    return GestureDetector(
                      onTap: () async {
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Excluir Imagem'),
                            content: Image.network(imageUrl, fit: BoxFit.contain),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text('Excluir', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirmar == true) {
                          await _removerImagem(imageUrl);
                        }
                      },
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.broken_image),
                      ),
                    );
                  },
                ),
              ),
              // Espaço entre o grid e os botões
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _adicionarImagem('galeria'),
                      icon: Icon(Icons.photo_library),
                      label: Text('Galeria'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _adicionarImagem('camera'),
                      icon: Icon(Icons.camera_alt),
                      label: Text('Câmera'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16), // Espaço adicional para evitar o problema do Snackbar
            ],
          ),
        );
      },
    ),
  );
}
}
