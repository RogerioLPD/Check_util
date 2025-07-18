import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VeiculoProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _veiculos = [];

  List<Map<String, dynamic>> get veiculos => _veiculos;

  Future<void> listarVeiculos(String? unidade) async {
    if (unidade == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Veiculos')
          .where('unidade', isEqualTo: unidade)
          .get();

      _veiculos.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        _veiculos.add({
          'imageUrl': data['imageUrl'],
          'marca': data['marca'],
          'modelo': data['modelo'],
          'placa': data['placa'],
          'tipoVeiculo': data['tipoVeiculo'],
          'unidade': data['unidade'],
        });
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao listar veículos: $e');
    }
  }
}
