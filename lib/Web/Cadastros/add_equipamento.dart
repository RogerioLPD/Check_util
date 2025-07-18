import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:checkutil/Mobile/Cadastros/pdf_helper_mobile.dart';
import 'package:checkutil/Web/Cadastros/pdf_helper_web.dart';
import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';

class CadastrarEquipamentoScreen extends StatefulWidget {
  const CadastrarEquipamentoScreen({super.key});

  @override
  State<CadastrarEquipamentoScreen> createState() => _CadastrarEquipamentoScreenState();
}

class _CadastrarEquipamentoScreenState extends State<CadastrarEquipamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tagController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _tipoEquipamentoController = TextEditingController();

  File? _imagem;
  String? _imagemBase64;

  final ImagePicker _picker = ImagePicker();

  List unidades = [];
  List locais = [];
  String? unidadeSelecionada;
  String? localSelecionado;
  String? prioridadeSelecionada;

  @override
  void initState() {
    super.initState();
  }

  void _onUnidadeChanged(String? newValue) {
    setState(() {
      unidadeSelecionada = newValue;
      locais.clear();
    });
  }

  Future<void> _selecionarImagem() async {
    final XFile? imagemSelecionada = await _picker.pickImage(source: ImageSource.gallery);
    if (imagemSelecionada != null) {
      if (kIsWeb) {
        final bytes = await imagemSelecionada.readAsBytes();
        setState(() {
          _imagemBase64 = base64Encode(bytes);
        });
      } else {
        setState(() {
          _imagem = File(imagemSelecionada.path);
        });
      }
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      String imageName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance.ref().child('checklist_images').child(imageName);
      final uploadTask = await storageRef.putFile(image);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  Future<void> _salvarEquipamento() async {
    String tag = _tagController.text;
    
    String tipoEquipamento = _tipoEquipamentoController.text;

    String? unidade = Provider.of<UnidadeProvider>(context, listen: false).unidadeSelecionada;

    if (tag.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O número da Tag não pode estar vazio')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      String? imagemUrl;

      try {
        if (_imagem != null) {
          imagemUrl = await _uploadImage(_imagem!);
        }

        if (_imagemBase64 != null) {
          final bytes = base64Decode(_imagemBase64!);
          String imageName = DateTime.now().millisecondsSinceEpoch.toString();
          final storageRef = FirebaseStorage.instance.ref().child('checklist_images').child(imageName);
          final uploadTask = await storageRef.putData(bytes);
          imagemUrl = await uploadTask.ref.getDownloadURL();
        }

        QuerySnapshot existingTag = await FirebaseFirestore.instance
            .collection('Equipamentos')
            .where('tag', isEqualTo: tag)
            .get();

        if (existingTag.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Já existe uma Tag com o número $tag.')),
          );
          return;
        }

        await FirebaseFirestore.instance.collection('Equipamentos').add({
          'unidade': unidade,
          'tag': tag,
          'marca': _marcaController.text,
          'modelo': _modeloController.text,
          'tipoEquipamento': _tipoEquipamentoController.text,
          'imageUrl': imagemUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipamento cadastrado com sucesso!')),
        );

        _tagController.clear();
        _marcaController.clear();
        _modeloController.clear();
        _tipoEquipamentoController.clear();
        setState(() {
          unidadeSelecionada = null;
          _imagem = null;
          _imagemBase64 = null;
        });
         Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QrCodeScreen(
              tag,
              tipoEquipamento,
              unidade ?? 'Unidade não especificada',
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar equipamento: $e')),
        );
      }
    }
  }

  void _limparFormulario() {
    _tagController.clear();
    _marcaController.clear();
    _modeloController.clear();
    _tipoEquipamentoController.clear();
    setState(() {
      unidadeSelecionada = null;
      _imagem = null;
      _imagemBase64 = null;
    });
  }



  @override
  Widget build(BuildContext context) {
    // Obtém a unidadeSelecionada do Provider
    unidadeSelecionada =
        Provider.of<UnidadeProvider>(context).unidadeSelecionada ??
            'Nenhuma Unidade Selecionada';

    // Chama _fetchLocais() sempre que a unidadeSelecionada mudar
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          customElevatedButton(
            onPressed: _limparFormulario,
            label: 'Cancelar',
            labelStyle: buttonTextStyle,
            icon: Icons.cancel,
            iconColor: const Color.fromARGB(255, 6, 41, 70),
            backgroundColor: const Color.fromARGB(193, 195, 204, 218),
          ),
          const SizedBox(width: 10),
          customElevatedButton(
            onPressed: _salvarEquipamento,
            label: 'Salvar',
            labelStyle: buttonTextStyle,
            icon: Icons.check,
            iconColor: const Color.fromARGB(255, 6, 41, 70),
            backgroundColor: backgroundButton,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                        Text(
                          'Cadastrar Equipamento',
                          style: headTextStyle,
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 110, // Definindo largura fixa
                              child: GestureDetector(
                                onTap: _selecionarImagem,
                                child: Container(
                                  width:
                                      110, // Mantendo consistência com o tamanho do botão
                                  height: 105,
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(143, 55, 71, 79),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF37474F),
                                    ),
                                  ),
                                  child:
                                      _imagem == null && _imagemBase64 == null
                                          ? const Icon(Icons.camera_alt,
                                              color: Color(0xFF37474F),
                                              size: 50)
                                          : (kIsWeb && _imagemBase64 != null)
                                              ? Image.memory(
                                                  base64Decode(_imagemBase64!),
                                                  width: 100,
                                                  height: 100)
                                              : (_imagem != null)
                                                  ? Image.file(_imagem!,
                                                      width: 100, height: 100)
                                                  : const Icon(Icons.camera_alt,
                                                      color: Color(0xFF37474F),
                                                      size: 50),
                                ),
                              ),
                            ),
                            const SizedBox(width: 50),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment
                                    .start, // Alinha os textos à esquerda
                                children: [
                                  Text(
                                    'Clique no botão ao lado para selecionar a imagem do equipamento que deseja cadastrar',
                                    style: drawerStyle.copyWith(
                                      fontSize: 16,
                                      color: textButton,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: true,
                                  ),
                                  Text(
                                    'A foto deve estar nítida e deve enquadrar o equipamento inteiro',
                                    style: drawerStyle.copyWith(
                                      fontSize: 12,
                                      color: drawerTextColor,
                                    ),
                                    softWrap: true,
                                    textAlign: TextAlign
                                        .left, // Opcional, pois já está alinhado pelo crossAxisAlignment
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Identificação do equipamento',
                                    style: secondaryTextStyle,
                                    textAlign: TextAlign.start,
                                  ),
                                  _buildTextField(_tagController, 'Tag')
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tipo do equipamento',
                                    style: secondaryTextStyle,
                                    textAlign: TextAlign.start,
                                  ),
                                  _buildTextField(_tipoEquipamentoController,
                                      'Tipo de Equipamento'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unidade',
                              style: secondaryTextStyle,
                              textAlign: TextAlign.start,
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color.fromARGB(
                                        255, 216, 216, 216),
                                    width: 1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              alignment: Alignment.centerLeft,
                              height:
                                  48, // Define altura fixa para alinhar com o dropdown
                              child: Text(
                                unidadeSelecionada ?? 'Nenhuma Unidade Selecionada',
                                style: bodyTextStyle.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Marca do equipamento',
                                    style: secondaryTextStyle,
                                    textAlign: TextAlign.start,
                                  ),
                                  _buildTextField(_marcaController, 'Marca')
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Modelo do equipamento',
                                    style: secondaryTextStyle,
                                    textAlign: TextAlign.start,
                                  ),
                                  _buildTextField(_modeloController, 'Modelo'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 50),
                        
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Column(
      children: [
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: bodyTextStyle,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(
                  color: Color.fromARGB(255, 216, 216, 216)), // Cor correta
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(
                  color: Color(0xFF37474F), width: 2), // Cor ao focar
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira $label.';
            }
            return null;
          },
        ),
      ],
    );
  }
}

Widget buildTextField(String label) {
  return Column(
    children: [
      const SizedBox(height: 10),
      TextFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: bodyTextStyle,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Color(0xFF37474F)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 216, 216, 216)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Color(0xFF37474F), width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, insira $label.';
          }
          return null;
        },
      ),
    ],
  );
}

class QrCodeScreen extends StatelessWidget {
  final String tag;
  final String unidade;
  final String tipoEquipamento;

  const QrCodeScreen(this.tag, this.tipoEquipamento, this.unidade, 
      {super.key});

  @override
  Widget build(BuildContext context) {
    final String fullUrl =
        'https://util-check.web.app/#auditor?tag=$tag';

    final Map<String, dynamic> qrData = {
      'url': fullUrl,
      'tag': tag,
      'tipoEquipamento': tipoEquipamento,
      'unidade': unidade,
      
    };

    final String encodedQrData = jsonEncode(qrData);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'QR Code do Equipamento',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        elevation: 4,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF607D8B), Color(0xFF455A64)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF607D8B), Color(0xFF455A64)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              // Para garantir que o conteúdo seja rolável em dispositivos menores
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                            20), // Bordas arredondadas para suavizar o visual
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: encodedQrData,
                        size: 200, // Tamanho do QR Code
                      ),
                    ),
                    const SizedBox(height: 30),
                    customElevatedButton(
                      onPressed: () =>
                          _saveQrCodeToFirestore(encodedQrData, context),
                      label: 'Salvar QR Code',
                      labelStyle: buttonTextStyle,
                      icon: Icons.save,
                      iconColor: const Color.fromARGB(255, 6, 41, 70),
                      backgroundColor: Colors.orange,
                    ),
                    const SizedBox(height: 20),
                    customElevatedButton(
                      onPressed: () => _saveAsPdf(encodedQrData),
                      icon: Icons.picture_as_pdf,
                      iconColor: const Color.fromARGB(255, 6, 41, 70),
                      backgroundColor: Colors.orange,
                      label: 'Salvar como PDF',
                      labelStyle: buttonTextStyle,
                    ),
                    const SizedBox(height: 20),
                    customElevatedButton(
                      onPressed: () => _printQrCode(encodedQrData),
                      icon: Icons.print,
                      label: 'Imprimir QR Code',
                      labelStyle: buttonTextStyle,
                      iconColor: const Color.fromARGB(255, 6, 41, 70),
                      backgroundColor: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveQrCodeToFirestore(
      String qrData, BuildContext context) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Usuário não autenticado');

      // Gerar imagem do QR Code
      final qrImage = await QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: true,
      ).toImage(200);

      final ByteData? byteData =
          await qrImage.toByteData(format: ImageByteFormat.png);
      if (byteData == null) throw Exception('Erro ao gerar imagem do QR Code');

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Fazer upload para Firebase Storage
      final storageRef =
          FirebaseStorage.instance.ref().child('qr_codes/$userId/$tag.png');
      final uploadTask = await storageRef.putData(pngBytes);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // Salvar dados no Firestore
      final qrCodeRef = FirebaseFirestore.instance
          .collection('QRCODES')
          .doc(userId)
          .collection('user_qr_codes')
          .doc(tag);

      await qrCodeRef.set({
        'tag': tag,
        'tipoEquipamento': tipoEquipamento,
        'unidade': unidade,
        'qrData': qrData,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR Code salvo com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar QR Code: $e')),
      );
    }
  }

  

  Future<void> _saveAsPdf(String qrData) async {
    final pdf = pw.Document();

    final qrImage = await QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: true,
    ).toImage(200);

    final ByteData? byteData = await qrImage.toByteData(format: ImageByteFormat.png);
    if (byteData == null) return;

    final Uint8List pngBytes = byteData.buffer.asUint8List();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Image(pw.MemoryImage(pngBytes)),
        ),
      ),
    );

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      await savePdfWeb(pdfBytes, "QRCode");
    } else {
      await savePdfMobile(pdfBytes);
    }
  }

  Future<void> _printQrCode(String qrData) async {
    final pdf = pw.Document();

    final qrImage = await QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: true,
    ).toImage(200);

    final ByteData? byteData = await qrImage.toByteData(format: ImageByteFormat.png);
    if (byteData == null) return;

    final Uint8List pngBytes = byteData.buffer.asUint8List();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Image(pw.MemoryImage(pngBytes)),
        ),
      ),
    );

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      await printQrCodeWeb(pdfBytes);
    } else {
      await printQrCodeMobile(pdfBytes);
    }
  }

}