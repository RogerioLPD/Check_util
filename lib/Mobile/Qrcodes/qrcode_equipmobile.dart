
import 'package:checkutil/Mobile/Cadastros/pdf_helper_mobile.dart';
import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;

class QRCodeEquipamentoMobile extends StatefulWidget {
  const QRCodeEquipamentoMobile({super.key});

  @override
  _QRCodeEquipamentoMobileState createState() =>
      _QRCodeEquipamentoMobileState();
}

class _QRCodeEquipamentoMobileState extends State<QRCodeEquipamentoMobile> {
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
              pw.Text('QR Code', style: const pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.Image(image),
            ],
          ),
        ),
      ),
    );

    final pdfBytes = await pdf.save();

    // Salva o PDF no dispositivo móvel
    await savePdfMobile(pdfBytes);
    debugPrint('PDF salvo no dispositivo.');
  } catch (e) {
    debugPrint('Erro ao salvar o PDF: $e');
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

    // Envia o QR Code para impressão
    await printQrCodeMobile(pdfBytes);
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
          title: Text(
            'QR Codes dos Equipamentos',
            style: secondaryTextStyle.copyWith(fontSize: 12.sp),
          ),
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
      backgroundColor: primaryColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(160.h), // Altura responsiva da AppBar
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
                          // Ícone de voltar alinhado à esquerda
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: textSecondary),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          SizedBox(width: 16.w), // Espaçamento entre elementos

                          // Campo de busca expandido
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              style: const TextStyle(
                                  color:
                                      backgroundAppBarMobile), // Cor do texto digitado
                              decoration: InputDecoration(
                                labelText: 'Buscar por TAG, Local ou Tipo',
                                labelStyle: const TextStyle(
                                    color: Colors
                                        .grey), // Cor quando não estiver selecionado
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                      color: backgroundAppBarMobile,
                                      width: 2.0), // Cor quando selecionado
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                      color: Colors.grey,
                                      width:
                                          1.5), // Cor quando não estiver selecionado
                                ),
                                prefixIcon: const Icon(Icons.search,
                                    color: Colors.grey), // Ícone de busca
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12.h,
                                  horizontal: 16.w,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value.toLowerCase();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h), // Espaçamento entre elementos
                      Text(
                        'QR Code Equipamentos',
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
                SizedBox(height: 60.h),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: qrCodesRef
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('Nenhum QR Code salvo.'));
                      }

                      final qrCodes = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final tag =
                            (data['tag'] ?? '').toString().toLowerCase();
                        final nomeLocal =
                            (data['nomeLocal'] ?? '').toString().toLowerCase();
                        final tipoEquipamento = (data['tipoEquipamento'] ?? '')
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

                          return customCardMobile(
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
                              title: Text(
                                'TAG: $tag',
                                style: cardTitleTextStyle.copyWith(
                                    fontSize: 10.sp),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Local: $nomeLocal',
                                    style: subtitleTextStyle.copyWith(
                                        fontSize: 8.sp),
                                  ),
                                  Text(
                                    'Tipo Equipamento: $tipoEquipamento',
                                    style: subtitleTextStyle.copyWith(
                                        fontSize: 8.sp),
                                  ),
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
                                    onPressed: () => _deleteQrCode(documentId),
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
    );
  }
}
