import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:checkutil/Mobile/Cadastros/pdf_helper_mobile.dart';
import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Services/equipamentos.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CadastrarEquipamentoMobileScreen extends StatefulWidget {
  const CadastrarEquipamentoMobileScreen({super.key});

  @override
  State<CadastrarEquipamentoMobileScreen> createState() =>
      _CadastrarEquipamentoMobileScreenState();
}

class _CadastrarEquipamentoMobileScreenState
    extends State<CadastrarEquipamentoMobileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tagController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _potenciaController = TextEditingController();
  final _tipoEquipamentoController = TextEditingController();

  File? _imagem; // Para Mobile
  String? _imagemBase64; // Para Web

  final ImagePicker _picker = ImagePicker();

  List unidades = [];
  List locais = []; // Lista para armazenar os locais
  String? unidadeSelecionada;
  String? localSelecionado; // Local selecionado
  String? prioridadeSelecionada;

  @override
  void initState() {
    super.initState();
    unidadeSelecionada =
        Provider.of<UnidadeProvider>(context, listen: false).unidadeSelecionada;
    if (unidadeSelecionada != null) {
      _fetchLocais();
    }
  }

  Future<void> _fetchLocais() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        throw Exception('Usuário não autenticado.');
      }

      if (unidadeSelecionada == null || unidadeSelecionada!.isEmpty) {
        return; // Não faz nada se a unidade não estiver selecionada
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('Local_lista')
          .doc(userId)
          .collection('local')
          .where('unidade', isEqualTo: unidadeSelecionada)
          .get();

      setState(() {
        locais =
            querySnapshot.docs.map((doc) => doc['nome'] as String).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar Locais: $e')),
      );
    }
  }

  void _onUnidadeChanged(String? newValue) {
    setState(() {
      unidadeSelecionada = newValue;
      locais.clear(); // Limpar locais ao mudar de unidade
    });
    _fetchLocais(); // Atualizar os locais com base na unidade selecionada
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
          .child('checklist_images')
          .child(imageName);
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
    ScreenUtil.init(context, designSize: const Size(375, 820));

    unidadeSelecionada =
        Provider.of<UnidadeProvider>(context).unidadeSelecionada ?? 'Nenhuma Unidade Selecionada';

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: backgroundAppBarMobile,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text(
                    'Cadastrar Equipamento',
                    style: mobiTextStyle.copyWith(fontSize: 26.sp, ),
                  ),
                  SizedBox(height: 8.h),
                  Form(
                    key: _formKey,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 60.h),
                          customCardMobile(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: SizedBox(
                                    width: 110.w,
                                    height: 170.h,
                                    child: GestureDetector(
                                      onTap: _selecionarImagem,
                                      child: Container(
                                        width: 110.w,
                                        height: 170.h,
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(143, 55, 71, 79),
                                          borderRadius: BorderRadius.circular(10.r),
                                          border: Border.all(color: const Color(0xFF37474F)),
                                        ),
                                        child: _imagem == null && _imagemBase64 == null
                                            ? Icon(Icons.camera_alt,
                                                color: const Color(0xFF37474F), size: 40.sp)
                                            : (kIsWeb && _imagemBase64 != null)
                                                ? Image.memory(base64Decode(_imagemBase64!),
                                                    width: 90.w, height: 90.h)
                                                : (_imagem != null)
                                                    ? Image.file(_imagem!,
                                                        width: 90.w, height: 90.h)
                                                    : Icon(Icons.camera_alt,
                                                        color: const Color(0xFF37474F),
                                                        size: 40.sp),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10.w),
                                Text(
                                  'Clique no botão para selecionar a imagem do equipamento que deseja cadastrar',
                                  style: drawerStyle.copyWith(
                                      fontSize: 14.sp,
                                      color: textButton,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'A foto deve estar nítida e deve enquadrar o equipamento inteiro',
                                  style: drawerStyle.copyWith(
                                      fontSize: 12.sp, color: drawerTextColor),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          customCardMobile(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Identificação do equipamento',
                                  style: mobileCardTextStyle.copyWith(fontSize: 18.sp),
                                ),
                                _buildTextField(_tagController, 'Tag'),
                                SizedBox(height: 20.h),
                                const Divider(),
                                SizedBox(height: 10.h),
                                Text(
                                  'Tipo do equipamento',
                                  style: mobileCardTextStyle.copyWith(fontSize: 18.sp),
                                ),
                                _buildTextField(_tipoEquipamentoController, 'Tipo de Equipamento'),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          customCardMobile(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unidade',
                                  style: mobileCardTextStyle.copyWith(fontSize: 18.sp),
                                ),
                                SizedBox(height: 10.h),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                                  height: 58.h,
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: const Color.fromARGB(255, 216, 216, 216),
                                        width: 1),
                                    borderRadius: BorderRadius.circular(5.r),
                                  ),
                                  child: Text(
                                    "Unidade: ${unidadeSelecionada ?? 'Nenhuma Unidade Selecionada'}",
                                    style: bodyTextStyle.copyWith(fontSize: 12.sp),
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                const Divider(),
                                SizedBox(height: 10.h),
                                Text(
                                  'Locais cadastrados',
                                  style: mobileCardTextStyle.copyWith(fontSize: 18.sp),
                                ),
                                SizedBox(height: 10.h),
                                locais.isEmpty
                                    ? Container(
                                        height: 58.h,
                                        alignment: Alignment.centerLeft,
                                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: const Color.fromARGB(255, 216, 216, 216),
                                              width: 1),
                                          borderRadius: BorderRadius.circular(5.r),
                                        ),
                                        child: Text("Nenhum local disponível",
                                            style: bodyTextStyle.copyWith(fontSize: 12.sp)),
                                      )
                                    : DropdownButtonFormField<String>(
                                        dropdownColor: Colors.white,
                                        style: TextStyle(
                                            color: const Color(0xFF37474F), fontSize: 14.sp),
                                        decoration: buildInputDecoration('Locais'),
                                        value: localSelecionado != null &&
                                                locais.contains(localSelecionado)
                                            ? localSelecionado
                                            : null,
                                        items: locais
                                            .map<DropdownMenuItem<String>>((local) {
                                          return DropdownMenuItem<String>(
                                            value: local,
                                            child: Text(local),
                                          );
                                        }).toList(),
                                        onChanged: (value) =>
                                            setState(() => localSelecionado = value),
                                        validator: (value) => value == null
                                            ? 'Por favor, selecione um Local.'
                                            : null,
                                      ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          customCardMobile(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Marca do equipamento',
                                  style: mobileCardTextStyle.copyWith(fontSize: 18.sp),
                                ),
                                _buildTextField(_marcaController, 'Marca'),
                                SizedBox(height: 20.h),
                                const Divider(),
                                SizedBox(height: 10.h),
                                Text(
                                  'Modelo do equipamento',
                                  style: mobileCardTextStyle.copyWith(fontSize: 18.sp),
                                ),
                                _buildTextField(_modeloController, 'Modelo'),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          customCardMobile(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Potência do equipamento',
                                  style: mobileCardTextStyle.copyWith(fontSize: 18.sp),
                                ),
                                _buildTextField(_potenciaController, 'Potência'),
                                SizedBox(height: 20.h),
                                const Divider(),
                                SizedBox(height: 10.h),
                                Text(
                                  'Nível de prioridade do equipamento',
                                  style: mobileCardTextStyle.copyWith(fontSize: 18.sp),
                                ),
                                SizedBox(height: 10.h),
                                DropdownButtonFormField<String>(
                                  dropdownColor: Colors.white,
                                  style: TextStyle(
                                      color: const Color(0xFF37474F), fontSize: 14.sp),
                                  decoration: buildInputDecoration('Prioridade'),
                                  value: prioridadeSelecionada,
                                  items: ['Alta', 'Média', 'Baixa']
                                      .map((prioridade) => DropdownMenuItem(
                                          value: prioridade, child: Text(prioridade)))
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => prioridadeSelecionada = value),
                                  validator: (value) => value == null
                                      ? 'Por favor, selecione a prioridade.'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30.h),
                          Center(
                            child: TextButton.icon(
                              onPressed: _limparFormulario,
                              icon: const Icon(
                                Icons.cancel,
                                color: textSecondary,
                              ),
                              label: Text(
                                'Cancelar',
                                style: buttonMobileTextStyle.copyWith(
                                  fontSize: 14.sp,
                                  color:
                                      textSecondary, // Garante que o texto esteja com a cor correta
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                backgroundColor: Colors
                                    .transparent, // Remova ou troque se quiser fundo
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Center(
                            child: TextButton.icon(
                              onPressed: _salvarEquipamento,
                              icon: const Icon(
                                Icons.check,
                                color: textSecondary,
                              ),
                              label: Text(
                                'Salvar',
                                style: buttonMobileTextStyle.copyWith(
                                  fontSize: 14.sp,
                                  color:
                                      textSecondary, // Garante que o texto esteja com a cor correta
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                backgroundColor: Colors
                                    .transparent, // Remova ou troque se quiser fundo
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 30.h),
                        ],
                      ),
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

Widget customCardMobile({required Widget child}) {
  return Card(
    margin: EdgeInsets.symmetric(vertical: 10.h),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.r),
    ),
    elevation: 5,
    child: Padding(padding: EdgeInsets.all(16.w), child: child),
  );
}

Widget customElevatedButton({
  required VoidCallback onPressed,
  required String label,
  required TextStyle labelStyle,
  required IconData icon,
  required Color iconColor,
  required Color backgroundColor,
}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, color: iconColor),
    label: Text(label, style: labelStyle),
    style: ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      textStyle: TextStyle(fontSize: 14.sp),
    ),
  );
}

class QrCodeScreen extends StatelessWidget {
  final String tag;
  final String unidade;
  final String tipoEquipamento;

  const QrCodeScreen(
    this.tag,
    this.tipoEquipamento,
    this.unidade, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final String fullUrl =
        'https://cleanmed-6de09.web.app/#landingpage?roomNumber=$tag';

    final Map<String, dynamic> qrData = {
      'url': fullUrl,
      'tag': tag,
      'tipoEquipamento': tipoEquipamento,
      'nomeLocal': unidade,
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
                          20,
                        ), // Bordas arredondadas para suavizar o visual
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
                      onPressed:
                          () => _saveQrCodeToFirestore(encodedQrData, context),
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
    String qrData,
    BuildContext context,
  ) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Usuário não autenticado');

      // Gerar imagem do QR Code
      final qrImage = await QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: true,
      ).toImage(200);

      final ByteData? byteData = await qrImage.toByteData(
        format: ImageByteFormat.png,
      );
      if (byteData == null) throw Exception('Erro ao gerar imagem do QR Code');

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Fazer upload para Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(
        'qr_codes/$userId/$tag.png',
      );
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
        'nomeLocal': unidade,
        'qrData': qrData,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR Code salvo com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar QR Code: $e')));
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

  // Chamando diretamente a função mobile, sem verificar se é Web.
  await savePdfMobile(pdfBytes);
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

  // Chamando diretamente a função mobile, sem verificar se é Web.
  await printQrCodeMobile(pdfBytes);
}


  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
      elevation: 5,
    );
  }
}