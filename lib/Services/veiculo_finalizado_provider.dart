import 'package:checkutil/Services/models/veiculo_finalizado.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VeiculoFinalizadoProvider with ChangeNotifier {
  final List<VeiculoFinalizado> _veiculos = [];
  bool _isLoading = false;

  List<VeiculoFinalizado> get veiculos => _veiculos;
  bool get isLoading => _isLoading;

  /// Lista todos os veículos finalizados (sem filtro)
  Future<void> carregarVeiculos() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Veiculos_finalizados')
          .orderBy('dataFinalizacao', descending: true)
          .get();

      _veiculos.clear();
      for (var doc in snapshot.docs) {
        final veiculo = VeiculoFinalizado.fromMap(doc.data());
        _veiculos.add(veiculo);
      }
    } catch (e) {
      print('Erro ao carregar veículos finalizados: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Lista veículos finalizados de uma unidade específica
  Future<void> carregarVeiculosPorUnidade(String unidade) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Veiculos_finalizados')
          .where('unidade', isEqualTo: unidade)
          .orderBy('dataFinalizacao', descending: true)
          .get();

      _veiculos.clear();
      for (var doc in snapshot.docs) {
        final veiculo = VeiculoFinalizado.fromMap(doc.data());
        _veiculos.add(veiculo);
      }
    } catch (e) {
      print('Erro ao carregar veículos por unidade: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Lista apenas os veículos finalizados no dia atual para a unidade
  Future<void> carregarVeiculosDoDia(String unidade) async {
    _isLoading = true;
    notifyListeners();

    try {
      final agora = DateTime.now();
      final inicioDoDia = DateTime(agora.year, agora.month, agora.day);
      final fimDoDia = DateTime(agora.year, agora.month, agora.day, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('Veiculos_finalizados')
          .where('unidade', isEqualTo: unidade)
          .where('dataFinalizacao', isGreaterThanOrEqualTo: inicioDoDia)
          .where('dataFinalizacao', isLessThanOrEqualTo: fimDoDia)
          .orderBy('dataFinalizacao', descending: true)
          .get();

      _veiculos.clear();
      for (var doc in snapshot.docs) {
        final veiculo = VeiculoFinalizado.fromMap(doc.data());
        _veiculos.add(veiculo);
      }
    } catch (e) {
      print('Erro ao carregar veículos do dia: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
