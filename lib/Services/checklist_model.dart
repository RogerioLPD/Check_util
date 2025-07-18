import 'package:flutter/material.dart';

class ItemChecklist {
  final String item;
  final String status;
  final String comentario;
  final String descricao;
  final String imagem;

  ItemChecklist({
    required this.item,
    required this.status,
    required this.comentario,
    required this.descricao,
    required this.imagem,
  });

  factory ItemChecklist.fromMap(Map<String, dynamic> map) {
    return ItemChecklist(
      item: map['item'] ?? '',
      status: map['status'] ?? '',
      comentario: map['comentario'] ?? '',
      descricao: map['descricao'] ?? '',
      imagem: map['imagem'] ?? '',
    );
  }
}