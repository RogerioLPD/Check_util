import 'dart:convert';
import 'dart:typed_data';
import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class ListaOcorrenciasScreen extends StatefulWidget {
  const ListaOcorrenciasScreen({super.key});

  @override
  _ListaOcorrenciasScreenState createState() => _ListaOcorrenciasScreenState();
}

class _ListaOcorrenciasScreenState extends State<ListaOcorrenciasScreen> {
  String? _statusSelecionado;

  @override
  Widget build(BuildContext context) {
    final unidadeSelecionada =
        Provider.of<UnidadeProvider>(context).unidadeSelecionada;

    if (unidadeSelecionada == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Lista de Ocorrências")),
        body: const Center(child: Text("Nenhuma unidade selecionada.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text("Legenda do Status: ", style: subtitleTextStyle),
                    legendaStatus("Realizado", Colors.green),
                    legendaStatus("Analisado", Colors.yellow),
                    legendaStatus("Pendente", Colors.red),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.filter_list,
                        color: textSecondary), // Ícone de filtro
                    const SizedBox(
                        width: 8), // Espaço entre o ícone e o dropdown
                    DropdownButton<String>(
                      style: bodyTextStyle, // Estilo aplicado ao texto
                      value: _statusSelecionado,
                      hint: Text(
                        "Filtrar",
                        style: bodyTextStyle,
                        textAlign: TextAlign
                            .left, // Opcional, ajusta o alinhamento do texto
                      ),
                      icon: SizedBox.shrink(), // Remove o ícone padrão
                      underline: SizedBox.shrink(), // Remove a linha subjacente
                      items: ["Todos", "Realizado", "Analisado", "Pendente"]
                          .map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Center(
                            child: Text(
                              status,
                              style: bodyTextStyle,
                            ),
                          ), // Garante centralização no item
                        );
                      }).toList(),
                      selectedItemBuilder: (BuildContext context) {
                        return ["Todos", "Realizado", "Analisado", "Pendente"]
                            .map((status) {
                          return Align(
                            alignment: Alignment
                                .centerLeft, // Alinha o texto à esquerda
                            child: Text(
                              status,
                              style: bodyTextStyle,
                            ),
                          );
                        }).toList();
                      },
                      onChanged: (value) {
                        setState(() {
                          _statusSelecionado = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 56,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
          child: Container(
            margin: EdgeInsets.zero, // Garantindo que não há margem extra
            padding: EdgeInsets.zero,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: Color.fromARGB(255, 216, 216, 216),
                    width: 1.0), // Borda no topo
                right: BorderSide(
                    color: Color.fromARGB(255, 216, 216, 216),
                    width: 1.0), // Borda na direita
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(45, 20, 40, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text("Lista de Ocorrências", style: headTextStyle),
                  const SizedBox(height: 40),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Ocorrencias')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('ocorrencia')
                          .where('unidade', isEqualTo: unidadeSelecionada)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text("Nenhuma ocorrência encontrada."));
                        }

                        final List<Map<String, dynamic>> ocorrencias =
                            snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          data['_vendaNumero'] =
                              (data['_vendaNumero'] is String)
                                  ? int.tryParse(data['_vendaNumero']) ?? 0
                                  : data['_vendaNumero'];
                          return data;
                        }).where((ocorrencia) {
                          // Se "Todos" for selecionado, mostrar todos os itens
                          if (_statusSelecionado == null ||
                              _statusSelecionado == "Todos") {
                            return true;
                          }
                          return ocorrencia['status'] == _statusSelecionado;
                        }).toList();

                        // Ordenação por número de ocorrência
                        ocorrencias.sort((a, b) =>
                            a['_vendaNumero'].compareTo(b['_vendaNumero']));

                        return ListView.builder(
                          itemCount: ocorrencias.length,
                          itemBuilder: (context, index) {
                            final ocorrencia = ocorrencias[index];
                            final status =
                                ocorrencia['status']?.toLowerCase() ?? '';
                            final cardColor = _getStatusColor(status);

                            return Card(
                              color: cardColor,
                              child: ListTile(
                                title: Text(
                                  ocorrencia['nomeLocal'] ??
                                      'Local não informado',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "Status: ${ocorrencia['status'] ?? 'Indefinido'}"),
                                    Text(
                                        "Observações: ${ocorrencia['observacoes'] ?? 'Nenhuma'}"),
                                    Text(
                                        "Nº da Ocorrência: ${ocorrencia['_vendaNumero'].toString().padLeft(4, '0')}"),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Colors.grey),
                                onTap: () {
                                  _mostrarDetalhesOcorrencia(
                                      context, ocorrencia);
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget legendaStatus(String texto, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          Container(width: 16, height: 16, color: cor),
          const SizedBox(width: 4),
          Text(texto, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'realizado':
        return Colors.green.shade400;
      case 'analisado':
        return Colors.yellow.shade400;
      case 'pendente':
        return Colors.red.shade400;
      default:
        return Colors.grey.shade500;
    }
  }

  void _mostrarDetalhesOcorrencia(
      BuildContext context, Map<String, dynamic> ocorrencia) {
    Uint8List? assinaturaBytes;

    if (ocorrencia['assinatura'] != null &&
        ocorrencia['assinatura'].isNotEmpty) {
      assinaturaBytes = base64Decode(ocorrencia['assinatura']);
    }

    showDialog(
      context: context,
      builder: (context) {
        Uint8List? assinaturaBytes;

        if (ocorrencia['assinatura'] != null &&
            ocorrencia['assinatura'].isNotEmpty) {
          assinaturaBytes = base64Decode(ocorrencia['assinatura']);
        }

        return AlertDialog(
          title: Text("Detalhes da Ocorrência"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Unidade: ${ocorrencia['unidade']}"),
                Text("Nº da Ocorrência: ${ocorrencia['_vendaNumero']}"),
                Text(
                    "Problema: ${ocorrencia['ocorrencia'].isEmpty ? 'Nenhuma' : ocorrencia['ocorrencia']}"),
                Text("Local: ${ocorrencia['nomeLocal']}"),
                Text("Status: ${ocorrencia['status']}"),
                Text("Status Equipamento: ${ocorrencia['statusEquipamento']}"),
                Text("Data Início: ${ocorrencia['dataInicio']}"),
                Text("Hora Início: ${ocorrencia['horaInicio']}"),
                Text("Data Término: ${ocorrencia['dataTermino']}"),
                Text("Hora Término: ${ocorrencia['horaTermino']}"),
                Text(
                    "Observações: ${ocorrencia['observacoes'].isEmpty ? 'Nenhuma' : ocorrencia['observacoes']}"),
                const SizedBox(height: 8),

                // Exibir a imagem da ocorrência, se existir
                if (ocorrencia['imageUrl'] != null &&
                    ocorrencia['imageUrl'].isNotEmpty)
                  Row(
                    children: [
                      Image.network(ocorrencia['imageUrl'],
                          height: 200, fit: BoxFit.cover),

                      const SizedBox(width: 8),

                      // Exibir a assinatura, se existir
                      if (assinaturaBytes != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Nome: ${ocorrencia['nomeUsuario']}"),
                            const SizedBox(height: 5),
                            Text("Assinatura:",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Image.memory(assinaturaBytes, height: 100),
                            ),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Fechar"),
            ),
          ],
        );
      },
    );
  }
}
