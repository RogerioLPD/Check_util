import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UnidadeProvider with ChangeNotifier {
  String? _unidadeSelecionada;
  String? _logoBase64;
  int? _ultimoNumeroVenda;
  bool _isLoading = false;

  String? get unidadeSelecionada => _unidadeSelecionada;
  String? get logoBase64 => _logoBase64;
  int? get ultimoNumeroVenda => _ultimoNumeroVenda;
  bool get isLoading => _isLoading;

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> buscarLogoDaUnidade(String unidade) async {
    try {
      if (_user == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('Unidades')
          .doc(_user!.uid)
          .collection('Unidade')
          .where('nome', isEqualTo: unidade)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final unidadeData = querySnapshot.docs.first.data();
        _logoBase64 = unidadeData['logo'];
        if (kDebugMode) {
          print("Logo recuperada: $_logoBase64");
        }
      } else {
        _logoBase64 = null;
        if (kDebugMode) {
          print("Unidade não encontrada.");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao buscar logo da unidade: $e");
      }
      _logoBase64 = null;
    }
    notifyListeners();
  }

  Future<void> buscarUltimoNumeroVenda() async {
    try {
      if (_user == null || _unidadeSelecionada == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('Ocorrencias')
          .doc(_user!.uid)
          .collection('ocorrencia')
          .where('unidade', isEqualTo: _unidadeSelecionada)
          .orderBy('_vendaNumero', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final ultimoNumero = querySnapshot.docs.first['_vendaNumero'];
        if (ultimoNumero is String) {
          _ultimoNumeroVenda = int.tryParse(ultimoNumero) ?? 0;
        } else if (ultimoNumero is int) {
          _ultimoNumeroVenda = ultimoNumero;
        }
      } else {
        _ultimoNumeroVenda = 0;
      }
      if (kDebugMode) {
        print("Último número de venda recuperado: $_ultimoNumeroVenda");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao buscar último número de venda: $e");
      }
      _ultimoNumeroVenda = 0;
    }
    notifyListeners();
  }

  void setUnidadeSelecionada(String? novaUnidade) {
    if (_unidadeSelecionada == novaUnidade) return; // Evita notificações desnecessárias

    _unidadeSelecionada = novaUnidade;
    _logoBase64 = null;
    _ultimoNumeroVenda = null;
    notifyListeners();

    if (novaUnidade != null) {
      _isLoading = true;
      notifyListeners();

      buscarLogoDaUnidade(novaUnidade).then((_) => buscarUltimoNumeroVenda()).whenComplete(() {
        _isLoading = false;
        notifyListeners();
      });
    }
  }
}
