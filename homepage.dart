import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
              // Logo do cliente - Imagem acima dos botões
              Image.asset(
                'ios/Assets/logo_cliente.png', // Caminho para a logo do cliente
                width: 150, // Ajuste o tamanho conforme necessário
                height: 150,
              ),
              SizedBox(height: 30), // Espaçamento entre a logo e os botões
              
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
              const SizedBox(height: 30), // Espaçamento entre os botões e o texto

              // Exibe o número de equipamentos em estoque
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('equipamentos').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text(
                      'Erro ao carregar dados',
                      style: TextStyle(color: Colors.red),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text(
                      'Equipamentos em Estoque: 0',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    );
                  } else {
                    int totalEquipamentos = snapshot.data!.docs.length;
                    return Text(
                      'Equipamentos em Estoque: $totalEquipamentos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
