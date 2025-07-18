import 'package:flutter/material.dart';

class VendaState with ChangeNotifier {
  String nomeCliente = '';
  DateTime dataVenda = DateTime.now();

  // Métodos para alterar o estado
  void setNomeCliente(String nome) {
    nomeCliente = nome;
    notifyListeners(); // Notifica para atualizar a UI
  }

  void setDataVenda(DateTime data) {
    dataVenda = data;
    notifyListeners();
  }
}
