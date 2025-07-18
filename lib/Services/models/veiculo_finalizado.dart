import 'package:cloud_firestore/cloud_firestore.dart';

class VeiculoFinalizado {
  final String assinaturaUrl;
  final DateTime dataFinalizacao;
  final List<Map<String, dynamic>> itens;
  final String placa;
  final String tipoVeiculo;
  final String unidade;
  final String usuarioNome;
  final String usuarioEmail;

  VeiculoFinalizado({
    required this.assinaturaUrl,
    required this.dataFinalizacao,
    required this.itens,
    required this.placa,
    required this.tipoVeiculo,
    required this.unidade,
    required this.usuarioNome,
    required this.usuarioEmail,
  });

  factory VeiculoFinalizado.fromMap(Map<String, dynamic> data) {
    return VeiculoFinalizado(
      assinaturaUrl: data['assinaturaUrl'] ?? '',
      dataFinalizacao: (data['dataFinalizacao'] as Timestamp).toDate(),
      itens: List<Map<String, dynamic>>.from(data['itens'] ?? []),
      placa: data['placa'] ?? '',
      tipoVeiculo: data['tipoVeiculo'] ?? '',
      unidade: data['unidade'] ?? '',
      usuarioNome: data['usuario']?['nome'] ?? '',
      usuarioEmail: data['usuario']?['email'] ?? '',
    );
  }
}
