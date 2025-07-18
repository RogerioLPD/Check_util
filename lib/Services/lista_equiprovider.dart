import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EquipamentoProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _equipamentos = [];

  List<Map<String, dynamic>> get equipamentos => _equipamentos;

  Future<void> listarEquipamentos(String? unidade) async {
    if (unidade == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Equipamentos')
          .where('unidade', isEqualTo: unidade)
          .get();

      _equipamentos.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        _equipamentos.add({
          'tag': data['tag'],
          'tipoEquipamento': data['tipoEquipamento'],
        });
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao listar equipamentos: $e');
    }
  }
}
