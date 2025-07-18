import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RelatoriosVeiculosProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _veiculos = [];

  List<Map<String, dynamic>> get veiculos => _veiculos;

  Future<void> listarVeiculos(String? unidade) async {
    if (unidade == null) {
      print('Unidade nula. Abortando listagem de veículos.');
      return;
    }

    print('Buscando veículos para unidade: $unidade');

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Veiculos')
          .where('unidade', isEqualTo: unidade)
          .get();

      print('Documentos encontrados: ${snapshot.docs.length}');

      _veiculos.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('Veículo encontrado: ${data['placa']} - ${data['tipoVeiculo']}');
        _veiculos.add({
          'placa': data['placa'],
          'tipoVeiculo': data['tipoVeiculo'],
        });
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao listar veículos: $e');
    }
  }
}
