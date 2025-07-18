import 'package:flutter/material.dart';

class OcorrenciaEstado with ChangeNotifier {
  String nomeCliente = '';
  DateTime dataInicio = DateTime.now();
  DateTime dataTermino = DateTime.now();
  TimeOfDay horaInicio = TimeOfDay.now();
  TimeOfDay horaTermino = TimeOfDay.now();

  // Métodos para alterar o estado
  void setNomeCliente(String nome) {
    nomeCliente = nome;
    notifyListeners(); // Notifica para atualizar a UI
  }

  void setDataInicio(DateTime data) {
    dataInicio = data;
    notifyListeners();
  }

  void setDataTermino(DateTime data) {
    dataTermino = data;
    notifyListeners();
  }

  void setHoraInicio(TimeOfDay hora) {
    horaInicio = hora;
    notifyListeners();
  }

  void setHoraTermino(TimeOfDay hora) {
    horaTermino = hora;
    notifyListeners();
  }
}
