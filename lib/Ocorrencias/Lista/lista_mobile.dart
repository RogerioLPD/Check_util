import 'dart:convert';
import 'dart:typed_data';
import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ListaOcorrenciasMobile extends StatefulWidget {
  const ListaOcorrenciasMobile({super.key});

  @override
  _ListaOcorrenciasMobileState createState() => _ListaOcorrenciasMobileState();
}

class _ListaOcorrenciasMobileState extends State<ListaOcorrenciasMobile> {
  String? _statusSelecionado = "Todos"; // Defina um valor inicial
  late final Function(String?) onStatusChanged;

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
      backgroundColor: primaryColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(146.h), // Altura responsiva da AppBar
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: backDrawerColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double availableHeight = constraints.maxHeight;

                return Padding(
                  padding: EdgeInsets.only(
                    left: 16.w,
                    right: 16.w,
                    top: availableHeight * 0.1,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Primeiro item alinhado à esquerda
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: textSecondary),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Spacer(), // Empurra os próximos itens para a direita

                          // Segundo e terceiro itens alinhados à direita
                          Row(
                            children: [
                              Icon(Icons.filter_list,
                                  color: backgroundAppBarMobile),
                              SizedBox(width: 8.w),
                              DropdownButton<String>(
                                style: bodyTextStyle,
                                value: _statusSelecionado,
                                hint: Text(
                                  "Filtrar",
                                  style: bodyTextStyle,
                                  textAlign: TextAlign.left,
                                ),
                                icon: const SizedBox.shrink(),
                                underline: const SizedBox.shrink(),
                                items: [
                                  "Todos",
                                  "Realizado",
                                  "Analisado",
                                  "Pendente"
                                ].map((status) {
                                  return DropdownMenuItem<String>(
                                    value: status,
                                    child: Center(
                                      child: Text(
                                        status,
                                        style: bodyTextStyle,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                selectedItemBuilder: (BuildContext context) {
                                  return [
                                    "Todos",
                                    "Realizado",
                                    "Analisado",
                                    "Pendente"
                                  ].map((status) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        status,
                                        style: buttonMobileTextStyle.copyWith(
                                            fontSize: 12.sp),
                                      ),
                                    );
                                  }).toList();
                                },
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _statusSelecionado = newValue;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        'Lista de Ocorrências',
                        style: mobileTextStyle.copyWith(
                          fontSize: 28.sp,
                          color: backgroundAppBarMobile,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Text("Legenda do Status:",
                        style: TextStyle(fontSize: 14.sp)),
                    legendaStatus("Realizado", Colors.green),
                    legendaStatus("Analisado", Colors.yellow),
                    legendaStatus("Pendente", Colors.red),
                  ],
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Ocorrencias')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection('ocorrencia')
                        .where('unidade', isEqualTo: unidadeSelecionada)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text("Nenhuma ocorrência encontrada."));
                      }

                      final List<Map<String, dynamic>> ocorrencias =
                          snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        data['_vendaNumero'] = (data['_vendaNumero'] is String)
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
                                _mostrarDetalhesOcorrencia(context, ocorrencia);
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
                  SizedBox(height: 8.h),

                Image.network(ocorrencia['imageUrl'],
                    height: 200, fit: BoxFit.cover),

                 SizedBox(height: 8.h),

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
