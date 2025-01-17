import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SaidaEquipamento extends StatefulWidget {
  @override
  _SaidaScreenState createState() => _SaidaScreenState();
}

class _SaidaScreenState extends State<SaidaEquipamento> {
  final _numeroSerieController = TextEditingController();

  Future<void> _removerEquipamento() async {
    final numeroSerie = _numeroSerieController.text.trim();

    if (numeroSerie.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('equipamentos')
            .where('numeroSerie', isEqualTo: numeroSerie)
            .get();

        if (snapshot.docs.isNotEmpty) {
          // Obter o documento do equipamento
          var equipamentoDoc = snapshot.docs.first;
          List<String> urlsImagens =
              List<String>.from(equipamentoDoc['imagensUrl']);

          // Excluir as imagens do Firebase Storage
          for (var imageUrl in urlsImagens) {
            try {
              // Extrair o caminho correto da URL
              final path = _getStoragePath(imageUrl);
              Reference storageRef = FirebaseStorage.instance.ref(path);
              await storageRef.delete();
            } catch (error) {
              print('Erro ao excluir imagem: $error');
            }
          }

          // Remove o equipamento do Firestore
          await FirebaseFirestore.instance
              .collection('equipamentos')
              .doc(equipamentoDoc.id)
              .delete();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Equipamento removido com sucesso!')),
          );
          _numeroSerieController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Equipamento não encontrado no estoque.')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover equipamento: $error')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, insira o número de série.')),
      );
    }
  }

  /// Função para extrair o caminho do arquivo no Storage
  String _getStoragePath(String url) {
    try {
      final uri = Uri.parse(url);

      // Verifica se a URL tem o formato esperado
      if (uri.pathSegments.contains('o')) {
        return uri.pathSegments
            .skipWhile((segment) => segment != 'o')
            .skip(1)
            .join('/')
            .replaceAll('%2F', '/');
      } else {
        throw FormatException('Formato de URL inválido: $url');
      }
    } catch (e) {
      throw Exception('Erro ao processar o caminho da URL: $e');
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
              decoration: InputDecoration(
                labelText: 'Número de Série',
                border: OutlineInputBorder(),
              ),
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
