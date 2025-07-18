import 'package:flutter/material.dart';

class LocalProvider with ChangeNotifier {
  String _localSelecionado = '';

  String get localSelecionado => _localSelecionado;

  void setLocalSelecionado(String local) {
    _localSelecionado = local;
    notifyListeners();
  }
}
