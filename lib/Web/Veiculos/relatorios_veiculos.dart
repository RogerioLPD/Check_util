import 'package:checkutil/Services/equipamentos.dart';
import 'package:checkutil/Services/lista_equiprovider.dart';
import 'package:checkutil/Services/relatorios_veiculos_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

class RelatoriosVeiculos extends StatefulWidget {
  const RelatoriosVeiculos({Key? key}) : super(key: key);

  @override
  State<RelatoriosVeiculos> createState() => _RelatoriosVeiculosState();
}

class _RelatoriosVeiculosState extends State<RelatoriosVeiculos> {
  Map<String, dynamic>? _veiculosSelecionado;
  List<Map<String, dynamic>> _checklistFinalizado = [];
  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final unidade = Provider.of<UnidadeProvider>(context, listen: false)
          .unidadeSelecionada;
      Provider.of<RelatoriosVeiculosProvider>(context, listen: false)
          .listarVeiculos(unidade);
    });
  }

  Future<void> _carregarChecklistFinalizado(
      String placa, DateTime dataInicio, DateTime dataFim) async {
    // Ajustando para filtrar pela data de início e data de fim
    final snapshot = await FirebaseFirestore.instance
        .collection('Veiculos_finalizados')
        .where('placa', isEqualTo: placa)
        .where('dataFinalizacao', isGreaterThanOrEqualTo: dataInicio)
        .where('dataFinalizacao', isLessThanOrEqualTo: dataFim)
        .orderBy('dataFinalizacao', descending: true)
        .get();

    List<Map<String, dynamic>> resultados = [];

    for (var doc in snapshot.docs) {
      final dados = doc.data();
      resultados.add({
        'dataChecklist': dados['dataFinalizacao'],
        'usuario': dados['usuario'],
        'assinaturaUrl': dados['assinaturaUrl'],
        'itens': List<Map<String, dynamic>>.from(
            (dados['itens'] ?? []).map((e) => Map<String, dynamic>.from(e))),
      });
    }

    setState(() {
      _checklistFinalizado = resultados;
    });
  }

  Future<void> _selecionarDatas(BuildContext context) async {
    final DateTime? inicio = await showDatePicker(
      context: context,
      initialDate: _dataInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (inicio != null) {
      final DateTime? fim = await showDatePicker(
        context: context,
        initialDate: _dataFim ?? DateTime.now(),
        firstDate: inicio,
        lastDate: DateTime(2100),
      );

      if (fim != null && fim.isAfter(inicio)) {
        setState(() {
          _dataInicio = inicio;
          _dataFim = fim;
          _checklistFinalizado.clear();
        });
        if (_veiculosSelecionado != null) {
          _carregarChecklistFinalizado(
              _veiculosSelecionado!['placa'], inicio, fim);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('A data de fim deve ser após a de início.')),
        );
      }
    }
  }

  Future<void> _gerarPDF() async {
    final pdf = pw.Document();

    for (var checklist in _checklistFinalizado) {
      final dataFormatada = DateFormat("dd/MM/yyyy 'às' HH:mm")
          .format(checklist['dataChecklist'].toDate());

      // Carrega a assinatura do usuário se existir
      pw.Widget? assinaturaWidget;
      if (checklist['assinaturaUrl'] != null &&
          checklist['assinaturaUrl'].toString().isNotEmpty) {
        final assinaturaImage = await networkImage(checklist['assinaturaUrl']);
        assinaturaWidget = pw.Image(assinaturaImage, height: 80);
      }

      // Lista de itens com possíveis imagens
      final List<pw.Widget> itensWidgets = [];
      for (var item in checklist['itens']) {
        final List<pw.Widget> children = [
          pw.Text('- ${item['item']}'),
          if (item['descricao'] != '')
            pw.Text('  Descrição: ${item['descricao']}'),
          pw.Text('  Status: ${item['status']}'),
          if (item['comentario'] != '')
            pw.Text('  Comentário: ${item['comentario']}'),
        ];

        if (item['imagem'] != null && item['imagem'].toString().isNotEmpty) {
          try {
            final imagem = await networkImage(item['imagem']);
            children.add(pw.SizedBox(height: 4));
            children.add(
              pw.Center(
                child: pw.Image(
                  imagem,
                  width: 300,
                  height: 200,
                  fit: pw.BoxFit.fill, // força o preenchimento do espaço
                ),
              ),
            );
          } catch (e) {
            children.add(pw.Text('  (Erro ao carregar imagem)'));
          }
        }

        itensWidgets.add(pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [...children, pw.SizedBox(height: 10)],
        ));
      }

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${_veiculosSelecionado!['tipoVeiculo']} - ${_veiculosSelecionado!['placa']}',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Data: $dataFormatada'),
                pw.Text(
                    'Usuário: ${checklist['usuario']['nome']} (${checklist['usuario']['email']})'),
                if (assinaturaWidget != null) ...[
                  pw.SizedBox(height: 12),
                  pw.Text('Assinatura:'),
                  assinaturaWidget,
                ],
                pw.SizedBox(height: 12),
                pw.Text('Itens do Checklist:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                ...itensWidgets,
                pw.Divider(),
              ],
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.teal;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('Veículos',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (_checklistFinalizado.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              tooltip: 'Gerar PDF',
              onPressed: _gerarPDF,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<RelatoriosVeiculosProvider>(
          builder: (context, veiculosProvider, child) {
            final veiculos = veiculosProvider.veiculos;

            if (veiculos.isEmpty) {
              return const Center(
                  child: Text('Nenhum equipamento cadastrado.'));
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.build, color: Colors.teal),
                      const SizedBox(width: 8),
                      const Text('Escolha um equipamento:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Selecione uma Placa',
                      prefixIcon: Icon(Icons.precision_manufacturing),
                    ),
                    value: _veiculosSelecionado,
                    items: veiculos.map((veiculos) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: veiculos,
                        child: Text(
                            '${veiculos['tipoVeiculo']} - ${veiculos['placa']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _veiculosSelecionado = value;
                        _checklistFinalizado.clear();
                      });
                      if (_dataInicio != null && _dataFim != null) {
                        _carregarChecklistFinalizado(
                            value!['placa'], _dataInicio!, _dataFim!);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                    onPressed: () => _selecionarDatas(context),
                    icon: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                    ),
                    label: Text(
                      _dataInicio != null && _dataFim != null
                          ? 'Período: ${DateFormat("dd/MM/yyyy").format(_dataInicio!)} até ${DateFormat("dd/MM/yyyy").format(_dataFim!)}'
                          : 'Escolher Período',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_checklistFinalizado.isNotEmpty)
                    ListView(
                      shrinkWrap: true,
                      children: _checklistFinalizado.map((checklist) {
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data de Finalização: ${DateFormat("dd/MM/yyyy 'às' HH:mm").format(checklist['dataChecklist'].toDate())}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: themeColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (checklist['assinaturaUrl']
                                    .toString()
                                    .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Image.network(
                                        checklist['assinaturaUrl']),
                                  ),
                                const SizedBox(height: 10),
                                Text(
                                  'Itens do Checklist:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: themeColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                for (var item in checklist['itens'])
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('- ${item['item']}'),
                                        if (item['descricao'] != '')
                                          Text(
                                              '  Descrição: ${item['descricao']}'),
                                        Text('  Status: ${item['status']}'),
                                        if (item['comentario'] != '')
                                          Text(
                                              '  Comentário: ${item['comentario']}'),
                                        if (item['imagem'] != null &&
                                            item['imagem']
                                                .toString()
                                                .isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Image.network(
                                              item['imagem'],
                                              height: 100,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    const Center(child: Text('Nenhum checklist encontrado')),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
