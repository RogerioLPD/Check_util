import 'package:checkutil/Mobile/Cadastros/pdf_helper_mobile.dart';
import 'package:checkutil/Web/Cadastros/pdf_helper_web.dart';
import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart'; // Import necessário para kIsWeb


class QRCodeDisplayScreen extends StatefulWidget {
  const QRCodeDisplayScreen({super.key});

  @override
  _QRCodeDisplayScreenState createState() => _QRCodeDisplayScreenState();
}

class _QRCodeDisplayScreenState extends State<QRCodeDisplayScreen> {
  List unidades = [];
  String? unidadeSelecionada;
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  Future<void> _generateQrCodePdf(String imageUrl, String fileName) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Falha ao carregar a imagem do QR Code.');
      }

      final pdf = pw.Document();
      final image = pw.MemoryImage(response.bodyBytes);

      pdf.addPage(
        pw.Page(
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
        ),
      );

      final pdfBytes = await pdf.save();

      if (kIsWeb) {
        // Chama a função do helper web
        await savePdfWeb(pdfBytes, fileName);
      } else {
        // Chama a função do helper mobile
        await savePdfMobile(pdfBytes);
      }
    } catch (e) {
      debugPrint('Erro ao gerar o PDF: $e');
    }
  }

  Future<void> _printQrCode(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Falha ao carregar a imagem do QR Code.');
      }

      final pdf = pw.Document();
      final image = pw.MemoryImage(response.bodyBytes);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(
            child: pw.Image(image),
          ),
        ),
      );

      final pdfBytes = await pdf.save();

      if (kIsWeb) {
        // Chama a função do helper web
        await printQrCodeWeb(pdfBytes);
      } else {
        // Chama a função do helper mobile
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
          .collection('QRCODES')
          .doc(userId)
          .collection('user_qr_codes')
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
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('QR Codes'),
          flexibleSpace: Container(
            color: backgroundColor,
          ),
        ),
        body: const Center(child: Text('Usuário não autenticado.')),
      );
    }

    final qrCodesRef = FirebaseFirestore.instance
        .collection('QRCODES')
        .doc(userId)
        .collection('user_qr_codes');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Buscar por TAG, Local ou Tipo',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
        ),
        actions: [],
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
                  Text(
                    'QR Codes dos Equipamentos',
                    style: headTextStyle,
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: qrCodesRef
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(child: Text('Nenhum QR Code salvo.'));
                        }

                        final qrCodes = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final tag =
                              (data['tag'] ?? '').toString().toLowerCase();
                          final nomeLocal = (data['nomeLocal'] ?? '')
                              .toString()
                              .toLowerCase();
                          final tipoEquipamento =
                              (data['tipoEquipamento'] ?? '')
                                  .toString()
                                  .toLowerCase();
                          return tag.contains(searchQuery) ||
                              nomeLocal.contains(searchQuery) ||
                              tipoEquipamento.contains(searchQuery);
                        }).toList();

                        return ListView.builder(
                          itemCount: qrCodes.length,
                          itemBuilder: (context, index) {
                            final qrCode =
                                qrCodes[index].data() as Map<String, dynamic>;
                            final documentId = qrCodes[index].id;
                            final tag = qrCode['tag'] ?? 'Sem nome';
                            final nomeLocal =
                                qrCode['nomeLocal'] ?? 'Desconhecido';
                            final tipoEquipamento =
                                qrCode['tipoEquipamento'] ?? 'Desconhecido';
                            final imageUrl = qrCode['imageUrl'] ?? '';

                            return customCard(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 16),
                                leading: imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.qr_code,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                title: Text('TAG: $tag',
                                    style: cardTitleTextStyle),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Local: $nomeLocal',
                                      style: subtitleTextStyle,
                                    ),
                                    Text('Tipo Equipamento: $tipoEquipamento',
                                        style: subtitleTextStyle),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.picture_as_pdf),
                                      color: backgroundColor,
                                      tooltip: 'Gerar PDF',
                                      onPressed: () =>
                                          _generateQrCodePdf(imageUrl, tag),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.print),
                                      color: backgroundColor,
                                      tooltip: 'Imprimir QR Code',
                                      onPressed: () => _printQrCode(imageUrl),
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
}
