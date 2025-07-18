import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ItensNaoConformesVeiculos extends ChangeNotifier {
  List<Map<String, dynamic>> _itensNaoConformes = [];
  String? _unidadeSelecionada;

  List<Map<String, dynamic>> get itensNaoConformes => _itensNaoConformes;

  void setUnidadeSelecionada(String unidade) {
    _unidadeSelecionada = unidade;
    fetchItensNaoConformes();
  }

  Future<void> fetchItensNaoConformes() async {
    if (_unidadeSelecionada == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('Veiculos_finalizados')
        .where('unidade', isEqualTo: _unidadeSelecionada) // ou use "unidade" se for o campo correto
        .get();

    List<Map<String, dynamic>> listaNaoConformes = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final itens = List<Map<String, dynamic>>.from(data['itens'] ?? []);

      for (var item in itens) {
        if (item['status'] == 'Não Conforme') {
          listaNaoConformes.add({
            'item': item['item'],
            'comentario': item['comentario'],
            'imagem': item['imagem'],
            'usuario': data['usuario'],
            'dataFinalizacao': data['dataFinalizacao'],
            'placa': data['placa'], // ou 'unidade'
          });
        }
      }
    }

    _itensNaoConformes = listaNaoConformes;
    notifyListeners();
  }
}
