import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class EntradaEquipamento extends StatefulWidget {
  @override
  _EntradaEquipamentoState createState() => _EntradaEquipamentoState();
}

class _EntradaEquipamentoState extends State<EntradaEquipamento> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _numeroSerieController = TextEditingController();
  List<File> _imagens = [];
  final ImagePicker _picker = ImagePicker();

  Future<Uint8List> _compressImage(File imagem) async {
    final bytes = await imagem.readAsBytes();
    final image = img.decodeImage(bytes);
    final compressedImage = img.encodeJpg(image!, quality: 50); // Qualidade ajustada para compactação
    return Uint8List.fromList(compressedImage);
  }

  // ignore: unused_element
  Future<void> _selecionarImagem(ImageSource source) async {
    final XFile? imagemSelecionada = await _picker.pickImage(source: source);

    if (imagemSelecionada != null) {
      setState(() {
        _imagens.add(File(imagemSelecionada.path));
      });
    }
  }

  void _visualizarImagem(File imagem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(imagem),
              SizedBox(height: 16),
              Text('Deseja excluir esta imagem?'),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancelar'),
                  ),
                  ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _imagens.remove(imagem);
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Imagem removida com sucesso!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(
                    'Excluir',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _adicionarEquipamento(BuildContext context) async {
    String nome = _nomeController.text.trim();
    String numeroSerie = _numeroSerieController.text.trim();

    if (nome.isNotEmpty && numeroSerie.isNotEmpty && _imagens.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('equipamentos')
            .where('numeroSerie', isEqualTo: numeroSerie)
            .get();

        if (snapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Equipamento já se encontra no pátio.')),
          );
        } else {
          List<String> urlsImagens = [];

          for (var imagem in _imagens) {
            Uint8List compressedBytes = await _compressImage(imagem);

            String fileName =
                '${numeroSerie}_${DateTime.now().millisecondsSinceEpoch}_${_imagens.indexOf(imagem)}.jpg';
            Reference storageRef =
                FirebaseStorage.instance.ref().child('equipamentos/$fileName');

            UploadTask uploadTask =
                storageRef.putData(compressedBytes); // Envia os bytes compactados
            TaskSnapshot taskSnapshot = await uploadTask;

            String imageUrl = await taskSnapshot.ref.getDownloadURL();
            urlsImagens.add(imageUrl);
          }

          await FirebaseFirestore.instance.collection('equipamentos').add({
            'nome': nome,
            'numeroSerie': numeroSerie,
            'data': DateTime.now(),
            'imagensUrl': urlsImagens,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Equipamento adicionado com sucesso!')),
          );
          _nomeController.clear();
          _numeroSerieController.clear();
          setState(() {
            _imagens.clear();
          });
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar equipamento: $error')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, preencha todos os campos e selecione pelo menos uma imagem.')),
      );
    }
  }

 void _selecionarImagemComSnackbar(ImageSource source, BuildContext context) async {
  final XFile? imagemSelecionada = await _picker.pickImage(source: source);

  if (imagemSelecionada != null) {
    setState(() {
      _imagens.add(File(imagemSelecionada.path));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Imagem adicionada com sucesso!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ignore: unused_element
void _removerImagemComSnackbar(File imagem, BuildContext context) {
  setState(() {
    _imagens.remove(imagem);
  });
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Imagem removida com sucesso!'),
      duration: Duration(seconds: 2),
    ),
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Entrada de Equipamento')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            _imagens.isNotEmpty
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _imagens
                        .map((imagem) => GestureDetector(
                              onTap: () => _visualizarImagem(imagem),
                              child: Image.file(
                                imagem,
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ))
                        .toList(),
                  )
                : Text('Nenhuma imagem selecionada'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _selecionarImagemComSnackbar(ImageSource.gallery, context),
                  icon: Icon(Icons.photo_library),
                  label: Text('Galeria'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _selecionarImagemComSnackbar(ImageSource.camera, context),
                  icon: Icon(Icons.camera_alt),
                  label: Text('Câmera'),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _adicionarEquipamento(context),
              child: Text('Adicionar Equipamento'),
            ),
          ],
        ),
      ),
    ),
  );
}
}
