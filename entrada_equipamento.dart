import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EntradaEquipamento extends StatefulWidget {
  @override
  _EntradaEquipamentoState createState() => _EntradaEquipamentoState();
}

class _EntradaEquipamentoState extends State<EntradaEquipamento> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _numeroSerieController = TextEditingController();
  List<File> _imagens = [];

  final ImagePicker _picker = ImagePicker();

  Future<void> _selecionarImagem(ImageSource source) async {
    final XFile? imagemSelecionada = await _picker.pickImage(source: source);

    if (imagemSelecionada != null) {
      setState(() {
        _imagens.add(File(imagemSelecionada.path));
      });
    }
  }

  Future<void> _adicionarEquipamento(BuildContext context) async {
    String nome = _nomeController.text.trim();
    String numeroSerie = _numeroSerieController.text.trim();

    if (nome.isNotEmpty && numeroSerie.isNotEmpty && _imagens.isNotEmpty) {
      try {
        // Verifica se o número de série já existe
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

          // Faz upload de cada imagem para o Firebase Storage
          for (var imagem in _imagens) {
            String fileName =
                '${numeroSerie}_${DateTime.now().millisecondsSinceEpoch}_${_imagens.indexOf(imagem)}.jpg';
            Reference storageRef =
                FirebaseStorage.instance.ref().child('equipamentos/$fileName');

            UploadTask uploadTask = storageRef.putFile(imagem);
            TaskSnapshot taskSnapshot = await uploadTask;

            // Obtém a URL da imagem
            String imageUrl = await taskSnapshot.ref.getDownloadURL();
            urlsImagens.add(imageUrl);
          }

          // Adiciona o equipamento ao Firestore
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Entrada de Equipamento')),
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
            _imagens.isNotEmpty
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _imagens
                        .map((imagem) => Image.file(imagem, height: 100, width: 100))
                        .toList(),
                  )
                : Text('Nenhuma imagem selecionada'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _selecionarImagem(ImageSource.gallery),
                  child: Text('Galeria'),
                ),
                ElevatedButton(
                  onPressed: () => _selecionarImagem(ImageSource.camera),
                  child: Text('Câmera'),
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
    );
  }
}
