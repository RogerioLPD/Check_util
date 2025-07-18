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

class CadastrarVeiculoScreen extends StatefulWidget {
  const CadastrarVeiculoScreen({super.key});

  @override
  State<CadastrarVeiculoScreen> createState() => _CadastrarVeiculoScreenState();
}

class _CadastrarVeiculoScreenState extends State<CadastrarVeiculoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();

  File? _imagem;
  String? _imagemBase64;
  String? _tipoVeiculoSelecionado;

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
    final XFile? imagemSelecionada =
        await _picker.pickImage(source: ImageSource.gallery);
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
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('veiculos_images')
          .child(imageName);
      final uploadTask = await storageRef.putFile(image);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  Future<void> _salvarEquipamento() async {
    String placa = _placaController.text;
    String tipoVeiculo = _tipoVeiculoSelecionado ?? '';

    String? unidade =
        Provider.of<UnidadeProvider>(context, listen: false).unidadeSelecionada;

    if (placa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O número da Placa não pode estar vazio')),
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
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('veiculos_images')
              .child(imageName);
          final uploadTask = await storageRef.putData(bytes);
          imagemUrl = await uploadTask.ref.getDownloadURL();
        }

        QuerySnapshot existingPlaca = await FirebaseFirestore.instance
            .collection('Veiculos')
            .where('placa', isEqualTo: placa)
            .get();

        if (existingPlaca.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Já existe uma Placa com o número $placa.')),
          );
          return;
        }

        // 2. Buscar itens do checklist de acordo com tipo do veículo
        final checklistSnapshot = await FirebaseFirestore.instance
            .collection('Checklist_veiculos')
            .doc(unidade)
            .collection(tipoVeiculo)
            .orderBy('ordem')
            .get();

// Corrigido: pegar só o campo 'item'
        List<String> checklistItens = checklistSnapshot.docs.map((doc) {
          return doc['item'] as String;
        }).toList();

// Salvar o veículo já com o checklist
        await FirebaseFirestore.instance.collection('Veiculos').add({
          'unidade': unidade,
          'placa': placa,
          'marca': _marcaController.text,
          'modelo': _modeloController.text,
          'tipoVeiculo': _tipoVeiculoSelecionado,
          'imageUrl': imagemUrl,
          'checklist':
              checklistItens, // Agora é um array só com os nomes dos itens!
          'createdAt': DateTime.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veículo e checklist cadastrados com sucesso!')),
        );

        _placaController.clear();
        _marcaController.clear();
        _modeloController.clear();

        setState(() {
          unidadeSelecionada = null;
          _imagem = null;
          _imagemBase64 = null;
          _tipoVeiculoSelecionado = null;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QrCodeScreen(
              placa,
              tipoVeiculo,
              unidade ?? 'Unidade não especificada',
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar veículo: $e')),
        );
      }
    }
  }

  void _limparFormulario() {
    _placaController.clear();
    _marcaController.clear();
    _modeloController.clear();
    _tipoVeiculoSelecionado = null;

    setState(() {
      unidadeSelecionada = null;
      _imagem = null;
      _imagemBase64 = null;
      _tipoVeiculoSelecionado = null;
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
                          'Cadastrar Veículo',
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
                                    'Clique no botão ao lado para selecionar a imagem do veículo que deseja cadastrar',
                                    style: drawerStyle.copyWith(
                                      fontSize: 16,
                                      color: textButton,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    softWrap: true,
                                  ),
                                  Text(
                                    'A foto deve estar nítida ',
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
                                    'Placa do Veículo',
                                    style: secondaryTextStyle,
                                    textAlign: TextAlign.start,
                                  ),
                                  _buildTextField(_placaController, 'Placa')
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
                                    'Tipo do Veículo',
                                    style: secondaryTextStyle,
                                    textAlign: TextAlign.start,
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    dropdownColor: Colors.white,
                                    value: _tipoVeiculoSelecionado,
                                    style: const TextStyle(
                                        color: Color(0xFF37474F)),
                                    decoration: buildInputDecoration(
                                      'Selecione o Tipo do Veículo',
                                    ),
                                    items: [
                                      'Carros',
                                      'Van',
                                      'MicroÔnibus',
                                      'Ônibus',
                                      'Caminhão',
                                    ].map((tipo) {
                                      return DropdownMenuItem<String>(
                                        value: tipo,
                                        child: Text(tipo),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _tipoVeiculoSelecionado = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Selecione um tipo de veículo';
                                      }
                                      return null;
                                    },
                                  ),
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
                                unidadeSelecionada ??
                                    'Nenhuma Unidade Selecionada',
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
                                    'Marca do Veículo',
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
                                    'Modelo e ano do Veículo',
                                    style: secondaryTextStyle,
                                    textAlign: TextAlign.start,
                                  ),
                                  _buildTextField(
                                      _modeloController, 'Modelo/ano'),
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
  final String placa;
  final String unidade;
  final String tipoVeiculo;

  const QrCodeScreen(this.placa, this.tipoVeiculo, this.unidade, {super.key});

  @override
  Widget build(BuildContext context) {
    final String fullUrl = 'https://util-check.web.app/#veiculos?placa=$placa&unidade=$unidade&tipoVeiculo=$tipoVeiculo';

    final Map<String, dynamic> qrData = {
      'url': fullUrl,
      'placa': placa,
      'tipoVeiculo': tipoVeiculo,
      'unidade': unidade,
    };

    final String encodedQrData = jsonEncode(qrData);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'QR Code do Veículo',
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
          FirebaseStorage.instance.ref().child('qr_codes/$userId/$placa.png');
      final uploadTask = await storageRef.putData(pngBytes);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // Salvar dados no Firestore
      final qrCodeRef = FirebaseFirestore.instance
          .collection('QR_Veiculos')
          .doc(userId)
          .collection('user_qr_veiculos')
          .doc(placa);

      await qrCodeRef.set({
        'placa': placa,
        'tipoVeiculo': tipoVeiculo,
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

    final ByteData? byteData =
        await qrImage.toByteData(format: ImageByteFormat.png);
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

    final ByteData? byteData =
        await qrImage.toByteData(format: ImageByteFormat.png);
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
