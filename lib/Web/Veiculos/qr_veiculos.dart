import 'package:checkutil/Mobile/Cadastros/pdf_helper_mobile.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:checkutil/Web/Cadastros/pdf_helper_web.dart';
import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

class QRCodeVeiculos extends StatefulWidget {
  const QRCodeVeiculos({super.key});

  @override
  _QRCodeVeiculosState createState() => _QRCodeVeiculosState();
}

class _QRCodeVeiculosState extends State<QRCodeVeiculos> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  bool _dadosCarregados = false;
  String? _unidade;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final unidadeProvider = Provider.of<UnidadeProvider>(context);
    final unidadeSelecionada = unidadeProvider.unidadeSelecionada;

    if (!_dadosCarregados &&
        unidadeSelecionada != null &&
        unidadeSelecionada.isNotEmpty) {
      setState(() {
        _unidade = unidadeSelecionada;
        _dadosCarregados = true;
      });
    }
  }

  Future<void> _generateQrCodePdf(String imageUrl, String fileName) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200)
        throw Exception('Falha ao carregar a imagem do QR Code.');

      final pdf = pw.Document();
      final image = pw.MemoryImage(response.bodyBytes);

      pdf.addPage(pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('QR Code', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.Image(image),
            ],
          ),
        ),
      ));

      final pdfBytes = await pdf.save();

      if (kIsWeb) {
        await savePdfWeb(pdfBytes, fileName);
      } else {
        await savePdfMobile(pdfBytes);
      }
    } catch (e) {
      debugPrint('Erro ao gerar o PDF: $e');
    }
  }

  Future<void> _printQrCode(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200)
        throw Exception('Falha ao carregar a imagem do QR Code.');

      final pdf = pw.Document();
      final image = pw.MemoryImage(response.bodyBytes);

      pdf.addPage(pw.Page(
          build: (pw.Context context) => pw.Center(child: pw.Image(image))));
      final pdfBytes = await pdf.save();

      if (kIsWeb) {
        await printQrCodeWeb(pdfBytes);
      } else {
        await printQrCodeMobile(pdfBytes);
      }

      debugPrint('QR Code enviado para impressão.');
    } catch (e) {
      debugPrint('Erro ao imprimir o QR Code: $e');
    }
  }

  Future<void> _deleteQrCode(String documentId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Usuário não autenticado.');

      final qrCodesRef = FirebaseFirestore.instance
          .collection('QR_Veiculos')
          .doc(userId)
          .collection('user_qr_veiculos')
          .doc(documentId);

      await qrCodesRef.delete();
      debugPrint('QR Code deletado com sucesso.');
    } catch (e) {
      debugPrint('Erro ao deletar o QR Code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || _unidade == null) {
      return const Scaffold(
        body: Center(child: Text("Carregando QR Codes...")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('', style: headTextStyle),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
              child: Container(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: Color.fromARGB(255, 216, 216, 216), width: 1.0),
                    right: BorderSide(
                        color: Color.fromARGB(255, 216, 216, 216), width: 1.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(45, 20, 40, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('QR Codes dos Veículos', style: headTextStyle),
                      const SizedBox(height: 24),
                      TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          labelText: 'Buscar por Placa, Local ou Tipo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(
                                color: Color(0xffd1e6d9), width: 1.0),
                          ),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('QR_Veiculos')
                              .doc(userId)
                              .collection('user_qr_veiculos')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                  child: Text('Nenhum QR Code salvo.'));
                            }

                            final qrCodes = snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final placa = (data['placa'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              final unidade = (data['unidade'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              final tipoVeiculo = (data['tipoVeiculo'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              final unidadeDoc =
                                  (data['unidade'] ?? '').toString();
                              final unidadeAtual = _unidade ?? '';

                              return (unidadeDoc == unidadeAtual) &&
                                  (placa.contains(searchQuery) ||
                                      unidade.contains(searchQuery) ||
                                      tipoVeiculo.contains(searchQuery));
                            }).toList();

                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xfff8fbfa),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xffd1e6d9)),
                              ),
                              child: ListView.separated(
                                itemCount: qrCodes.length,
                                separatorBuilder: (_, __) => const Divider(
                                    color: Color(0xffd1e6d9), height: 1),
                                itemBuilder: (context, index) {
                                  final qrCode = qrCodes[index].data()
                                      as Map<String, dynamic>;
                                  final documentId = qrCodes[index].id;
                                  final placa = qrCode['placa'] ?? 'Sem nome';
                                  final unidade =
                                      qrCode['unidade'] ?? 'Desconhecido';
                                  final tipoVeiculo =
                                      qrCode['tipoVeiculo'] ?? 'Desconhecido';
                                  final imageUrl = qrCode['imageUrl'] ?? '';
                                  

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12.0, horizontal: 12.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 70,
                                          child: imageUrl.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    imageUrl,
                                                    width: 50,
                                                    height: 50,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : const Icon(Icons.qr_code,
                                                  size: 40, color: Colors.grey),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Placa: $placa',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: textSecondary)),
                                              Text('Unidade: $unidade',
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      color: textSecondary)),
                                              Text('Tipo Veículo: $tipoVeiculo',
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      color: textSecondary)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.picture_as_pdf),
                                              color: backgroundColor,
                                              tooltip: 'Gerar PDF',
                                              onPressed: () =>
                                                  _generateQrCodePdf(
                                                      imageUrl, placa),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.print),
                                              color: backgroundColor,
                                              tooltip: 'Imprimir QR Code',
                                              onPressed: () =>
                                                  _printQrCode(imageUrl),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              color: Colors.red,
                                              tooltip: 'Deletar QR Code',
                                              onPressed: () =>
                                                  _deleteQrCode(documentId),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
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
        ),
      ),
    );
  }
}
