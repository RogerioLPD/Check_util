import 'dart:convert'; // Para base64
import 'dart:io';
import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/gradient.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CadastrarUnidadeMobile extends StatefulWidget {
  const CadastrarUnidadeMobile({super.key});

  @override
  _CadastrarUnidadeMobileState createState() => _CadastrarUnidadeMobileState();
}

class _CadastrarUnidadeMobileState extends State<CadastrarUnidadeMobile> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _enderecoController = TextEditingController();

  List estados = [];
  List cidades = [];
  String? estadoSelecionado;
  String? cidadeSelecionada;
  File? _imagem; // Para Mobile
  String? _imagemBase64; // Para Web

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchEstados();
  }

  Future<void> _fetchEstados() async {
    final response = await http.get(
      Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados'),
    );
    if (response.statusCode == 200) {
      setState(() {
        estados = json.decode(response.body);
      });
    }
  }

  Future<void> _fetchCidades(String uf) async {
    final response = await http.get(
      Uri.parse(
        'https://servicodados.ibge.gov.br/api/v1/localidades/estados/$uf/municipios',
      ),
    );
    if (response.statusCode == 200) {
      setState(() {
        cidades = json.decode(response.body);
      });
    }
  }

  Future<void> _selecionarImagem() async {
    final XFile? imagemSelecionada = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (imagemSelecionada != null) {
      if (kIsWeb) {
        // Para Web: Converter a imagem para base64
        final bytes = await imagemSelecionada.readAsBytes();
        setState(() {
          _imagemBase64 = base64Encode(bytes); // Salvar a imagem em base64
        });
      } else {
        // Para Mobile: Usar o File
        setState(() {
          _imagem = File(imagemSelecionada.path);
        });
      }
    }
  }

  Future<void> _salvarUnidade() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;

        if (userId == null) {
          throw Exception('Usuário não autenticado.');
        }

        String? imagemUrl;

        if (kIsWeb && _imagemBase64 != null) {
          // Para Web, salvar a imagem em base64
          imagemUrl = _imagemBase64;
        } else if (_imagem != null) {
          // Para Mobile, fazer upload no Firebase Storage
          final storageRef = FirebaseStorage.instance.ref().child(
                'logos/${DateTime.now().millisecondsSinceEpoch}.jpg',
              );

          final uploadTask = storageRef.putFile(_imagem!);

          final snapshot = await uploadTask;
          imagemUrl = await snapshot.ref.getDownloadURL();
        }

        // Salvar os dados no Firestore
        await FirebaseFirestore.instance
            .collection('Unidades')
            .doc(userId)
            .collection('Unidade')
            .add({
          'nome': _nomeController.text,
          'cnpj': _cnpjController.text,
          'telefone': _telefoneController.text,
          'email': _emailController.text,
          'endereco': _enderecoController.text,
          'estado': estadoSelecionado,
          'cidade': cidadeSelecionada,
          'logo': imagemUrl, // Salvar a URL ou base64 da imagem
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unidade cadastrada com sucesso!')),
        );

        _nomeController.clear();
        _enderecoController.clear();
        _cnpjController.clear();
        _telefoneController.clear();
        _emailController.clear();
        setState(() {
          estadoSelecionado = null;
          cidadeSelecionada = null;
          cidades = [];
          _imagem = null;
          _imagemBase64 = null; // Limpar a imagem selecionada
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar unidade: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _nomeController.clear();
    _cnpjController.clear();
    _telefoneController.clear();
    _emailController.clear();
    _enderecoController.clear();

    setState(() {
      estadoSelecionado = null;
      cidadeSelecionada = null;
      cidades = [];
      _imagem = null;
      _imagemBase64 = null; // Limpar a imagem selecionada
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulário limpo com sucesso.')),
    );
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
                    'Cadastrar Unidades',
                    style: mobiTextStyle.copyWith(fontSize: 28.sp),
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
                                Text(
                                  'Nome da Unidade',
                                  style: mobileCardTextStyle.copyWith(
                                    fontSize: 18.sp,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                                _buildTextField(
                                  _nomeController,
                                  'Nome da Unidade',
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
                                  'Endereço da Unidade',
                                  style: mobileCardTextStyle.copyWith(
                                    fontSize: 18.sp,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                                _buildTextField(
                                  _enderecoController,
                                  'Endereço da Unidade',
                                ),
                                SizedBox(height: 20.h),
                                const Divider(),
                                SizedBox(height: 10.h),
                                Text(
                                  'CNPJ da Unidade',
                                  style: mobileCardTextStyle.copyWith(
                                    fontSize: 18.sp,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                                _buildTextField(
                                  _cnpjController,
                                  'CNPJ da Unidade',
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
                                  'Telefone da Unidade',
                                  style: mobileCardTextStyle.copyWith(
                                    fontSize: 18.sp,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                                _buildTextField(
                                  _telefoneController,
                                  'Telefone da Unidade',
                                ),
                                SizedBox(height: 20.h),
                                const Divider(),
                                SizedBox(height: 10.h),
                                Text(
                                  'E-mail da Unidade',
                                  style: mobileCardTextStyle.copyWith(
                                    fontSize: 18.sp,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                                _buildTextField(
                                  _emailController,
                                  'Email da Unidade',
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
                                  'Estado',
                                  style: mobileCardTextStyle.copyWith(
                                    fontSize: 18.sp,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                                DropdownButtonFormField<String>(
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(
                                    color: Color(0xFF37474F),
                                  ),
                                  decoration: buildInputDecoration('Estado'),
                                  value: estadoSelecionado,
                                  items: estados.map<DropdownMenuItem<String>>((
                                    estado,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: estado['sigla'],
                                      child: Text(estado['nome']),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      estadoSelecionado = value;
                                      cidadeSelecionada = null;
                                      cidades = [];
                                    });
                                    if (value != null) {
                                      _fetchCidades(value);
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Por favor, selecione um estado.';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 20.h),
                                const Divider(),
                                SizedBox(height: 10.h),
                                customCardMobile(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cidade',
                                        style: mobileCardTextStyle.copyWith(
                                          fontSize: 18.sp,
                                        ),
                                        textAlign: TextAlign.start,
                                      ),
                                      DropdownButtonFormField<String>(
                                        dropdownColor: Colors.white,
                                        style: const TextStyle(
                                          color: Color(0xFF37474F),
                                        ),
                                        decoration: buildInputDecoration(
                                          'Cidade',
                                        ),
                                        value: cidadeSelecionada,
                                        items: cidades
                                            .map<DropdownMenuItem<String>>(
                                                (cidade) {
                                          return DropdownMenuItem<String>(
                                            value: cidade['nome'],
                                            child: Text(cidade['nome']),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            cidadeSelecionada = value;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null) {
                                            return 'Por favor, selecione uma cidade.';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20.h),
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
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                      backgroundColor: Colors
                                          .transparent, // Remova ou troque se quiser fundo
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                if (kIsWeb && _imagemBase64 != null)
                                  Image.memory(
                                    base64Decode(_imagemBase64!),
                                    width: 100,
                                    height: 100,
                                  )
                                else if (_imagem != null)
                                  Image.file(_imagem!, width: 100, height: 100),
                              ],
                            ),
                          ),
                          SizedBox(height: 30.h),
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
                              onPressed: _salvarUnidade,
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: Color(0xFF37474F)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 216, 216, 216),
            ),
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

Widget customCardMobile({required Widget child}) {
  return Card(
    margin: EdgeInsets.symmetric(vertical: 10.h),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
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
