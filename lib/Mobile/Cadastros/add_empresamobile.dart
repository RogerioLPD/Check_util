import 'dart:convert';
import 'dart:io';
import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/gradient.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class EmpresaMobile extends StatefulWidget {
  const EmpresaMobile({super.key});

  @override
  _EmpresaMobileState createState() => _EmpresaMobileState();
}

class _EmpresaMobileState extends State<EmpresaMobile> {
  final _nomeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _cepController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _logoUrl;
  final ImagePicker _picker = ImagePicker();
  String? _imagemBase64;
  File? _imagem;

  Future<void> _selecionarImagem() async {
    final XFile? imagemSelecionada = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (imagemSelecionada != null) {
      if (kIsWeb) {
        final bytes = await imagemSelecionada.readAsBytes();
        setState(() {
          _imagemBase64 = base64Encode(bytes);
          _imagem = null; // Resetar a imagem local
        });
      } else {
        setState(() {
          _imagem = File(imagemSelecionada.path);
          _imagemBase64 = null; // Resetar a imagem base64
        });
      }
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      String imageName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance.ref().child(
            'logos_empresa_principal/$imageName',
          );
      final uploadTask = await storageRef.putFile(image);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  Future<void> _submitData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;

      if (_imagem != null) {
        _logoUrl = await _uploadImage(_imagem!);
      }

      FirebaseFirestore.instance
          .collection('Empresa Principal')
          .doc(userId)
          .collection('principal')
          .add({
        'nome': _nomeController.text,
        'endereco': _enderecoController.text,
        'cnpj': _cnpjController.text,
        'cep': _cepController.text,
        'cidade': _cidadeController.text,
        'telefone': _telefoneController.text,
        'email': _emailController.text,
        'logoUrl': _logoUrl ?? _imagemBase64,
      });

      _nomeController.clear();
      _enderecoController.clear();
      _cnpjController.clear();
      _cepController.clear();
      _cidadeController.clear();
      _telefoneController.clear();
      _emailController.clear();
      _logoUrl = null;
      _imagemBase64 = null;
      _imagem = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Empresa Principal cadastrada com sucesso'),
        ),
      );
    }
  }

  void _clearForm() {
    _nomeController.clear();
    _enderecoController.clear();
    _cnpjController.clear();
    _cepController.clear();
    _cidadeController.clear();
    _telefoneController.clear();
    _emailController.clear();
    setState(() {
      _imagem = null;
      _imagemBase64 = null; // Limpar a imagem selecionada
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: backgroundAppBarMobile,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 40,
              ),
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
                    'Cadastrar Empresa',
                    style: mobiTextStyle.copyWith(fontSize: 28.sp),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 60.h),
                        customCardMobile(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nome da Empresa',
                                style: mobileCardTextStyle.copyWith(
                                  fontSize: 18.sp,
                                ),
                                textAlign: TextAlign.start,
                              ),
                              _buildTextField(_nomeController, 'Nome'),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        customCardMobile(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Endereço',
                                style: mobileCardTextStyle.copyWith(
                                  fontSize: 18.sp,
                                ),
                                textAlign: TextAlign.start,
                              ),
                              _buildTextField(
                                _enderecoController,
                                'Rua e número',
                              ),
                              SizedBox(height: 20.h),
                              const Divider(),
                              SizedBox(height: 10.h),
                              Text(
                                'CEP',
                                style: mobileCardTextStyle.copyWith(
                                  fontSize: 18.sp,
                                ),
                                textAlign: TextAlign.start,
                              ),
                              _buildTextField(_cepController, 'CEP'),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        customCardMobile(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cidade',
                                style: mobileCardTextStyle.copyWith(
                                  fontSize: 18.sp,
                                ),
                                textAlign: TextAlign.start,
                              ),
                              _buildTextField(_cidadeController, 'Cidade'),
                              SizedBox(height: 20.h),
                              const Divider(),
                              SizedBox(height: 10.h),
                              Text(
                                'CNPJ',
                                style: mobileCardTextStyle.copyWith(
                                  fontSize: 18.sp,
                                ),
                                textAlign: TextAlign.start,
                              ),
                              _buildTextField(_cnpjController, 'CNPJ'),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        customCardMobile(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Telefone',
                                style: mobileCardTextStyle.copyWith(
                                  fontSize: 18.sp,
                                ),
                                textAlign: TextAlign.start,
                              ),
                              _buildTextField(_telefoneController, 'Telefone'),
                              SizedBox(height: 20.h),
                              const Divider(),
                              SizedBox(height: 10.h),
                              Text(
                                'E-mail',
                                style: mobileCardTextStyle.copyWith(
                                  fontSize: 18.sp,
                                ),
                                textAlign: TextAlign.start,
                              ),
                              _buildTextField(_emailController, 'E-mail'),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        if (_imagem != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Image.file(_imagem!, height: 150),
                          )
                        else if (_imagemBase64 != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Image.memory(
                              base64Decode(_imagemBase64!),
                              height: 150,
                            ),
                          ),
                        Center(
                          child: TextButton.icon(
                            onPressed: _selecionarImagem,
                            icon: const Icon(
                              Icons.check,
                              color: textSecondary,
                            ),
                            label: Text(
                              'Inserir Logo',
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
                            onPressed: _clearForm,
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
                            onPressed: _submitData,
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
                        SizedBox(height: 20.h),
                      ],
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
                color: Color.fromARGB(255, 216, 216, 216),
              ), // Cor correta
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(
                color: Color(0xFF37474F),
                width: 2,
              ), // Cor ao focar
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
