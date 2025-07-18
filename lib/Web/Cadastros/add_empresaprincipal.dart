import 'dart:convert';
import 'dart:io';
import 'package:checkutil/Componentes/colors.dart';
import 'package:checkutil/Componentes/tipografia.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EmpresaPrincipalScreen extends StatefulWidget {
  const EmpresaPrincipalScreen({super.key});

  @override
  _EmpresaPrincipalScreenState createState() => _EmpresaPrincipalScreenState();
}

class _EmpresaPrincipalScreenState extends State<EmpresaPrincipalScreen> {
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
    final XFile? imagemSelecionada =
        await _picker.pickImage(source: ImageSource.gallery);
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
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('logos_empresa_principal/$imageName');
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

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Empresa Principal cadastrada com sucesso')));
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
            onPressed: _clearForm,
            label: 'Cancelar',
            labelStyle: buttonTextStyle,
            icon: Icons.cancel,
            iconColor: const Color.fromARGB(255, 6, 41, 70),
            backgroundColor: const Color.fromARGB(193, 195, 204, 218),
          ),
          const SizedBox(width: 10),
          customElevatedButton(
            onPressed: _submitData,
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
                      const SizedBox(height: 8),
                      Text(
                        'Cadastrar Empresa',
                        style: headTextStyle,
                      ),
                      const SizedBox(height: 40),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nome da Empresa',
                                  style: secondaryTextStyle,
                                  textAlign: TextAlign.start,
                                ),
                                _buildTextField(_nomeController, 'Nome'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Endereço',
                                  style: secondaryTextStyle,
                                  textAlign: TextAlign.start,
                                ),
                                _buildTextField(
                                    _enderecoController, 'Rua e número'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CEP',
                                  style: secondaryTextStyle,
                                  textAlign: TextAlign.start,
                                ),
                                _buildTextField(_cepController, 'CEP'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cidade',
                                  style: secondaryTextStyle,
                                  textAlign: TextAlign.start,
                                ),
                                _buildTextField(_cidadeController, 'Cidade'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CNPJ',
                                  style: secondaryTextStyle,
                                  textAlign: TextAlign.start,
                                ),
                                _buildTextField(_cnpjController, 'CNPJ'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Telefone',
                                  style: secondaryTextStyle,
                                  textAlign: TextAlign.start,
                                ),
                                _buildTextField(
                                    _telefoneController, 'Telefone'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          Text(
                            'E-mail',
                            style: secondaryTextStyle,
                            textAlign: TextAlign.start,
                          ),
                          _buildTextField(_emailController, 'E-mail'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_imagem != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Image.file(
                    _imagem!,
                    height: 150,
                  ),
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
                child: customElevatedButton(
                  onPressed: _selecionarImagem,
                  icon: Icons.check,
                  iconColor: const Color.fromARGB(255, 6, 41, 70),
                  backgroundColor: backgroundButton,
                  labelStyle: buttonTextStyle,
                  label: "Inserir Logo",
                ),
              ),
              const SizedBox(height: 20),
            ],
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
